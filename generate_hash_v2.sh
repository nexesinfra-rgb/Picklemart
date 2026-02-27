# Get the IP of the auth container
AUTH_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q --filter name=supabase-auth | head -n 1))
ANON_KEY=$(docker exec $(docker ps -q --filter name=supabase-auth | head -n 1) printenv SUPABASE_ANON_KEY)

echo "Auth IP: $AUTH_IP"
echo "Anon Key: $ANON_KEY"

# Signup temp user
# GoTrue typically listens on 9999 inside the container
curl -X POST "http://$AUTH_IP:9999/signup" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "temp_fix_admin@sm.com",
    "password": "admin123"
  }'

echo "Signup request sent."
