import paramiko

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def check_vps_env():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Checking VPS Env...")
    # List files in the service directory
    base_dir = "/data/coolify/services/ogw8kswcww8swko0c8gswsks"
    stdin, stdout, stderr = ssh.exec_command(f"ls -la {base_dir}")
    print(stdout.read().decode().strip())
    
    # Check .env content (masking keys slightly if needed, but I need the key)
    # I'll just grep for ANON_KEY
    stdin, stdout, stderr = ssh.exec_command(f"grep 'ANON_KEY' {base_dir}/.env")
    print("\nANON_KEY:")
    print(stdout.read().decode().strip())

    ssh.close()

if __name__ == "__main__":
    check_vps_env()
