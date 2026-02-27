-- Grant full access to supabase_auth_admin on auth.users
-- This is necessary because the role lacks BYPASSRLS and we cannot alter it due to restrictions.

DO $$
BEGIN
    -- Drop policy if it exists to avoid errors
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'auth' 
        AND tablename = 'users' 
        AND policyname = 'Auth admin full access'
    ) THEN
        DROP POLICY "Auth admin full access" ON auth.users;
    END IF;
END $$;

-- Create the policy
CREATE POLICY "Auth admin full access" ON auth.users
    FOR ALL
    TO supabase_auth_admin
    USING (true)
    WITH CHECK (true);

-- Verify policy creation
SELECT * FROM pg_policies WHERE schemaname = 'auth' AND tablename = 'users';
