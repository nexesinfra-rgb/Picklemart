-- Grant BYPASSRLS to supabase_auth_admin to allow it to manage auth tables even if RLS is on
ALTER ROLE supabase_auth_admin WITH BYPASSRLS;

-- Change owner of auth.users to supabase_auth_admin (standard practice)
ALTER TABLE auth.users OWNER TO supabase_auth_admin;

-- Also checking other key tables
ALTER TABLE auth.sessions OWNER TO supabase_auth_admin;
ALTER TABLE auth.refresh_tokens OWNER TO supabase_auth_admin;
ALTER TABLE auth.identities OWNER TO supabase_auth_admin;

-- Verify fix
SELECT rolname, rolbypassrls FROM pg_roles WHERE rolname = 'supabase_auth_admin';
