#!/bin/bash

echo "Запуск Docker Compose..."
docker-compose up --build -d

echo "Контейнеры запущены!"
docker ps

if [ -n "$1" ]; then
    DUMP_FILE="$1"

    CONTAINER="storage_db-warehouse_db-1"

    echo "Ожидание запуска PostgreSQL..."
    until docker exec "$CONTAINER" pg_isready -U postgres > /dev/null 2>&1; do
        sleep 1
    done

    echo "PostgreSQL готов!"
    echo "Инициализация базы данных из файла $DUMP_FILE ..."

    docker exec -i "$CONTAINER" psql -U postgres -d warehouse < "$DUMP_FILE"

    echo "Импорт завершён!"
fi

docker-compose logs -f > logs/warehouse.log 2>&1 &