-- Grant BYPASSRLS to the auth admin role so it can manage the auth schema without RLS blocking it
ALTER ROLE supabase_auth_admin WITH BYPASSRLS;

-- Ensure it has usage on the schema
GRANT USAGE ON SCHEMA auth TO supabase_auth_admin;

-- Ensure it has all privileges on all tables in auth schema
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO supabase_auth_admin;

-- Check the result
SELECT rolname, rolsuper, rolbypassrls 
FROM pg_roles 
WHERE rolname = 'supabase_auth_admin';
