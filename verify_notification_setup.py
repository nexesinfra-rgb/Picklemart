import paramiko
import time

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def verify_setup():
    print(f"Connecting to VPS {VPS_IP}...")
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)
        print("Connected successfully.")
    except Exception as e:
        print(f"Failed to connect: {e}")
        return

    # Find DB container
    cmd_find_db = "docker ps --format '{{.ID}} {{.Names}}' | grep -E 'supabase-db|postgres' | head -n 1 | awk '{print $1}'"
    stdin, stdout, stderr = ssh.exec_command(cmd_find_db)
    container_id = stdout.read().decode().strip()
    
    if not container_id:
        cmd_find_db_2 = "docker ps -q --filter ancestor=supabase/postgres"
        stdin, stdout, stderr = ssh.exec_command(cmd_find_db_2)
        container_id = stdout.read().decode().strip()
    
    if not container_id:
        print("❌ Database container not found.")
        ssh.close()
        return

    print(f"✅ Found database container: {container_id}")

    # Define checks
    checks = [
        # Check Tables
        ("Table 'user_notifications'", "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_notifications');"),
        ("Table 'admin_fcm_tokens'", "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'admin_fcm_tokens');"),
        ("Table 'user_fcm_tokens'", "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_fcm_tokens');"),
        
        # Check Columns
        ("Column 'is_pushed' in user_notifications", "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'user_notifications' AND column_name = 'is_pushed');"),
        ("Column 'conversation_id' in user_notifications", "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'user_notifications' AND column_name = 'conversation_id');"),
        
        # Check Triggers
        ("Trigger 'trigger_order_placed_notification'", "SELECT EXISTS (SELECT FROM information_schema.triggers WHERE trigger_name = 'trigger_order_placed_notification');"),
        ("Trigger 'trigger_admin_order_notification'", "SELECT EXISTS (SELECT FROM information_schema.triggers WHERE trigger_name = 'trigger_admin_order_notification');"),
        ("Trigger 'trigger_order_status_notification'", "SELECT EXISTS (SELECT FROM information_schema.triggers WHERE trigger_name = 'trigger_order_status_notification');"),
    ]

    print("\n--- Running Verification Checks ---")
    all_passed = True
    
    for name, sql in checks:
        # Wrap SQL in single quotes for the bash command
        cmd = f"docker exec -i {container_id} psql -U postgres -d postgres -t -A -c \"{sql}\""
        stdin, stdout, stderr = ssh.exec_command(cmd)
        result = stdout.read().decode().strip()
        
        if result == "t":
            print(f"✅ PASS: {name}")
        else:
            print(f"❌ FAIL: {name} (Result: {result})")
            all_passed = False

    print("\n-----------------------------------")
    if all_passed:
        print("🎉 ALL CHECKS PASSED! Notification system is correctly configured.")
    else:
        print("⚠️ SOME CHECKS FAILED. Please review above.")

    ssh.close()

if __name__ == "__main__":
    verify_setup()
