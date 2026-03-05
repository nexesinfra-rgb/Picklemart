import paramiko
import time
import os

# Configuration
VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"
SQL_FILE = "fix_cash_book_triggers.sql"

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

    # Check if SQL file exists
    if not os.path.exists(SQL_FILE):
        print(f"❌ SQL file not found: {SQL_FILE}")
        return

    # 1. Find Database Container
    print("Finding database container...")
    # Look for container with 'db' or 'postgres' in name
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
    remote_sql_path = "/tmp/fix_cash_book_triggers.sql"
    print(f"Uploading SQL to {remote_sql_path}...")
    
    try:
        sftp = ssh.open_sftp()
        sftp.put(SQL_FILE, remote_sql_path)
        sftp.close()
    except Exception as e:
        print(f"❌ Failed to upload SQL file: {e}")
        ssh.close()
        return
    
    # 3. Copy SQL file into container
    print("Copying SQL into container...")
    container_sql_path = "/tmp/fix_triggers.sql"
    ssh.exec_command(f"docker cp {remote_sql_path} {container_id}:{container_sql_path}")

    # 4. Execute SQL
    print("Executing SQL inside container...")
    # Using psql inside the container to execute the file
    cmd_exec = f"docker exec -i {container_id} psql -U postgres -d postgres -f {container_sql_path}"
    stdin, stdout, stderr = ssh.exec_command(cmd_exec)
    
    out = stdout.read().decode()
    err = stderr.read().decode()
    
    print("\n--- SQL Output ---")
    print(out)
    if err:
        print("\n--- SQL Errors/Warnings ---")
        print(err)
        
    if "CREATE TRIGGER" in out or "CREATE FUNCTION" in out:
        print("\n✅ Fix applied successfully! Triggers are now active.")
    else:
        print("\n⚠️ Fix might have issues, check output above.")

    # Cleanup
    try:
        ssh.exec_command(f"rm {remote_sql_path}")
        ssh.exec_command(f"docker exec {container_id} rm {container_sql_path}")
    except:
        pass
    
    ssh.close()
    print("Disconnected.")

if __name__ == "__main__":
    apply_fix()
