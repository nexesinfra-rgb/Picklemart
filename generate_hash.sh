# Get the Anon Key from the running container
ANON_KEY=$(docker exec $(docker ps -q --filter name=supabase-auth | head -n 1) printenv SUPABASE_ANON_KEY)
DB_PASS=$(docker exec $(docker ps -q --filter name=supabase-auth | head -n 1) printenv SUPABASE_DB_PASSWORD)

echo "Anon Key: $ANON_KEY"

# Try to signup a temp user to generate a valid hash
curl -X POST 'http://localhost:9999/signup' \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "temp_fix_admin@sm.com",
    "password": "admin123"
  }'

echo "Signup request sent."
