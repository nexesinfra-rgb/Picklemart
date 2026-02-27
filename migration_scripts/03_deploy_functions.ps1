# VPS Configuration
$VPS_IP = "72.62.229.227"
$VPS_USER = "root"
$FUNCTIONS_DIR = "supabase/functions"
$REMOTE_DIR = "/data/coolify/services/ogw8kswcww8swko0c8gswsks/volumes/functions"
$CONTAINER_NAME = "supabase-edge-functions-ogw8kswcww8swko0c8gswsks"

Write-Host "Deploying Edge Functions to VPS..."

# Check if scp is available
if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
    Write-Error "scp command not found. Please install OpenSSH Client."
    exit 1
}

# Create remote directory if not exists
Write-Host "Creating remote directory..."
ssh -o StrictHostKeyChecking=no -i "C:\Users\Venky\.ssh\id_ed25519" $VPS_USER@$VPS_IP "mkdir -p $REMOTE_DIR"

# Copy functions
Write-Host "Copying functions to VPS..."
scp -o StrictHostKeyChecking=no -i "C:\Users\Venky\.ssh\id_ed25519" -r "$FUNCTIONS_DIR/*" "${VPS_USER}@${VPS_IP}:${REMOTE_DIR}"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Functions files copied successfully!" -ForegroundColor Green
    
    Write-Host "Setting permissions and restarting Edge Runtime..."
    # Set permissions to deno user (1000:1000) and restart container
    ssh -o StrictHostKeyChecking=no -i "C:\Users\Venky\.ssh\id_ed25519" $VPS_USER@$VPS_IP "chown -R 1000:1000 $REMOTE_DIR && docker restart $CONTAINER_NAME"
    
    if ($LASTEXITCODE -eq 0) {
         Write-Host "✅ Edge Runtime restarted successfully! Functions are live." -ForegroundColor Green
    } else {
         Write-Host "❌ Failed to restart Edge Runtime." -ForegroundColor Red
    }
} else {
    Write-Host "❌ Failed to deploy functions." -ForegroundColor Red
}
