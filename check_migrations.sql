SELECT table_schema, table_name FROM information_schema.tables WHERE table_name = 'schema_migrations';
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'schema_migrations';
SELECT * FROM auth.schema_migrations;