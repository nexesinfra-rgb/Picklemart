import os
import json
import time
import subprocess
import logging
import sys
from typing import Optional, List, Dict, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("fcm_worker.log")
    ]
)
logger = logging.getLogger("FCMWorker")

# Firebase setup
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    
    # Path to service account key
    SERVICE_ACCOUNT_PATH = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "service-account.json")
    
    if not os.path.exists(SERVICE_ACCOUNT_PATH):
        logger.error(f"Service account file not found at {SERVICE_ACCOUNT_PATH}")
        sys.exit(1)
        
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    # Check if app is already initialized
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred)
    logger.info("Firebase Admin initialized successfully")
    
except ImportError:
    logger.error("firebase-admin package not installed. Please run: pip install firebase-admin")
    sys.exit(1)
except Exception as e:
    logger.error(f"Failed to initialize Firebase Admin: {e}")
    sys.exit(1)

def get_db_container_id():
    """Get the container ID of the postgres database"""
    try:
        # First try finding by name
        cmd = ["docker", "ps", "-q", "--filter", "name=supabase-db"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip().split('\n')[0]
            
        # Fallback to finding by image name if name filter fails
        cmd = ["docker", "ps", "-q", "--filter", "ancestor=supabase/postgres"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip().split('\n')[0]
            
        return None
    except Exception as e:
        logger.error(f"Failed to get DB container ID: {e}")
        return None

def execute_sql(sql_query: str) -> str:
    """Execute SQL query via docker exec psql"""
    container_id = get_db_container_id()
    if not container_id:
        raise Exception("Database container not found")
        
    # Escape double quotes in SQL for shell command
    # We use a slightly different approach to handle complex JSON queries
    # Write SQL to a temporary file inside the container and execute it
    
    # Simple execution for now
    cmd = [
        "docker", "exec", "-i", container_id,
        "psql", "-U", "postgres", "-d", "postgres",
        "-t", "-A", "-c", sql_query
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise Exception(f"SQL execution failed: {result.stderr}")
        
    return result.stdout.strip()

def fetch_pending_notifications():
    """Fetch notifications that haven't been pushed yet"""
    # Fetch from user_notifications and try to find token in user_fcm_tokens OR admin_fcm_tokens
    # We use a CTE to get the token based on user_id
    sql = """
    WITH token_lookup AS (
        SELECT 
            n.id, 
            n.user_id, 
            n.type, 
            n.title, 
            n.message, 
            n.order_id,
            COALESCE(
                (SELECT fcm_token FROM user_fcm_tokens WHERE user_id = n.user_id AND is_active = true ORDER BY last_used_at DESC LIMIT 1),
                (SELECT fcm_token FROM admin_fcm_tokens WHERE admin_id = n.user_id AND is_active = true ORDER BY created_at DESC LIMIT 1)
            ) as token
        FROM user_notifications n
        WHERE n.is_pushed = FALSE 
        AND n.created_at > NOW() - INTERVAL '24 hour'
        LIMIT 10
    )
    SELECT json_agg(t) FROM token_lookup t;
    """
    
    try:
        output = execute_sql(sql)
        if not output or output == "" or output == "null":
            return []
        return json.loads(output)
    except Exception as e:
        logger.error(f"Error fetching notifications: {e}")
        return []

def mark_as_pushed(notification_id):
    """Mark notification as pushed"""
    sql = f"UPDATE user_notifications SET is_pushed = TRUE WHERE id = '{notification_id}';"
    try:
        execute_sql(sql)
        logger.info(f"Marked notification {notification_id} as pushed")
    except Exception as e:
        logger.error(f"Error marking notification {notification_id}: {e}")

def send_fcm(notification):
    """Send FCM notification"""
    token = notification.get('token')
    if not token:
        logger.warning(f"No token found for user {notification['user_id']}")
        mark_as_pushed(notification['id']) # Mark as pushed to avoid retry loop
        return

    try:
        # Construct the message payload
        # Note: 'data' fields must be strings
        data_payload = {
            'type': str(notification.get('type', '')),
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        }
        
        if notification.get('order_id'):
            data_payload['order_id'] = str(notification['order_id'])
            
        message = messaging.Message(
            notification=messaging.Notification(
                title=notification['title'],
                body=notification['message'],
            ),
            data=data_payload,
            token=token,
        )
        
        response = messaging.send(message)
        logger.info(f"Successfully sent message to user {notification['user_id']}: {response}")
        mark_as_pushed(notification['id'])
    except Exception as e:
        logger.error(f"Error sending message to user {notification['user_id']}: {e}")
        # If token is invalid (e.g. NotRegistered), we should probably deactivate it
        # For now, just mark as pushed to stop the loop
        mark_as_pushed(notification['id'])

def setup_db():
    """Ensure is_pushed column exists"""
    logger.info("Checking database schema...")
    try:
        execute_sql("ALTER TABLE user_notifications ADD COLUMN IF NOT EXISTS is_pushed BOOLEAN DEFAULT FALSE;")
        execute_sql("CREATE INDEX IF NOT EXISTS idx_user_notifications_is_pushed ON user_notifications(is_pushed) WHERE is_pushed = FALSE;")
        logger.info("Database schema check passed.")
    except Exception as e:
        logger.error(f"Failed to setup DB schema: {e}")

def main():
    logger.info("Starting FCM Worker...")
    setup_db()
    
    logger.info("Worker started. Polling for notifications...")
    while True:
        try:
            notifications = fetch_pending_notifications()
            if notifications:
                logger.info(f"Found {len(notifications)} pending notifications")
                for n in notifications:
                    send_fcm(n)
            else:
                pass # No notifications
                
        except Exception as e:
            logger.error(f"Worker loop error: {e}")
            
        time.sleep(5) # Poll every 5 seconds

if __name__ == "__main__":
    main()
