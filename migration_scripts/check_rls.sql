-- Check RLS status on auth.users
SELECT relname, relrowsecurity, relforcerowsecurity 
FROM pg_class 
WHERE oid = 'auth.users'::regclass;

-- Check roles and privileges
SELECT rolname, rolsuper, rolbypassrls 
FROM pg_roles 
WHERE rolname = 'supabase_auth_admin';
