#!/bin/bash

docker-compose up -d

docker ps

docker-compose logs -f nginx > logs/nginx.log 2>&1 &
docker-compose logs -f pgadmin > logs/pgadmin4.log 2>&1 &
docker-compose logs -f warehouse_db > logs/postgresql.log 2>&1 &
docker-compose logs -f server > logs/backend.log 2>&1 &
docker-compose logs -f frontend > logs/fontend.log 2>&1 &