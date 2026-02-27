# VPS Deployment & Troubleshooting Guide for Pickle Mart

This guide covers the complete process for deploying the Pickle Mart backend (Supabase) to a Coolify-managed VPS, including database migration, edge functions deployment, and troubleshooting critical issues.

## 1. Prerequisites & Environment

-   **VPS IP**: `72.62.229.227`
-   **SSH User**: `root`
-   **Coolify Service ID**: `ogw8kswcww8swko0c8gswsks`
-   **Service Path**: `/data/coolify/services/ogw8kswcww8swko0c8gswsks`
-   **Local SSH Key**: `~/.ssh/id_ed25519` (Authorized on VPS)

## 2. Deployment Steps

### Step 1: Database Migration
To migrate the database schema and data from the old Supabase instance to the VPS:

1.  **Backup Old Database**:
    Ensure you have the connection string for the old database.

2.  **Run Migration Script**:
    Use the provided script `migration_scripts/01_migrate_db_v2.sh`. This script:
    -   Installs PostgreSQL 17 client (if missing).
    -   Dumps the old database (`pg_dump`).
    -   Restores it to the VPS Supabase instance (`psql` via Docker).

    ```bash
    # Run from Git Bash or WSL
    cd migration_scripts
    ./01_migrate_db_v2.sh
    ```

### Step 2: Edge Functions Deployment
Supabase Edge Functions are deployed by copying the source files to the VPS volume and restarting the service.

1.  **Deploy Script**:
    Use `migration_scripts/03_deploy_functions.ps1`. This script:
    -   Copies `supabase/functions/*` to the VPS directory `/data/coolify/services/.../volumes/functions`.
    -   Sets ownership to `deno:deno` (UID 1000).
    -   Restarts the `supabase-edge-functions` container.

    ```powershell
    # Run from PowerShell
    cd migration_scripts
    ./03_deploy_functions.ps1
    ```

### Step 3: Environment Configuration
Ensure these critical environment variables are set in Coolify (Service -> Configuration -> Environment Variables):

-   `FIREBASE_SERVICE_ACCOUNT`: Full JSON content for FCM notifications.
-   `ENABLE_EMAIL_AUTOCONFIRM`: Set to `true` (see troubleshooting below).
-   `GOTRUE_MAILER_AUTOCONFIRM`: Set to `true`.
-   `API_EXTERNAL_URL`: `http://<VPS_IP>:8000` (or your domain).
-   `SUPABASE_PUBLIC_URL`: `http://<VPS_IP>:8000` (or your domain).

---

## 3. Troubleshooting & Fixes

### Issue 1: Users Cannot Login (Email Confirmation)
**Symptom**: New users (and Admin) cannot log in immediately because email verification is required, but SMTP is not configured.
**Fix**: Disable email confirmation.

1.  **SSH into VPS**:
    ```bash
    ssh root@72.62.229.227
    ```
2.  **Update Config**:
    ```bash
    cd /data/coolify/services/ogw8kswcww8swko0c8gswsks/
    sed -i 's/ENABLE_EMAIL_AUTOCONFIRM=false/ENABLE_EMAIL_AUTOCONFIRM=true/g' .env
    ```
3.  **Restart Auth Service**:
    ```bash
    docker compose up -d supabase-auth
    ```

### Issue 2: Image Uploads Fail (Permission Denied)
**Symptom**: `supabase-storage` container crashes or returns 500 errors. Logs show `permission denied for schema storage`.
**Cause**: Database restoration resets ownership of the `storage` schema to `postgres`.
**Fix**: Grant ownership to `supabase_storage_admin`.

1.  **Run Fix Script**:
    Save the following SQL as `fix_storage_perms.sql`:
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
2.  **Execute on VPS**:
    ```powershell
    scp "migration_scripts\fix_storage_perms.sql" root@72.62.229.227:/tmp/fix_storage_perms.sql
    ssh root@72.62.229.227 "cat /tmp/fix_storage_perms.sql | docker exec -i supabase-db-ogw8kswcww8swko0c8gswsks psql -U supabase_admin -d postgres"
    ssh root@72.62.229.227 "docker restart supabase-storage-ogw8kswcww8swko0c8gswsks"
    ```

### Issue 3: RLS Violations
**Symptom**: Admin operations fail with "row-level security policy violation".
**Fix**: Ensure RLS policies exist for `auth.users` and other tables.

1.  **Check Policies**:
    ```bash
    ssh root@72.62.229.227 "docker exec -i supabase-db-ogw8kswcww8swko0c8gswsks psql -U postgres -c 'SELECT * FROM pg_policies WHERE tablename = ''users'';'"
    ```
2.  **Apply Policies (if missing)**:
    See `migration_scripts/fix_rls.sql` for the necessary policies.

## 4. Useful Commands

| Action | Command |
| :--- | :--- |
| **Check Containers** | `ssh root@72.62.229.227 "docker ps"` |
| **View Auth Logs** | `ssh root@72.62.229.227 "docker logs --tail 50 supabase-auth-ogw8kswcww8swko0c8gswsks"` |
| **View Storage Logs** | `ssh root@72.62.229.227 "docker logs --tail 50 supabase-storage-ogw8kswcww8swko0c8gswsks"` |
| **DB Shell** | `ssh root@72.62.229.227 "docker exec -it supabase-db-ogw8kswcww8swko0c8gswsks psql -U postgres"` |
