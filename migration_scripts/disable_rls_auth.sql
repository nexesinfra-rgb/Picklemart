-- Disable RLS on auth.users to allow auth service to insert/update users
ALTER TABLE auth.users DISABLE ROW LEVEL SECURITY;

-- Also check other critical auth tables
ALTER TABLE auth.sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE auth.refresh_tokens DISABLE ROW LEVEL SECURITY;
ALTER TABLE auth.identities DISABLE ROW LEVEL SECURITY;

-- Verify
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE oid IN (
    'auth.users'::regclass, 
    'auth.sessions'::regclass, 
    'auth.refresh_tokens'::regclass,
    'auth.identities'::regclass
);
