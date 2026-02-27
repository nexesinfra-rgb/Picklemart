#!/bin/bash
set -e

# Configuration
# URL Encoded Password: Venky@1234#1234 -> Venky%401234%231234
OLD_DB_URL="postgresql://postgres:Venky%401234%231234@db.bgqcuykvsiejgqeiefpi.supabase.co:5432/postgres"
NEW_DB_URL="postgresql://postgres:a3imslr4i2dXLWumtSRJR6vFVIII5URS@127.0.0.1:5432/postgres"

echo "Step 1: Install PostgreSQL 17 Client if missing..."
if ! command -v pg_dump &> /dev/null || [[ $(pg_dump --version) != *"17"* ]]; then
    # Add PostgreSQL repository to get version 17
    sudo apt-get update
    sudo apt-get install -y curl ca-certificates
    sudo install -d /usr/share/postgresql-common/pgdg
    sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
    sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    
    sudo apt-get update
    sudo apt-get install -y postgresql-client-17
fi

echo "Step 2: Dump Old Database..."
# Dump schema and data, cleaning existing objects first
# Using --no-owner and --no-privileges to avoid permission issues
pg_dump --verbose --clean --if-exists --quote-all-identifiers --no-owner --no-privileges --dbname="$OLD_DB_URL" -f dump.sql

# Try to find the correct container IP if 127.0.0.1 fails
# It might be running in a Docker container (Coolify)
# We need to find the Postgres container ID and use it or its IP

echo "Step 3: Prepare New Database (Terminate Connections)..."
# Check if docker is available and we can find a postgres container
if command -v docker &> /dev/null; then
    echo "Checking Docker containers..."
    # Try to find the Coolify/Supabase postgres container
    # Assuming Coolify names containers predictably or we can grep
    PG_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i "postgres" | head -n 1)
    
    if [ -n "$PG_CONTAINER" ]; then
        echo "Found Postgres container: $PG_CONTAINER"
        # Execute psql inside the container directly
        docker exec -i "$PG_CONTAINER" psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'postgres' AND pid <> pg_backend_pid();" || true
        
        echo "Step 4: Restore to New Database (via Docker exec)..."
        # We need to make sure the input is piped correctly
        # And handle errors during restore (like role already exists) more gracefully
        cat dump.sql | docker exec -i "$PG_CONTAINER" psql -U postgres -d postgres -v ON_ERROR_STOP=0
        
        echo "Database Migration Complete!"
        exit 0
    fi
else
    # Hardcoded fallback for Coolify Supabase
    PG_CONTAINER="supabase-db-ogw8kswcww8swko0c8gswsks"
    if docker ps | grep -q "$PG_CONTAINER"; then
         echo "Found Coolify Supabase container: $PG_CONTAINER"
         docker exec -i "$PG_CONTAINER" psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'postgres' AND pid <> pg_backend_pid();" || true
         cat dump.sql | docker exec -i "$PG_CONTAINER" psql -U postgres -d postgres -v ON_ERROR_STOP=0
         echo "Database Migration Complete!"
         exit 0
    fi
    
    echo "Docker not found or no postgres container running."
    echo "Listing running containers (if any):"
    docker ps -a || echo "Cannot list containers"
fi

# Try to find the port 5432 is listening on which IP
echo "Checking where Postgres is listening..."
sudo netstat -tulpn | grep 5432 || true

# If it's a Supabase/Coolify setup, it might be listening on the private docker network IP
# Let's try to connect to the docker gateway IP if 127.0.0.1 failed
DOCKER_GATEWAY=$(ip addr show docker0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
if [ -n "$DOCKER_GATEWAY" ]; then
    echo "Trying to connect via Docker Gateway: $DOCKER_GATEWAY"
    NEW_DB_URL_GATEWAY=$(echo $NEW_DB_URL | sed "s/127.0.0.1/$DOCKER_GATEWAY/")
    psql --dbname="$NEW_DB_URL_GATEWAY" -c "SELECT 1;" && \
    (
        echo "Connected via Gateway! Restoring..."
        psql --dbname="$NEW_DB_URL_GATEWAY" -f dump.sql
        exit 0
    )
fi

# Try to find postgres user password from coolify env if possible?
# No, we assume user provided correct password.

# Try connecting to unix socket if available
if [ -d "/var/run/postgresql" ]; then
    echo "Trying Unix socket..."
    # We need to strip the host/port part from the URL or just use psql params
    # But password auth might fail if it's expecting md5
    # Let's try to find if there is a running postgres process and see its args
    ps aux | grep postgres | head -n 5
fi

# If all else fails, assume it's running but maybe credentials or host is different
# Just exit so we can see the logs
echo "Failed to connect to local Postgres."
exit 1

echo "Database Migration Complete!"
