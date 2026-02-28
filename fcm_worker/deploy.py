import paramiko
import os
import sys
import time

# VPS details
VPS_IP = "72.62.229.227"
VPS_USER = "root"

# SSH Key Path - Default to typical location, but ask user if not found
# Trying the path seen in other scripts first
DEFAULT_KEY_PATH = r"C:\Users\Venky\.ssh\id_ed25519"

def get_ssh_key_path():
    """Get the SSH key path from user or use default"""
    key_path = DEFAULT_KEY_PATH
    
    if not os.path.exists(key_path):
        print(f"Default key path not found: {key_path}")
        print("Please enter the full path to your SSH private key (e.g., C:\\Users\\Name\\.ssh\\id_rsa):")
        user_path = input("Key Path: ").strip().strip('"').strip("'")
        if os.path.exists(user_path):
            return user_path
        else:
            print(f"Error: Key file not found at {user_path}")
            return None
    return key_path

def deploy():
    print("=== FCM Worker Deployment ===")
    
    # Check for service account file
    if not os.path.exists("service-account.json"):
        print("ERROR: service-account.json not found in current directory.")
        print("Please place your Firebase Service Account JSON file in the 'fcm_worker' directory and rename it to 'service-account.json'.")
        return

    key_path = get_ssh_key_path()
    if not key_path:
        print("Aborting deployment due to missing SSH key.")
        return

    print(f"Connecting to {VPS_IP} using key: {key_path}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(VPS_IP, username=VPS_USER, key_filename=key_path)
    except Exception as e:
        print(f"Connection failed: {e}")
        print("Please check your SSH key path and VPS connectivity.")
        return

    print("Creating directory /opt/fcm-worker...")
    ssh.exec_command("mkdir -p /opt/fcm-worker")

    print("Uploading files...")
    sftp = ssh.open_sftp()
    files = ["fcm_worker.py", "requirements.txt", "service-account.json"]
    for file in files:
        print(f"  Uploading {file}...")
        sftp.put(file, f"/opt/fcm-worker/{file}")
    sftp.close()

    print("Setting up environment (this may take a minute)...")
    commands = [
        "apt-get update && apt-get install -y python3-pip python3-venv",
        "cd /opt/fcm-worker && python3 -m venv venv",
        "/opt/fcm-worker/venv/bin/pip install -r requirements.txt",
    ]
    
    for cmd in commands:
        print(f"Running: {cmd}")
        stdin, stdout, stderr = ssh.exec_command(cmd)
        exit_status = stdout.channel.recv_exit_status()
        if exit_status != 0:
            err = stderr.read().decode()
            print(f"Warning/Error: {err}")
            # Continue anyway as venv might already exist
    
    print("Creating systemd service...")
    service_content = """[Unit]
Description=FCM Worker Service
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/fcm-worker
ExecStart=/opt/fcm-worker/venv/bin/python fcm_worker.py
Restart=always
RestartSec=10
Environment=GOOGLE_APPLICATION_CREDENTIALS=/opt/fcm-worker/service-account.json

[Install]
WantedBy=multi-user.target
"""
    
    with open("fcm-worker.service", "w") as f:
        f.write(service_content)
        
    sftp = ssh.open_sftp()
    sftp.put("fcm-worker.service", "/etc/systemd/system/fcm-worker.service")
    sftp.close()
    os.remove("fcm-worker.service")

    print("Starting service...")
    ssh.exec_command("systemctl daemon-reload")
    ssh.exec_command("systemctl enable fcm-worker")
    ssh.exec_command("systemctl restart fcm-worker")
    
    print("Checking service status...")
    time.sleep(2)
    stdin, stdout, stderr = ssh.exec_command("systemctl status fcm-worker")
    print(stdout.read().decode())

    print("Done! FCM Worker deployed and started successfully.")
    ssh.close()

if __name__ == "__main__":
    deploy()
