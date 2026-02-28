import paramiko
import os
import sys
import time

# VPS details
VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = r"C:\Users\Venky\.ssh\id_ed25519"

# Local paths - Use raw string literal for Windows path
WORKER_DIR = r"c:\Users\Venky\Downloads\Pickle mart(25-02-2026)\sm\fcm_worker"
FILES_TO_UPLOAD = ["fcm_worker.py", "requirements.txt", "service-account.json"]

def deploy_worker():
    print(f"Connecting to {VPS_IP}...")
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)
        print("Connected successfully.")
    except Exception as e:
        print(f"Connection failed: {e}")
        return

    # 1. Create directory
    print("Creating /opt/fcm-worker directory...")
    ssh.exec_command("mkdir -p /opt/fcm-worker")

    # 2. Upload files
    print("Uploading files...")
    try:
        sftp = ssh.open_sftp()
        for filename in FILES_TO_UPLOAD:
            local_path = os.path.join(WORKER_DIR, filename)
            remote_path = f"/opt/fcm-worker/{filename}"
            
            if not os.path.exists(local_path):
                print(f"❌ ERROR: Local file not found: {local_path}")
                print("Please make sure service-account.json is in the fcm_worker folder!")
                return
                
            print(f"  Uploading {filename}...")
            sftp.put(local_path, remote_path)
            
        # 3. Create Service File
        print("Creating systemd service file...")
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
        # Create temp file locally and upload it
        with open("fcm-worker.service", "w", encoding='utf-8') as f:
            f.write(service_content)
            
        sftp.put("fcm-worker.service", "/etc/systemd/system/fcm-worker.service")
        sftp.close()
        
    except Exception as e:
        print(f"Failed to upload files: {e}")
        return

    # 4. Setup Python environment
    print("Setting up Python environment (this may take a minute)...")
    commands = [
        "apt-get update",
        "apt-get install -y python3-pip python3-venv",
        "cd /opt/fcm-worker && python3 -m venv venv",
        "/opt/fcm-worker/venv/bin/pip install -r requirements.txt",
    ]
    
    for cmd in commands:
        print(f"Running: {cmd}")
        stdin, stdout, stderr = ssh.exec_command(cmd)
        exit_status = stdout.channel.recv_exit_status()
        if exit_status != 0:
            print(f"Warning: Command failed: {cmd}")
            # print(stderr.read().decode()) # Can be verbose
    
    # 5. Enable and Start Service
    print("Starting service...")
    ssh.exec_command("systemctl daemon-reload")
    ssh.exec_command("systemctl enable fcm-worker")
    ssh.exec_command("systemctl restart fcm-worker")
    
    time.sleep(3)
    
    # 6. Check Status
    stdin, stdout, stderr = ssh.exec_command("systemctl is-active fcm-worker")
    status = stdout.read().decode().strip()
    
    if status == "active":
        print("\n🎉 SUCCESS! FCM Worker is deployed and RUNNING.")
        print("Logs:")
        stdin, stdout, stderr = ssh.exec_command("journalctl -u fcm-worker -n 10 --no-pager")
        print(stdout.read().decode())
    else:
        print(f"\n❌ Service failed to start. Status: {status}")
        print("Logs:")
        stdin, stdout, stderr = ssh.exec_command("journalctl -u fcm-worker -n 20 --no-pager")
        print(stdout.read().decode())

    ssh.close()

if __name__ == "__main__":
    deploy_worker()
