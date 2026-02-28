import paramiko
import time
import os

VPS_IP = "72.62.229.227"
VPS_USER = "root"
KEY_FILE = "C:\\Users\\Venky\\.ssh\\id_ed25519"

def restart_worker():
    print(f"Connecting to VPS {VPS_IP}...")
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(VPS_IP, username=VPS_USER, key_filename=KEY_FILE)
        print("Connected successfully.")
    except Exception as e:
        print(f"Failed to connect: {e}")
        return

    # Check service status
    print("\nChecking FCM Worker status...")
    stdin, stdout, stderr = ssh.exec_command("systemctl is-active fcm-worker")
    status = stdout.read().decode().strip()
    
    if status == "active":
        print("✅ FCM Worker is currently running.")
        print("Restarting to pick up latest database changes...")
        ssh.exec_command("systemctl restart fcm-worker")
        time.sleep(2) # Wait for restart
    else:
        print(f"⚠️ FCM Worker is NOT running (Status: {status}).")
        print("Attempting to start/enable service...")
        
        # Check if service file exists
        stdin, stdout, stderr = ssh.exec_command("ls /etc/systemd/system/fcm-worker.service")
        if not stdout.read().decode().strip():
            print("❌ Service file missing! You may need to run full deployment.")
            # We can try to deploy the service file here if needed, but let's see first.
        else:
            ssh.exec_command("systemctl daemon-reload")
            ssh.exec_command("systemctl enable fcm-worker")
            ssh.exec_command("systemctl start fcm-worker")
            time.sleep(2)

    # Verify status after action
    stdin, stdout, stderr = ssh.exec_command("systemctl is-active fcm-worker")
    final_status = stdout.read().decode().strip()
    
    if final_status == "active":
        print("\n🎉 FCM Worker is ACTIVE and RUNNING!")
        
        # Show logs
        print("\n--- Recent Logs ---")
        stdin, stdout, stderr = ssh.exec_command("journalctl -u fcm-worker -n 20 --no-pager")
        print(stdout.read().decode())
        print("-------------------")
    else:
        print(f"\n❌ FCM Worker failed to start (Status: {final_status}).")
        print("Checking logs for errors...")
        stdin, stdout, stderr = ssh.exec_command("journalctl -u fcm-worker -n 50 --no-pager")
        print(stdout.read().decode())

    ssh.close()
    print("Disconnected.")

if __name__ == "__main__":
    restart_worker()
