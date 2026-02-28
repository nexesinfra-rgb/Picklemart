# FCM Worker Deployment Script for PowerShell
# Usage: .\deploy.ps1 [-KeyPath "C:\path\to\key"]

param (
    [string]$KeyPath = ""
)

$VPS_IP = "72.62.229.227"
$VPS_USER = "root"

Write-Host "=== FCM Worker Deployment ===" -ForegroundColor Cyan

# Check for service-account.json
if (-not (Test-Path "service-account.json")) {
    Write-Host "ERROR: service-account.json not found in current directory." -ForegroundColor Red
    Write-Host "Please place your Firebase Service Account JSON file in the 'fcm_worker' directory and rename it to 'service-account.json'."
    exit 1
}

# Get SSH Key Path
if ([string]::IsNullOrEmpty($KeyPath)) {
    # Try to find key in common locations
    $PossibleKeys = @(
        "$env:USERPROFILE\.ssh\id_ed25519",
        "$env:USERPROFILE\.ssh\id_rsa",
        "C:\Users\Venky\.ssh\id_ed25519" # From user context
    )
    
    foreach ($path in $PossibleKeys) {
        if (Test-Path $path) {
            $KeyPath = $path
            break
        }
    }
    
    if ([string]::IsNullOrEmpty($KeyPath)) {
        Write-Host "SSH Key not found in default locations." -ForegroundColor Yellow
        $KeyPath = Read-Host "Please enter the full path to your SSH private key (e.g., C:\Users\Name\.ssh\id_rsa)"
        $KeyPath = $KeyPath.Trim('"').Trim("'")
    }
}

if (-not (Test-Path $KeyPath)) {
    Write-Host "ERROR: SSH Key file not found at: $KeyPath" -ForegroundColor Red
    exit 1
}

Write-Host "Using SSH Key: $KeyPath" -ForegroundColor Green

# Define SSH Command Prefix
$SSH_CMD = "ssh -i `"$KeyPath`" -o StrictHostKeyChecking=no $VPS_USER@$VPS_IP"
$SCP_CMD = "scp -i `"$KeyPath`" -o StrictHostKeyChecking=no"

# 1. Create directory
Write-Host "Creating directory /opt/fcm-worker on VPS..."
Invoke-Expression "$SSH_CMD 'mkdir -p /opt/fcm-worker'"

# 2. Upload files
Write-Host "Uploading files..."
$Files = @("fcm_worker.py", "requirements.txt", "service-account.json")
foreach ($File in $Files) {
    Write-Host "  Uploading $File..."
    Invoke-Expression "$SCP_CMD $File $VPS_USER@$VPS_IP`:/opt/fcm-worker/"
}

# 3. Setup Environment
Write-Host "Setting up Python environment (this may take a minute)..."
$SetupCmd = "apt-get update && apt-get install -y python3-pip python3-venv && cd /opt/fcm-worker && python3 -m venv venv && /opt/fcm-worker/venv/bin/pip install -r requirements.txt"
Invoke-Expression "$SSH_CMD `"$SetupCmd`""

# 4. Create Service File
Write-Host "Creating systemd service..."
$ServiceContent = @"
[Unit]
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
"@

# Write service file locally then upload
$ServiceFile = "fcm-worker.service"
Set-Content -Path $ServiceFile -Value $ServiceContent
Invoke-Expression "$SCP_CMD $ServiceFile $VPS_USER@$VPS_IP`:/etc/systemd/system/"
Remove-Item $ServiceFile

# 5. Enable and Start Service
Write-Host "Starting service..."
Invoke-Expression "$SSH_CMD 'systemctl daemon-reload && systemctl enable fcm-worker && systemctl restart fcm-worker'"

# 6. Check Status
Write-Host "Checking service status..."
Start-Sleep -Seconds 2
Invoke-Expression "$SSH_CMD 'systemctl status fcm-worker'"

Write-Host "Done! FCM Worker deployed and started successfully." -ForegroundColor Green
