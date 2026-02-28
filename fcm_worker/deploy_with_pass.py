import paramiko
import os
import sys
import time

VPS_IP = '72.62.229.227'
VPS_USER = 'root'
PASSWORD = 'Nexes@123456'

def deploy():
    print('Connecting to ' + VPS_IP + '...')
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(VPS_IP, username=VPS_USER, password=PASSWORD)
    except Exception as e:
        print(f'Connection failed: {e}')
        return

    print('Creating directory /opt/fcm-worker...')
    ssh.exec_command('mkdir -p /opt/fcm-worker')

    print('Uploading files...')
    sftp = ssh.open_sftp()
    files = ['fcm_worker.py', 'requirements.txt', 'service-account.json']
    for file in files:
        if os.path.exists(file):
            print(f'  Uploading {file}...')
            sftp.put(file, f'/opt/fcm-worker/{file}')
        else:
            print(f'Warning: {file} not found!')
    sftp.close()

    print('Setting up environment...')
    commands = [
        'apt-get update && apt-get install -y python3-pip python3-venv',
        'cd /opt/fcm-worker && python3 -m venv venv',
        '/opt/fcm-worker/venv/bin/pip install -r requirements.txt'
    ]
    
    for cmd in commands:
        print(f'Running: {cmd}')
        stdin, stdout, stderr = ssh.exec_command(cmd)
        exit_status = stdout.channel.recv_exit_status()
        if exit_status != 0:
            print(f'Error: {stderr.read().decode()}')

    print('Creating systemd service...')
    service_content = '''[Unit]
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
'''
    
    with open('fcm-worker.service', 'w') as f:
        f.write(service_content)
        
    sftp = ssh.open_sftp()
    sftp.put('fcm-worker.service', '/etc/systemd/system/fcm-worker.service')
    sftp.close()
    if os.path.exists('fcm-worker.service'):
        os.remove('fcm-worker.service')

    print('Starting service...')
    ssh.exec_command('systemctl daemon-reload')
    ssh.exec_command('systemctl enable fcm-worker')
    ssh.exec_command('systemctl restart fcm-worker')
    
    print('Checking service status...')
    time.sleep(2)
    stdin, stdout, stderr = ssh.exec_command('systemctl status fcm-worker')
    print(stdout.read().decode())

    print('Done! FCM Worker deployed and started successfully.')
    ssh.close()

if __name__ == '__main__':
    deploy()
