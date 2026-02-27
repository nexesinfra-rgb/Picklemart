#!/bin/bash
CONTAINER_ID=$(docker ps -q --filter name=supabase-auth | head -n 1)
docker logs $CONTAINER_ID 2>&1 | grep -C 5 "49542e44"
