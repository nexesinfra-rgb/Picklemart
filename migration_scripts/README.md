# Supabase Migration Guide (Pickle Mart)

This folder contains scripts to migrate your Supabase project to the new self-hosted VPS.

## 🛑 IMPORTANT: First Step (Fix SSH)

The previous error "Failed to generate SSH key" has been fixed. Please run the setup script again:

1.  **Open PowerShell** in this folder.
2.  Run:
    ```powershell
    ./setup_ssh.ps1
    ```
3.  **When prompted for a password**, type: `Nexes@123456`
    *(You won't see the characters as you type, just type it and press Enter)*

---

## Migration Steps (After SSH is Fixed)

### Step 1: Migrate Storage (✅ Completed)
The storage buckets and files have already been migrated successfully.

### Step 2: Migrate Database & Auth (The Main Part)
This step must be run on the VPS to ensure fast and reliable data transfer.

1.  **Copy the migration script to VPS:**
    ```powershell
    scp migration_scripts/01_migrate_db_on_vps.sh root@72.62.229.227:/root/
    ```

2.  **SSH into VPS and run the script:**
    ```bash
    ssh root@72.62.229.227
    chmod +x 01_migrate_db_on_vps.sh
    ./01_migrate_db_on_vps.sh
    ```
    *(This handles Schema, Data, RLS policies, and Auth users automatically)*

### Step 3: Deploy Edge Functions
Run this script locally to copy your functions to the VPS:
```powershell
./migration_scripts/03_deploy_functions.ps1
```

**Note:** After copying, verify the functions are in the correct volume on your VPS (likely `/data/coolify/services/...`).

---

## Troubleshooting

- **Password Issues**: If `ssh` or `scp` keeps asking for a password, run `./setup_ssh.ps1` again and ensure the key is added to the VPS.
- **Database Errors**: If the migration script fails on the VPS, check if the VPS can connect to the internet (to reach the old Supabase DB).
