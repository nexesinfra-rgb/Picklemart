import paramiko
import sys

VPS_IP = "72.62.229.227"
VPS_USER = "root"
VPS_PASS = "Nexes@123456"
SUFFIX = "ogw8kswcww8swko0c8gswsks"
AUTH_CONTAINER = f"supabase-auth-{SUFFIX}"

def main():
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(VPS_IP, username=VPS_USER, password=VPS_PASS)
        
        cmd = f"docker exec {AUTH_CONTAINER} printenv GOTRUE_MAILER_AUTOCONFIRM"
        print(f"Running: {cmd}")
        stdin, stdout, stderr = ssh.exec_command(cmd)
        print(f"Result: {stdout.read().decode().strip()}")
        ssh.close()
    except Exception as e:
        print(e)

if __name__ == "__main__":
    main()
