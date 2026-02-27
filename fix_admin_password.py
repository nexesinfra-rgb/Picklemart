
import paramiko
import time
import json

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def fix_admin_password():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Starting Admin Password Fix...")

    # 1. Get Anon Key and Auth IP
    print("Getting API Key and IP...")
    cmd_key = "docker exec $(docker ps -q --filter name=supabase-auth | head -n 1) printenv SUPABASE_ANON_KEY"
    stdin, stdout, stderr = ssh.exec_command(cmd_key)
    anon_key = stdout.read().decode().strip()
    
    cmd_ip = "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q --filter name=supabase-auth | head -n 1)"
    stdin, stdout, stderr = ssh.exec_command(cmd_ip)
    auth_ip = stdout.read().decode().strip()

    if not anon_key or not auth_ip:
        print("Failed to get Anon Key or Auth IP.")
        return

    # 2. Signup Temp User
    print(f"Signing up temp_fix_admin@sm.com at {auth_ip}...")
    signup_cmd = f"""curl -s -X POST "http://{auth_ip}:9999/signup" \
      -H "apikey: {anon_key}" \
      -H "Content-Type: application/json" \
      -d '{{"email": "temp_fix_admin@sm.com", "password": "admin123"}}'"""
    
    stdin, stdout, stderr = ssh.exec_command(signup_cmd)
    signup_res = stdout.read().decode().strip()
    print(f"Signup Result: {signup_res}")

    # 3. Get Hash from DB
    print("Fetching hash from DB...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()

    sql_get_hash = "SELECT encrypted_password FROM auth.users WHERE email = 'temp_fix_admin@sm.com';"
    cmd_sql = f'docker exec {db_container} psql -U postgres -d postgres -t -c "{sql_get_hash}"'
    stdin, stdout, stderr = ssh.exec_command(cmd_sql)
    new_hash = stdout.read().decode().strip()
    
    if not new_hash:
        print("Failed to get hash. Signup might have failed.")
        return

    print(f"Got new hash: {new_hash}")

    # 4. Update Admin User
    print("Updating admin@sm.com with new hash...")
    sql_update = f"UPDATE auth.users SET encrypted_password = '{new_hash}', email_confirmed_at = NOW() WHERE email = 'admin@sm.com';"
    cmd_update = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql_update}"'
    stdin, stdout, stderr = ssh.exec_command(cmd_update)
    print(stdout.read().decode().strip())

    # 5. Cleanup Temp User
    print("Cleaning up temp user...")
    sql_delete = "DELETE FROM auth.users WHERE email = 'temp_fix_admin@sm.com';"
    cmd_delete = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql_delete}"'
    stdin, stdout, stderr = ssh.exec_command(cmd_delete)
    print(stdout.read().decode().strip())

    print("\nDONE! Admin password reset to 'admin123'.")
    ssh.close()

if __name__ == "__main__":
    fix_admin_password()
