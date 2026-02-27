#!/bin/bash
echo "--- Docker Containers (Auth) ---"
docker ps --filter name=auth --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"

echo -e "\n--- Inspecting Auth Container Image ---"
AUTH_CONTAINER=$(docker ps -q --filter name=supabase-auth | head -n 1)

if [ -n "$AUTH_CONTAINER" ]; then
    echo "Found container ID: $AUTH_CONTAINER"
    docker inspect $AUTH_CONTAINER | grep "Image"
    
    echo -e "\n--- Finding Coolify Configuration ---"
    # Try to find the service directory
    # Inspecting mounts or labels might be more reliable
    SERVICE_DIR=$(docker inspect $AUTH_CONTAINER | grep "Source" | grep "coolify" | head -n 1 | awk -F'"' '{print $4}' | sed 's|/volumes.*||')
    
    if [ -n "$SERVICE_DIR" ]; then
        echo "Service Directory: $SERVICE_DIR"
        if [ -f "$SERVICE_DIR/docker-compose.yml" ]; then
            echo "Found docker-compose.yml. Content related to image:"
            grep -B 2 -A 2 "image:" "$SERVICE_DIR/docker-compose.yml"
        else
            echo "No docker-compose.yml found in service directory."
        fi
        
        if [ -f "$SERVICE_DIR/.env" ]; then
             echo "Found .env file."
        fi
    else
        echo "Could not locate Coolify service directory via mounts."
        # Try finding via labels
        echo "Checking labels..."
        docker inspect $AUTH_CONTAINER --format '{{json .Config.Labels}}'
    fi
else
    echo "No container found with name 'supabase-auth'."
fi
