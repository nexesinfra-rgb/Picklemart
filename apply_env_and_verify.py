
import paramiko
import time

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def apply_env_and_verify():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    compose_dir = "/data/coolify/services/ogw8kswcww8swko0c8gswsks"

    # 1. Apply changes with docker compose up -d
    print(f"Applying changes in {compose_dir}...")
    # Try 'docker compose' first, fallback to 'docker-compose'
    cmd_up = f"cd {compose_dir} && docker compose up -d supabase-auth"
    print(f"Running: {cmd_up}")
    stdin, stdout, stderr = ssh.exec_command(cmd_up)
    exit_status = stdout.channel.recv_exit_status()
    
    if exit_status != 0:
        print("docker compose failed, trying docker-compose...")
        cmd_up = f"cd {compose_dir} && docker-compose up -d supabase-auth"
        stdin, stdout, stderr = ssh.exec_command(cmd_up)
        print(stdout.read().decode())
        print(stderr.read().decode())
    else:
        print("docker compose up -d executed successfully.")
        print(stdout.read().decode())

    # Wait a bit for restart
    print("Waiting 5 seconds for container restart...")
    time.sleep(5)

    # 2. Verify env var in container
    print("\nVerifying GOTRUE_MAILER_AUTOCONFIRM in container...")
    cmd_id = "docker ps -q --filter name=supabase-auth | head -n 1"
    stdin, stdout, stderr = ssh.exec_command(cmd_id)
    container_id = stdout.read().decode().strip()
    
    if container_id:
        cmd_inspect = f"docker inspect {container_id} --format '{{{{json .Config.Env}}}}'"
        stdin, stdout, stderr = ssh.exec_command(cmd_inspect)
        env_json = stdout.read().decode().strip()
        if "GOTRUE_MAILER_AUTOCONFIRM=true" in env_json:
            print("SUCCESS: GOTRUE_MAILER_AUTOCONFIRM=true found in container env.")
        else:
            print("FAILURE: GOTRUE_MAILER_AUTOCONFIRM=true NOT found in container env.")
            # Debug: print full env
            # print(env_json) 
    else:
        print("supabase-auth container not found.")

    ssh.close()

if __name__ == "__main__":
    apply_env_and_verify()
