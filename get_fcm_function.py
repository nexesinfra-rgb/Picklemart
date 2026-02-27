import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def get_fcm_function():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Getting fcm function definition...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if db_container:
        sql = "SELECT pg_get_functiondef('public.send_fcm_push_notification'::regproc);"
        cmd_sql = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql}"'
        stdin, stdout, stderr = ssh.exec_command(cmd_sql)
        print(stdout.read().decode().strip())

    ssh.close()

if __name__ == "__main__":
    get_fcm_function()
