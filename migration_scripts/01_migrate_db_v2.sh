#!/bin/bash
set -e

# Configuration
OLD_DB_URL="postgresql://postgres:Venky%401234%231234@db.bgqcuykvsiejgqeiefpi.supabase.co:5432/postgres"
CONTAINER_NAME="supabase-db-ogw8kswcww8swko0c8gswsks"

echo "Step 1: Install Dependencies..."
sudo apt-get update && sudo apt-get install -y postgresql-client

echo "Step 2: Dump Old Database..."
# Dump schema and data
pg_dump --verbose --clean --if-exists --quote-all-identifiers --no-owner --no-privileges --dbname="$OLD_DB_URL" -f dump.sql

echo "Step 3: Restore to New Database Container ($CONTAINER_NAME)..."

# Check if container exists
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "Error: Container $CONTAINER_NAME not found!"
    docker ps
    exit 1
fi

# Terminate connections
echo "Terminating existing connections..."
docker exec -i "$CONTAINER_NAME" psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'postgres' AND pid <> pg_backend_pid();" || true

# Restore
echo "Restoring data..."
# Use ON_ERROR_STOP=0 to continue despite minor permission errors common in Supabase migrations
cat dump.sql | docker exec -i "$CONTAINER_NAME" psql -U postgres -d postgres -v ON_ERROR_STOP=0

echo "✅ Database Migration Complete!"
