SELECT n.nspname as schema, c.relname as table 
FROM pg_class c 
JOIN pg_namespace n ON n.oid = c.relnamespace 
WHERE c.relkind = 'r' 
ORDER BY 1, 2;