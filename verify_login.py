
import paramiko
import json

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def verify_login():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)

    print("Verifying Admin Login...")

    # 1. Get Anon Key and Auth IP
    cmd_key = "docker exec $(docker ps -q --filter name=supabase-auth | head -n 1) printenv SUPABASE_ANON_KEY"
    stdin, stdout, stderr = ssh.exec_command(cmd_key)
    anon_key = stdout.read().decode().strip()
    
    cmd_ip = "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q --filter name=supabase-auth | head -n 1)"
    stdin, stdout, stderr = ssh.exec_command(cmd_ip)
    auth_ip = stdout.read().decode().strip()

    if not anon_key or not auth_ip:
        print("Failed to get Anon Key or Auth IP.")
        return

    # 2. Try Login
    # Using grant_type=password
    print(f"Attempting login for admin@sm.com at {auth_ip}...")
    login_cmd = f"""curl -s -X POST "http://{auth_ip}:9999/token?grant_type=password" \
      -H "apikey: {anon_key}" \
      -H "Content-Type: application/json" \
      -d '{{"email": "admin@sm.com", "password": "admin123"}}'"""
    
    stdin, stdout, stderr = ssh.exec_command(login_cmd)
    result = stdout.read().decode().strip()
    
    try:
        res_json = json.loads(result)
        if "access_token" in res_json:
            print("\nSUCCESS: Login successful! Access Token received.")
            print(f"User ID: {res_json.get('user', {}).get('id')}")
        else:
            print("\nFAILURE: Login failed.")
            print(f"Response: {result}")
    except json.JSONDecodeError:
        print(f"\nERROR: Invalid JSON response: {result}")

    ssh.close()

if __name__ == "__main__":
    verify_login()
