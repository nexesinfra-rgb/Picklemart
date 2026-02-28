import paramiko
import time
import os

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = r"C:\Users\Venky\.ssh\id_ed25519"
# Local paths - Use raw string literal for Windows path
SQL_FILE = r"c:\Users\Venky\Downloads\Pickle mart(25-02-2026)\sm\FIX_MISSING_COLUMNS.sql"

def apply_fix():
    print(f"Connecting to {VPS_IP}...")
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)
        print("Connected successfully.")
    except Exception as e:
        print(f"Failed to connect: {e}")
        return

    # 1. Find DB Container
    cmd_find_db = "docker ps --format '{{.ID}} {{.Names}}' | grep -E 'supabase-db|postgres' | head -n 1 | awk '{print $1}'"
    stdin, stdout, stderr = ssh.exec_command(cmd_find_db)
    container_id = stdout.read().decode().strip()
    
    if not container_id:
        cmd_find_db_2 = "docker ps -q --filter ancestor=supabase/postgres"
        stdin, stdout, stderr = ssh.exec_command(cmd_find_db_2)
        container_id = stdout.read().decode().strip()
        
    if not container_id:
        print("❌ Database container not found.")
        return

    print(f"✅ Found database container: {container_id}")

    # 2. Upload SQL
    print("Uploading SQL fix...")
    if not os.path.exists(SQL_FILE):
        print(f"❌ Error: SQL file not found at {SQL_FILE}")
        return
        
    try:
        sftp = ssh.open_sftp()
        sftp.put(SQL_FILE, "/tmp/fix_cols.sql")
        sftp.close()
    except Exception as e:
        print(f"Failed to upload SQL file: {e}")
        return

    # 3. Exec SQL
    print("Applying fix...")
    ssh.exec_command(f"docker cp /tmp/fix_cols.sql {container_id}:/tmp/fix_cols.sql")
    cmd_exec = f"docker exec -i {container_id} psql -U postgres -d postgres -f /tmp/fix_cols.sql"
    stdin, stdout, stderr = ssh.exec_command(cmd_exec)
    print(stdout.read().decode())
    print(stderr.read().decode())

    # 4. Restart Worker
    print("Restarting FCM Worker...")
    ssh.exec_command("systemctl restart fcm-worker")
    time.sleep(3)

    # 5. Check Logs
    print("\n--- Worker Logs ---")
    stdin, stdout, stderr = ssh.exec_command("journalctl -u fcm-worker -n 20 --no-pager")
    print(stdout.read().decode())

    ssh.close()

if __name__ == "__main__":
    apply_fix()
