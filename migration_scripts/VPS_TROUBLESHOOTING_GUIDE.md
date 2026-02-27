# VPS Deployment Troubleshooting & Fixes Guide

This guide documents the critical fixes applied to the Coolify/Supabase VPS deployment to resolve Auth and Storage issues.

## 1. Disable Email Confirmation (Auth Service)
**Issue**: Users (including Admin) cannot log in immediately after signup because email verification is required but SMTP might not be configured yet.
**Fix**: Enable auto-confirmation for emails in the Supabase Auth (`gotrue`) service.

### Commands
Run these commands on the VPS (via SSH):

```bash
# 1. Navigate to the Coolify service directory
# (Note: The ID 'ogw8kswcww8swko0c8gswsks' is specific to this deployment)
cd /data/coolify/services/ogw8kswcww8swko0c8gswsks/

# 2. Update the .env file to enable auto-confirm
# This replaces 'ENABLE_EMAIL_AUTOCONFIRM=false' with 'true'
sed -i 's/ENABLE_EMAIL_AUTOCONFIRM=false/ENABLE_EMAIL_AUTOCONFIRM=true/g' .env

# 3. Restart the Auth service to apply changes
docker compose up -d supabase-auth

# 4. Verify the setting
docker exec supabase-auth-ogw8kswcww8swko0c8gswsks env | grep AUTOCONFIRM
# Output should show: ENABLE_EMAIL_AUTOCONFIRM=true
```

## 2. Fix Storage Permission Denied (Image Uploads)
**Issue**: The `supabase-storage` container crashes repeatedly with `permission denied for schema storage`. This happens because the migration or restore process often resets ownership of the `storage` schema to `postgres`, while the Storage service connects as `supabase_storage_admin`.
**Fix**: Explicitly grant ownership and all privileges on the `storage` schema to `supabase_storage_admin`.

### SQL Fix Script
Save this as `fix_storage_perms.sql` (already created in `migration_scripts/`):

```sql
GRANT USAGE ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON TABLES TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON SEQUENCES TO supabase_storage_admin;
GRANT CREATE ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL PRIVILEGES ON TABLE storage.migrations TO supabase_storage_admin;
ALTER SCHEMA storage OWNER TO supabase_storage_admin;
ALTER TABLE storage.migrations OWNER TO supabase_storage_admin;
```

### Applying the Fix
Run these commands from your local machine (PowerShell/Terminal):

```powershell
# 1. Copy the SQL script to the VPS
scp "migration_scripts\fix_storage_perms.sql" root@72.62.229.227:/tmp/fix_storage_perms.sql

# 2. Execute the script inside the Supabase DB container
ssh root@72.62.229.227 "cat /tmp/fix_storage_perms.sql | docker exec -i supabase-db-ogw8kswcww8swko0c8gswsks psql -U supabase_admin -d postgres"

# 3. Restart the Storage service
ssh root@72.62.229.227 "docker restart supabase-storage-ogw8kswcww8swko0c8gswsks"

# 4. Check logs to verify it started successfully
ssh root@72.62.229.227 "docker logs --tail 20 supabase-storage-ogw8kswcww8swko0c8gswsks"
# Look for: "Server listening at http://0.0.0.0:5000"
```

## 3. Useful Debugging Commands

### Check Container Status
```bash
docker ps
# Ensure all containers (especially supabase-auth and supabase-storage) are 'healthy' or 'Up'
```

### View Logs
```bash
# Auth Logs
docker logs --tail 50 supabase-auth-ogw8kswcww8swko0c8gswsks

# Storage Logs
docker logs --tail 50 supabase-storage-ogw8kswcww8swko0c8gswsks

# Database Logs
docker logs --tail 50 supabase-db-ogw8kswcww8swko0c8gswsks
```

### Check Database Permissions (Interactive)
```bash
docker exec -i supabase-db-ogw8kswcww8swko0c8gswsks psql -U postgres
# Inside psql:
# \dn+  (List schemas and owners)
# \du   (List roles)
```
