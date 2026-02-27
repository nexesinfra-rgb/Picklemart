# Define variables
$vpsUser = "root"
$vpsHost = "72.62.229.227"
$sshKeyPath = "$HOME\.ssh\id_ed25519"
$localSqlFile = ".\fix_auth_permissions.sql"
$remoteSqlFile = "/root/fix_auth_permissions.sql"

# 1. Copy the SQL file to the VPS
Write-Host "Copying SQL file to VPS..."
scp -i $sshKeyPath -o StrictHostKeyChecking=no $localSqlFile "${vpsUser}@${vpsHost}:${remoteSqlFile}"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to copy file to VPS. Please check your connection."
    exit 1
}

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

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to execute SQL script."
    exit 1
}

# 4. Restart the auth container
Write-Host "Restarting Auth container..."
$authContainerName = ssh -i $sshKeyPath -o StrictHostKeyChecking=no "${vpsUser}@${vpsHost}" "docker ps -a --filter name=supabase-auth --format '{{.Names}}' | head -n 1"

if ($authContainerName) {
    ssh -i $sshKeyPath -o StrictHostKeyChecking=no "${vpsUser}@${vpsHost}" "docker restart $authContainerName"
    Write-Host "Auth container restarted: $authContainerName"
} else {
    Write-Warning "Could not find Auth container to restart."
}

Write-Host "Fix applied successfully!"
