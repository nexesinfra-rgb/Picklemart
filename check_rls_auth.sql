SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth')
AND relname = 'users';

SELECT * FROM pg_policies WHERE schemaname = 'auth' AND tablename = 'users';
