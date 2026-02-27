
import paramiko
import time

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def check_admin_and_compose():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    # 1. Find docker-compose.yml
    print("Finding docker-compose.yml...")
    cmd_find = 'find /data/coolify/services -maxdepth 2 -name "docker-compose.yml" -exec grep -l "supabase-auth" {} + | head -n 1'
    stdin, stdout, stderr = ssh.exec_command(cmd_find)
    compose_path = stdout.read().decode().strip()
    print(f"Found docker-compose.yml at: {compose_path}")
    
    compose_dir = ""
    if compose_path:
        compose_dir = "/".join(compose_path.split("/")[:-1])
        print(f"Compose dir: {compose_dir}")

    # 2. Check admin user status
    print("\nChecking admin user status in DB...")
    # Find DB container
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if db_container:
        sql = "SELECT email, encrypted_password, email_confirmed_at, confirmation_token, raw_app_meta_data FROM auth.users WHERE email = 'admin@sm.com';"
        cmd_sql = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql}"'
        stdin, stdout, stderr = ssh.exec_command(cmd_sql)
        print(stdout.read().decode().strip())
    else:
        print("DB container not found.")

    ssh.close()
    return compose_dir

if __name__ == "__main__":
    check_admin_and_compose()
