
import paramiko
import time

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

# Generated locally with bcrypt.hashpw(b'admin123', bcrypt.gensalt())
# Result: $2b$12$yslrxj6nrnfD2naKAcBT5ubVGP9Xzi6WyKBYdc/yCfk4S1maeqYGm
# NOTE: We must escape $ for shell execution (passed via docker exec "...")
KNOWN_HASH = r"\$2b\$12\$yslrxj6nrnfD2naKAcBT5ubVGP9Xzi6WyKBYdc/yCfk4S1maeqYGm"

def force_update_admin():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Forcing Admin Password Update...")

    # 1. Find DB Container
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if not db_container:
        print("DB container not found.")
        return

    # 2. Update Admin User
    print(f"Updating admin@sm.com with hash: {KNOWN_HASH}")
    sql_update = f"UPDATE auth.users SET encrypted_password = '{KNOWN_HASH}', email_confirmed_at = NOW(), confirmation_token = '' WHERE email = 'admin@sm.com';"
    cmd_update = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql_update}"'
    stdin, stdout, stderr = ssh.exec_command(cmd_update)
    print(stdout.read().decode().strip())
    print(stderr.read().decode().strip())

    # 3. Verify
    print("\nVerifying update...")
    sql_check = "SELECT email, encrypted_password FROM auth.users WHERE email = 'admin@sm.com';"
    cmd_check = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql_check}"'
    stdin, stdout, stderr = ssh.exec_command(cmd_check)
    print(stdout.read().decode().strip())

    ssh.close()

if __name__ == "__main__":
    force_update_admin()
