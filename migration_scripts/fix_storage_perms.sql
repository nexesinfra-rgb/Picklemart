
GRANT USAGE ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON TABLES TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON SEQUENCES TO supabase_storage_admin;
GRANT CREATE ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL PRIVILEGES ON TABLE storage.migrations TO supabase_storage_admin;
ALTER SCHEMA storage OWNER TO supabase_storage_admin;
ALTER TABLE storage.migrations OWNER TO supabase_storage_admin;
