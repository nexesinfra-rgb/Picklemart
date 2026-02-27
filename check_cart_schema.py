import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def check_cart_schema():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Checking cart_items schema...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if db_container:
        sql = "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'cart_items';"
        cmd_sql = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql}"'
        stdin, stdout, stderr = ssh.exec_command(cmd_sql)
        print(stdout.read().decode().strip())

    ssh.close()

if __name__ == "__main__":
    check_cart_schema()
