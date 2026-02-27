# Supabase CLI Usage Guide

## Installation

Supabase CLI is already installed via Scoop:
```powershell
scoop install supabase
```

## Authentication

1. **Login to Supabase:**
   ```powershell
   supabase login
   ```
   This will open a browser window for authentication.

2. **Verify login:**
   ```powershell
   supabase projects list
   ```

## Linking Project

1. **Link to your Supabase project:**
   ```powershell
   supabase link --project-ref okjuhvgavbcbbnzvvyxc
   ```
   You may be prompted for the database password.

2. **Verify link:**
   ```powershell
   supabase status
   ```

## Running Migrations

### Method 1: Using Supabase CLI (Recommended)

1. **Place migration files in `supabase/migrations/`:**
   - Migration files should be named with timestamp: `YYYYMMDDHHMMSS_description.sql`
   - Example: `20250112000000_setup_admin_user.sql`

2. **Push migrations to Supabase:**
   ```powershell
   supabase db push --linked --include-all
   ```

### Method 2: Using PowerShell Script

1. **Run the setup script:**
   ```powershell
   .\scripts\run_admin_setup.ps1
   ```

### Method 3: Manual SQL Execution

1. **Open Supabase SQL Editor:**
   - Go to: https://okjuhvgavbcbbnzvvyxc.supabase.co
   - Navigate to SQL Editor
   - Copy and paste the SQL from `supabase_migrations/006_setup_admin_user_id.sql`
   - Run the query

## Common Commands

### Database Operations

```powershell
# Push migrations
supabase db push --linked --include-all

# Pull schema from remote
supabase db pull

# Reset local database
supabase db reset

# Dump database
supabase db dump --linked

# Check migration status
supabase migration list --linked
```

### Project Management

```powershell
# List all projects
supabase projects list

# Link to project
supabase link --project-ref okjuhvgavbcbbnzvvyxc

# Unlink from project
supabase unlink

# Get project status
supabase status
```

### Storage Operations

```powershell
# List storage buckets
supabase storage list --linked

# Create storage bucket
supabase storage create <bucket-name> --linked

# Upload file to storage
supabase storage upload <bucket-name> <file-path> --linked
```

## Troubleshooting

### Connection Issues

If you encounter connection issues:

1. **Check network connectivity:**
   ```powershell
   Test-NetConnection api.supabase.com -Port 443
   ```

2. **Try using direct connection:**
   ```powershell
   supabase link --project-ref okjuhvgavbcbbnzvvyxc --skip-pooler
   ```

3. **Check DNS resolver:**
   ```powershell
   supabase --dns-resolver https link --project-ref okjuhvgavbcbbnzvvyxc
   ```

### Authentication Issues

1. **Re-login:**
   ```powershell
   supabase logout
   supabase login
   ```

2. **Check authentication status:**
   ```powershell
   supabase projects list
   ```

### Migration Issues

1. **Check migration status:**
   ```powershell
   supabase migration list --linked
   ```

2. **Dry run migration:**
   ```powershell
   supabase db push --linked --dry-run
   ```

3. **Check for conflicts:**
   ```powershell
   supabase db diff --linked
   ```

## Project Structure

```
.
├── supabase/
│   ├── config.toml          # Supabase configuration
│   ├── migrations/          # Database migrations
│   │   └── YYYYMMDDHHMMSS_description.sql
│   └── seed.sql             # Seed data (optional)
├── supabase_migrations/     # Migration files (source)
└── scripts/
    └── run_admin_setup.ps1  # Setup script
```

## Next Steps

After setting up the admin user:

1. **Verify admin user:**
   ```sql
   SELECT id, name, email, role 
   FROM profiles 
   WHERE id = '82fd273a-ba63-4577-84f9-16dce9c06d3d'::uuid;
   ```

2. **Verify storage bucket:**
   ```sql
   SELECT id, name, public 
   FROM storage.buckets 
   WHERE id = 'product-images';
   ```

3. **Verify storage policies:**
   ```sql
   SELECT policyname, cmd 
   FROM pg_policies 
   WHERE schemaname = 'storage' 
   AND tablename = 'objects' 
   AND policyname LIKE '%product images%';
   ```

## Resources

- [Supabase CLI Documentation](https://supabase.com/docs/guides/cli)
- [Supabase Migrations Guide](https://supabase.com/docs/guides/cli/local-development#database-migrations)
- [Supabase Storage Guide](https://supabase.com/docs/guides/storage)










