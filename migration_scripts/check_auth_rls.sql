SELECT relname 
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'auth' 
  AND c.relkind = 'r' 
  AND c.relrowsecurity = true;
