#!/bin/bash
docker exec -i supabase-db-ogw8kswcww8swko0c8gswsks psql -U postgres -c "SELECT id, email, email_confirmed_at, raw_app_meta_data FROM auth.users WHERE email = 'admin@sm.com';"
