SELECT rolname, rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user;
SELECT rolname, rolsuper FROM pg_roles WHERE rolname = 'supabase_admin';
