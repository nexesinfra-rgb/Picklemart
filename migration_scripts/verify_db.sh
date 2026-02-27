#!/bin/bash
docker exec -i supabase-db-ogw8kswcww8swko0c8gswsks psql -U postgres -c "SELECT count(*) as user_count FROM auth.users;"
docker exec -i supabase-db-ogw8kswcww8swko0c8gswsks psql -U postgres -c "SELECT count(*) as cart_items FROM public.cart_items;"
