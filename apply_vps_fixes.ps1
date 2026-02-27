# VPS Configuration Script
# Usage: .\apply_vps_fixes.ps1

$VPS_IP = "89.116.21.57"
$VPS_USER = "root"
$SSH_KEY_PATH = "$HOME\.ssh\id_ed25519"
$SSH_PUB_KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJa3EdpUv8EUVNA/UF1BSqnHxS6pGb0VhZ+NjfDuA4Z venky@VH"

Write-Host "1. Setting up SSH Key for passwordless access..."
Write-Host "   You will be asked for the password ('Nexes@123456') one last time."
ssh $VPS_USER@$VPS_IP "mkdir -p ~/.ssh && echo '$SSH_PUB_KEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh"

if ($LASTEXITCODE -eq 0) {
    Write-Host "   SSH Key configured successfully!"
} else {
    Write-Host "   Failed to configure SSH key. Subsequent commands might fail or ask for password."
}

Write-Host "`n2. Copying RLS Fix Script..."
scp -i $SSH_KEY_PATH ".\fix_rls_policies.sql" "${VPS_USER}@${VPS_IP}:/root/sm/fix_rls_policies.sql"

Write-Host "`n3. Applying RLS Fix (Granting permissions to Auth Admin)..."
ssh -i $SSH_KEY_PATH $VPS_USER@$VPS_IP "docker exec -i supabase-db psql -U postgres -d postgres -f /root/sm/fix_rls_policies.sql"

Write-Host "`n4. Disabling Email Confirmation (Auto-Confirm)..."
# Attempt to find and update the env file for Supabase Auth
$SCRIPT_BLOCK = {
    # Find the service directory containing the auth container config
    SERVICE_DIR=$(docker inspect $(docker ps -q --filter name=supabase-auth | head -n 1) | grep "Source" | grep "coolify" | head -n 1 | awk -F'"' '{print $4}' | sed 's|/volumes.*||')
    
    if [ -z "$SERVICE_DIR" ]; then
        echo "   Could not locate Coolify service directory automatically."
    else
        echo "   Found Service Directory: $SERVICE_DIR"
        ENV_FILE="$SERVICE_DIR/.env"
        
        if [ -f "$ENV_FILE" ]; then
            echo "   Updating .env file..."
            # Check if variable exists
            if grep -q "GOTRUE_MAILER_AUTOCONFIRM" "$ENV_FILE"; then
                sed -i 's/GOTRUE_MAILER_AUTOCONFIRM=.*/GOTRUE_MAILER_AUTOCONFIRM=true/' "$ENV_FILE"
            else
                echo "GOTRUE_MAILER_AUTOCONFIRM=true" >> "$ENV_FILE"
            fi
            
            # Also ensure secure email change is disabled if needed, but let's stick to autoconfirm first
            
            echo "   Restarting Supabase Auth container..."
            docker restart $(docker ps -q --filter name=supabase-auth)
            echo "   Email Confirmation Disabled."
        else
            echo "   .env file not found at $ENV_FILE"
        fi
    fi
}
ssh -i $SSH_KEY_PATH $VPS_USER@$VPS_IP "$SCRIPT_BLOCK"

Write-Host "`n5. Verifying Fixes..."
# Try to run the signup check again via SSH
ssh -i $SSH_KEY_PATH $VPS_USER@$VPS_IP "bash /root/sm/generate_hash_v2.sh"

Write-Host "`nDone!"
