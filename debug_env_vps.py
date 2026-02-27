
import paramiko
import time

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def debug_env():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    # 1. Find the .env file
    print("Finding .env file...")
    cmd_find = 'find /data/coolify/services -maxdepth 2 -name ".env" -exec grep -l "GOTRUE" {} + | head -n 1'
    stdin, stdout, stderr = ssh.exec_command(cmd_find)
    env_path = stdout.read().decode().strip()
    print(f"Found .env at: {env_path}")

    if env_path:
        # 2. Cat the .env file
        print(f"Content of {env_path} (grep GOTRUE):")
        stdin, stdout, stderr = ssh.exec_command(f"grep 'GOTRUE' {env_path}")
        print(stdout.read().decode().strip())

    # 3. Check docker inspect
    print("\nChecking docker inspect for supabase-auth container...")
    # Get container ID/Name
    cmd_id = "docker ps -q --filter name=supabase-auth | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_id)
    container_id = stdout.read().decode().strip()
    
    if container_id:
        cmd_inspect = f"docker inspect {container_id} --format '{{{{json .Config.Env}}}}'"
        stdin, stdout, stderr = ssh.exec_command(cmd_inspect)
        env_json = stdout.read().decode().strip()
        print(f"Container Env: {env_json}")
    else:
        print("No supabase-auth container found.")

    ssh.close()

if __name__ == "__main__":
    debug_env()
