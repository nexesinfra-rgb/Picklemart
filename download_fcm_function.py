import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def download_fcm_function():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Downloading fcm function definition...")
    cmd_db = "docker ps -q --filter name=supabase-db | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_db)
    db_container = stdout.read().decode().strip()
    
    if db_container:
        sql = "COPY (SELECT pg_get_functiondef('public.send_fcm_push_notification'::regproc)) TO STDOUT;"
        cmd_sql = f'docker exec {db_container} psql -U postgres -d postgres -c "{sql}" > /root/fcm_func.sql'
        ssh.exec_command(cmd_sql)
        
        sftp = ssh.open_sftp()
        sftp.get("/root/fcm_func.sql", "c:/Users/Venky/OneDrive/Desktop/optimize/Projects to vps hosting please/Pickle mart05022026/Pickle mart05022026/Pickle mart/sm/fcm_func.sql")
        sftp.close()
        
        ssh.exec_command("rm /root/fcm_func.sql")
        print("Downloaded to fcm_func.sql")

    ssh.close()

if __name__ == "__main__":
    download_fcm_function()
