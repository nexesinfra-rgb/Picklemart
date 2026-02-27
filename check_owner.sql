SELECT 
    n.nspname AS schema_name,
    c.relname AS table_name, 
    pg_catalog.pg_get_userbyid(c.relowner) AS owner_name,
    c.relrowsecurity AS rls_enabled
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'auth' AND c.relname = 'users';

SELECT rolname, rolbypassrls, rolsuper 
FROM pg_roles 
WHERE rolname = 'supabase_auth_admin';
