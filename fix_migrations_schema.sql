ALTER TABLE auth.schema_migrations ALTER COLUMN version TYPE VARCHAR(14);
ALTER TABLE auth.schema_migrations ADD PRIMARY KEY (version);