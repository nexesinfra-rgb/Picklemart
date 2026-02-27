# Define variables
$vpsUser = "root"
$vpsHost = "72.62.229.227"
$sshKeyPath = "$HOME\.ssh\id_ed25519"
$localSqlFile = ".\reset_passwords_vps_v2.sql"
$remoteSqlFile = "/root/reset_passwords_vps_v2.sql"

# 1. Copy the SQL file to the VPS
Write-Host "Copying SQL file to VPS..."
scp -i $sshKeyPath -o StrictHostKeyChecking=no $localSqlFile "${vpsUser}@${vpsHost}:${remoteSqlFile}"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to copy file to VPS."
    exit 1
}

# 2. Execute the SQL script inside the database container
Write-Host "Executing Password Reset Script..."
$cmd = "cat $remoteSqlFile | docker exec -i `$(docker ps -q --filter name=supabase-db | head -n 1) psql -U postgres -d postgres"
ssh -i $sshKeyPath -o StrictHostKeyChecking=no "${vpsUser}@${vpsHost}" $cmd

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to execute SQL script."
    exit 1
}

Write-Host "Passwords reset successfully."
