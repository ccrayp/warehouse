#!/bin/bash

echo "Запуск Docker Compose..."
docker-compose up --build -d

echo "Контейнеры запущены!"
docker ps

if [ -n "$1" ]; then
    echo "Инициализация базы данных из файла $1 ..."
    docker exec -i storage_db-warehouse_db-1 psql -U postgres -d warehouse < "$1"
fi