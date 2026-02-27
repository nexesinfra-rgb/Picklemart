-- Fix permissions for supabase_auth_admin on auth schema
BEGIN;

-- 1. Grant usage on schema
GRANT USAGE ON SCHEMA auth TO supabase_auth_admin;

-- 2. Grant all privileges on existing tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO supabase_auth_admin;

-- 3. Grant all privileges on existing sequences
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO supabase_auth_admin;

-- 4. Ensure future tables/sequences are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON TABLES TO supabase_auth_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON SEQUENCES TO supabase_auth_admin;

-- 5. Fix ownership of schema_migrations specifically
ALTER TABLE auth.schema_migrations OWNER TO supabase_auth_admin;

COMMIT;
