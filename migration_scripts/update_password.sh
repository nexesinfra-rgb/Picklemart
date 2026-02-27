#!/bin/bash
docker exec -i supabase-db-ogw8kswcww8swko0c8gswsks psql -U postgres -c "UPDATE auth.users SET encrypted_password = '\$2b\$12\$HETfOQpZaFivxzxF/oPyTONCXqnKIxbLwIts1O8UnHh9pTDIQSIsa', email_confirmed_at = COALESCE(email_confirmed_at, NOW()), confirmation_token = NULL, updated_at = NOW() WHERE email = 'admin@sm.com';"
docker exec -i supabase-db-ogw8kswcww8swko0c8gswsks psql -U postgres -c "SELECT email, encrypted_password FROM auth.users WHERE email = 'admin@sm.com';"
