# Define variables
$vpsUser = "root"
$vpsHost = "72.62.229.227"
$sshKeyPath = "$HOME\.ssh\id_ed25519"
$localSqlFile = ".\check_phone_user.sql"
$remoteSqlFile = "/root/check_phone_user.sql"

# 1. Copy the SQL file to the VPS
Write-Host "Copying SQL file to VPS..."
scp -i $sshKeyPath -o StrictHostKeyChecking=no $localSqlFile "${vpsUser}@${vpsHost}:${remoteSqlFile}"

# 2. Find the database container name
Write-Host "Finding database container..."
$dbContainerName = ssh -i $sshKeyPath -o StrictHostKeyChecking=no "${vpsUser}@${vpsHost}" "docker ps --filter name=supabase-db --format '{{.Names}}' | head -n 1"

if (-not $dbContainerName) {
    Write-Error "Could not find Supabase database container."
    exit 1
}
Write-Host "Database container found: $dbContainerName"

# 3. Execute the SQL script inside the database container
Write-Host "Executing SQL script..."
ssh -i $sshKeyPath -o StrictHostKeyChecking=no "${vpsUser}@${vpsHost}" "cat $remoteSqlFile | docker exec -i $dbContainerName psql -U postgres -d postgres"

Write-Host "Check complete."
