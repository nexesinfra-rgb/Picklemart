
$VPS_IP = "89.116.21.57"
$VPS_USER = "root"
$SSH_KEY_PATH = "$HOME\.ssh\id_ed25519"

Write-Host "Connecting to VPS to diagnose Supabase Auth container..."

$SCRIPT_BLOCK = {
    echo "--- Docker Containers (Auth) ---"
    docker ps --filter name=auth --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
    
    echo "`n--- Inspecting Auth Container Image ---"
    AUTH_CONTAINER=$(docker ps -q --filter name=supabase-auth | head -n 1)
    if [ -n "$AUTH_CONTAINER" ]; then
        docker inspect $AUTH_CONTAINER | grep "Image"
        
        echo "`n--- Finding Coolify Configuration ---"
        # Try to find the service directory
        SERVICE_DIR=$(docker inspect $AUTH_CONTAINER | grep "Source" | grep "coolify" | head -n 1 | awk -F'"' '{print $4}' | sed 's|/volumes.*||')
        
        if [ -n "$SERVICE_DIR" ]; then
            echo "Service Directory: $SERVICE_DIR"
            if [ -f "$SERVICE_DIR/docker-compose.yml" ]; then
                echo "Found docker-compose.yml. Content related to image:"
                grep -B 2 -A 2 "image:" "$SERVICE_DIR/docker-compose.yml"
            else
                echo "No docker-compose.yml found in service directory."
            fi
        else
            echo "Could not locate Coolify service directory."
        fi
    else
        echo "No container found with name 'supabase-auth'."
    fi
}

ssh -i $SSH_KEY_PATH $VPS_USER@$VPS_IP "$SCRIPT_BLOCK"
