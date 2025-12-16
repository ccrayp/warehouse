#!/bin/bash

echo "Запуск Docker Compose..."
docker-compose up --build -d

echo "Контейнеры запущены!"
docker ps

if [ -n "$1" ]; then
    DUMP_FILE="$1"

    CONTAINER="warehouse-warehouse_db-1"

    echo "Ожидание запуска PostgreSQL..."
    until docker exec "$CONTAINER" pg_isready -U postgres > /dev/null 2>&1; do
        sleep 1
    done

    echo "PostgreSQL готов!"
    echo "Инициализация базы данных из файла $DUMP_FILE ..."

    docker exec -i "$CONTAINER" psql -U postgres -d warehouse < "$DUMP_FILE"

    echo "Импорт завершён!"
fi

docker-compose logs -f nginx > logs/nginx.log 2>&1 &
docker-compose logs -f pgadmin > logs/pgadmin4.log 2>&1 &
docker-compose logs -f warehouse_db > logs/postgresql.log 2>&1 &
docker-compose logs -f server > logs/backend.log 2>&1 &
docker-compose logs -f frontend > logs/fontend.log 2>&1 &