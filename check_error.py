
import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def check_error_log():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Checking auth logs for error...")
    cmd_logs = "docker logs $(docker ps -q --filter name=supabase-auth | head -n 1) 2>&1 | grep -C 5 '57326566-a918-4212-a744-f342f2edb2e3'"
    stdin, stdout, stderr = ssh.exec_command(cmd_logs)
    print(stdout.read().decode().strip())

    ssh.close()

if __name__ == "__main__":
    check_error_log()
