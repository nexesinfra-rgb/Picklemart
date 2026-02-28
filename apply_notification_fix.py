import paramiko
import time
import os

# Configuration from apply_env_and_verify.py
VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"
SQL_FILE = "FIX_NOTIFICATIONS_PERMANENTLY.sql"

def apply_fix():
    print(f"Connecting to VPS {VPS_IP}...")
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)
        print("Connected successfully.")
    except Exception as e:
        print(f"Failed to connect: {e}")
        return

    # Read SQL content
    try:
        with open(SQL_FILE, 'r') as f:
            sql_content = f.read()
    except Exception as e:
        print(f"Failed to read local SQL file: {e}")
        return

    # 1. Find Database Container
    print("Finding database container...")
    # Look for container with 'db' or 'postgres' in name, excluding others if possible
    cmd_find_db = "docker ps --format '{{.ID}} {{.Names}}' | grep -E 'supabase-db|postgres' | head -n 1 | awk '{print $1}'"
    stdin, stdout, stderr = ssh.exec_command(cmd_find_db)
    container_id = stdout.read().decode().strip()
    
    if not container_id:
        print("❌ Could not find database container. Trying broader search...")
        cmd_find_db_2 = "docker ps -q --filter ancestor=supabase/postgres"
        stdin, stdout, stderr = ssh.exec_command(cmd_find_db_2)
        container_id = stdout.read().decode().strip()

    if not container_id:
        print("❌ ERROR: Database container not found.")
        ssh.close()
        return

    print(f"✅ Found database container: {container_id}")

    # 2. Upload SQL to VPS (to a temp file)
    remote_sql_path = "/tmp/fix_notifications.sql"
    print(f"Uploading SQL to {remote_sql_path}...")
    
    # Use sftp to upload
    sftp = ssh.open_sftp()
    sftp.put(SQL_FILE, remote_sql_path)
    sftp.close()
    
    # 3. Copy SQL file into container
    print("Copying SQL into container...")
    container_sql_path = "/tmp/fix.sql"
    ssh.exec_command(f"docker cp {remote_sql_path} {container_id}:{container_sql_path}")

    # 4. Execute SQL
    print("Executing SQL inside container...")
    cmd_exec = f"docker exec -i {container_id} psql -U postgres -d postgres -f {container_sql_path}"
    stdin, stdout, stderr = ssh.exec_command(cmd_exec)
    
    out = stdout.read().decode()
    err = stderr.read().decode()
    
    print("\n--- SQL Output ---")
    print(out)
    if err:
        print("\n--- SQL Errors/Warnings ---")
        print(err)
        
    if "CREATE TRIGGER" in out or "CREATE FUNCTION" in out or "GRANT" in out:
        print("\n✅ Fix applied successfully!")
    else:
        print("\n⚠️ Fix might have issues, check output above.")

    # Cleanup
    ssh.exec_command(f"rm {remote_sql_path}")
    ssh.exec_command(f"docker exec {container_id} rm {container_sql_path}")
    
    ssh.close()
    print("Disconnected.")

if __name__ == "__main__":
    apply_fix()
