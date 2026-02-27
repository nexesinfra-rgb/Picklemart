SELECT 
    table_schema, 
    table_name, 
    table_type 
FROM information_schema.tables 
WHERE table_name = 'schema_migrations';

SELECT 
    table_schema, 
    table_name, 
    column_name, 
    data_type, 
    character_maximum_length 
FROM information_schema.columns 
WHERE table_name = 'schema_migrations';

-- Check ownership and permissions could be useful too, but let's start with structure.
