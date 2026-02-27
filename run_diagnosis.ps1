
$VPS_IP = "89.116.21.57"
$VPS_USER = "root"
$SSH_KEY_PATH = "$HOME\.ssh\id_ed25519"

Write-Host "1. Copying diagnosis script to VPS..."
scp -i $SSH_KEY_PATH ".\diagnose_auth.sh" "${VPS_USER}@${VPS_IP}:/root/sm/diagnose_auth.sh"

Write-Host "`n2. Running diagnosis script..."
ssh -i $SSH_KEY_PATH $VPS_USER@$VPS_IP "chmod +x /root/sm/diagnose_auth.sh && /root/sm/diagnose_auth.sh"
