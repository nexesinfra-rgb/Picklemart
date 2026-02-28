# 🚀 Ultimate FCM Notification System Guide (Reusable for Any Project)

This guide provides a **universal, copy-paste architecture** to add Push Notifications to **any** Supabase/PostgreSQL project (E-commerce, Social Media, Chat Apps, etc.).

**How it works:**
1.  **Database**: Triggers create rows in a `user_notifications` table.
2.  **Worker**: A Python script on your VPS watches this table and sends messages via Firebase (FCM).
3.  **App**: Receives the notification.

---

## ✅ Step 1: Database Setup (Universal SQL)

Run this SQL in your Supabase SQL Editor. This sets up the core infrastructure.

```sql
-- 1. Create the Notifications Queue Table
CREATE TABLE IF NOT EXISTS public.user_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,          -- Who gets the notification
    type TEXT NOT NULL,             -- e.g., 'order_placed', 'new_message', 'like'
    title TEXT NOT NULL,            -- Notification Title
    message TEXT NOT NULL,          -- Notification Body
    order_id UUID,                  -- Optional: Link to an object (order, post, etc.)
    is_read BOOLEAN DEFAULT FALSE,
    is_pushed BOOLEAN DEFAULT FALSE, -- CRITICAL: Worker watches this column
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Token Storage (Where we save phone tokens)
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_info JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);

-- 3. Create Admin Token Storage (If you have a separate admin app)
CREATE TABLE IF NOT EXISTS public.admin_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(admin_id, fcm_token)
);

-- 4. Create Indexes for Speed
CREATE INDEX IF NOT EXISTS idx_notifications_pushed ON public.user_notifications(is_pushed) WHERE is_pushed = FALSE;
CREATE INDEX IF NOT EXISTS idx_tokens_user ON public.user_fcm_tokens(user_id);
```

---

## ✅ Step 2: Create Triggers (Project Specific)

This is the **only** part you change based on your project (E-commerce vs. Social Media).

### Example A: E-Commerce (Notify on New Order)
```sql
CREATE OR REPLACE FUNCTION public.notify_on_new_order()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify the User
    INSERT INTO public.user_notifications (user_id, type, title, message, order_id, is_pushed)
    VALUES (NEW.user_id, 'order_placed', 'Order Placed', 'Order #' || NEW.order_number || ' confirmed.', NEW.id, FALSE);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_new_order
    AFTER INSERT ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.notify_on_new_order();
```

### Example B: Social Media (Notify on New Like)
```sql
CREATE OR REPLACE FUNCTION public.notify_on_like()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify the Post Owner
    INSERT INTO public.user_notifications (user_id, type, title, message, order_id, is_pushed)
    VALUES (NEW.post_owner_id, 'like', 'New Like', 'Someone liked your post!', NEW.post_id, FALSE);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_new_like
    AFTER INSERT ON public.likes
    FOR EACH ROW EXECUTE FUNCTION public.notify_on_like();
```

---

## ✅ Step 3: The Worker Script (Python)

Save this as `fcm_worker.py`. This script runs on your VPS and actually sends the messages.

**Requirements:**
- `firebase-admin`
- `psycopg2-binary` (or just use Docker exec approach below which needs nothing extra)

```python
import os
import json
import time
import subprocess
import logging
import firebase_admin
from firebase_admin import credentials, messaging

# 1. Setup Logging & Firebase
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("FCMWorker")

# Load Firebase Key (Put service-account.json in same folder)
cred = credentials.Certificate("service-account.json")
firebase_admin.initialize_app(cred)

# 2. Helper to run SQL inside Docker (Supabase)
def execute_sql(sql):
    # Find the DB container
    cmd_find = "docker ps -q --filter ancestor=supabase/postgres"
    cid = subprocess.check_output(cmd_find, shell=True).decode().strip().split('\n')[0]
    
    # Run SQL
    cmd = f'docker exec -i {cid} psql -U postgres -d postgres -t -A -c "{sql}"'
    return subprocess.check_output(cmd, shell=True).decode().strip()

# 3. Main Loop
def main():
    logger.info("Worker Started...")
    while True:
        try:
            # A. Fetch Pending Notifications
            # We look for rows where is_pushed = FALSE
            # We also try to join/subquery to get the latest token
            sql = """
            WITH pending AS (
                SELECT n.id, n.user_id, n.title, n.message, n.type,
                COALESCE(
                    (SELECT fcm_token FROM user_fcm_tokens WHERE user_id = n.user_id ORDER BY last_used_at DESC LIMIT 1),
                    (SELECT fcm_token FROM admin_fcm_tokens WHERE admin_id = n.user_id ORDER BY last_used_at DESC LIMIT 1)
                ) as token
                FROM user_notifications n
                WHERE n.is_pushed = FALSE LIMIT 5
            )
            SELECT json_agg(pending) FROM pending;
            """
            
            data = execute_sql(sql)
            if not data or data == "null":
                time.sleep(2)
                continue
                
            notifications = json.loads(data)
            
            # B. Send to Firebase
            for n in notifications:
                if not n.get('token'):
                    logger.warning(f"No token for user {n['user_id']}")
                    # Mark pushed anyway to skip
                    execute_sql(f"UPDATE user_notifications SET is_pushed = TRUE WHERE id = '{n['id']}'")
                    continue
                    
                msg = messaging.Message(
                    notification=messaging.Notification(title=n['title'], body=n['message']),
                    data={'type': n['type'], 'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
                    token=n['token']
                )
                
                try:
                    messaging.send(msg)
                    logger.info(f"Sent to {n['user_id']}")
                except Exception as e:
                    logger.error(f"Failed to send: {e}")
                
                # C. Mark as Pushed
                execute_sql(f"UPDATE user_notifications SET is_pushed = TRUE WHERE id = '{n['id']}'")
                
        except Exception as e:
            logger.error(f"Error: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()
```

---

## ✅ Step 4: Deployment (VPS)

1.  **SSH into your VPS**.
2.  **Create Directory**: `mkdir -p /opt/fcm-worker`
3.  **Upload Files**: Upload `fcm_worker.py` and your `service-account.json` to that folder.
4.  **Install Dependencies**:
    ```bash
    apt-get update && apt-get install -y python3-pip
    pip3 install firebase-admin
    ```
5.  **Create System Service** (to make it run forever):
    ```bash
    nano /etc/systemd/system/fcm-worker.service
    ```
    Paste this:
    ```ini
    [Unit]
    Description=FCM Worker
    After=network.target docker.service
    
    [Service]
    User=root
    WorkingDirectory=/opt/fcm-worker
    ExecStart=/usr/bin/python3 fcm_worker.py
    Restart=always
    
    [Install]
    WantedBy=multi-user.target
    ```
6.  **Start it**:
    ```bash
    systemctl daemon-reload
    systemctl enable fcm-worker
    systemctl start fcm-worker
    ```

---

## 🎯 Summary

You now have a robust system:
1.  **SQL Trigger** detects an event (Order, Like, Message).
2.  **SQL Table** (`user_notifications`) stores the "Job".
3.  **Python Worker** picks up the job and sends it to Firebase.
4.  **Firebase** delivers it to the phone.

**To use in a new project:** Just copy Step 1 (SQL), customize Step 2 (Trigger), and deploy Step 3 & 4 (Worker).
