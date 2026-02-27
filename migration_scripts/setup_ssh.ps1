# SSH Setup Script
$KEY_PATH = "$HOME\.ssh\id_ed25519"
$PUB_KEY_PATH = "$KEY_PATH.pub"

Write-Host "Checking SSH Key..."

if (-not (Test-Path $KEY_PATH)) {
    Write-Host "Generating new SSH key..."
    # Use empty passphrase for automation
    # Fix: Use single quotes around double quotes for empty string argument in PowerShell
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N '""'
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to generate SSH key. Please run 'ssh-keygen -t ed25519' manually."
        exit 1
    }
} else {
    Write-Host "SSH key already exists."
}

$PUB_KEY = Get-Content $PUB_KEY_PATH
Write-Host "`nYOUR PUBLIC KEY:" -ForegroundColor Green
Write-Host $PUB_KEY -ForegroundColor Cyan

# Define VPS Details
$VPS_IP = "72.62.229.227"
$VPS_USER = "root"

Write-Host "`nStep 2: Copy Key to VPS" -ForegroundColor Yellow
Write-Host "We will now attempt to copy your public key to the VPS."
Write-Host "You will be asked for the VPS password ONE LAST TIME."
Write-Host "Password: Nexes@123456" -ForegroundColor Magenta

$Command = "mkdir -p ~/.ssh && echo `"$PUB_KEY`" >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"

# Run SSH command to append key
ssh -o StrictHostKeyChecking=no $VPS_USER@$VPS_IP $Command

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSUCCESS! SSH Key installed." -ForegroundColor Green
    Write-Host "You can now run the migration scripts without passwords."
} else {
    Write-Host "`nFailed to copy key automatically." -ForegroundColor Red
    Write-Host "Please run the following command manually and enter password 'Nexes@123456':"
    Write-Host "ssh $VPS_USER@$VPS_IP '$Command'"
}
