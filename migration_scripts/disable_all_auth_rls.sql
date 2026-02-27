DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT quote_ident(tablename) as tname
        FROM pg_tables
        WHERE schemaname = 'auth'
    ) LOOP
        EXECUTE format('ALTER TABLE auth.%I DISABLE ROW LEVEL SECURITY;', r.tname);
        RAISE NOTICE 'Disabled RLS on auth.%', r.tname;
    END LOOP;
END $$;
