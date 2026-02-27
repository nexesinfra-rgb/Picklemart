import paramiko
import sys

VPS_IP = "72.62.229.227"
VPS_USER = "root"
VPS_PASS = "Nexes@123456"

def main():
    try:
        print(f"Connecting to {VPS_IP}...")
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(VPS_IP, username=VPS_USER, password=VPS_PASS)
        print("Connected successfully!")

        stdin, stdout, stderr = ssh.exec_command("docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}'")
        print("\n--- Running Containers ---")
        print(stdout.read().decode())
        
        ssh.close()

    except Exception as e:
        print(f"\n[Fatal Error] {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
