#!/bin/bash

REMOVE_VOLUME=false

if [ -n "$1" ]; then
    DUMP_FILE="$1"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    DUMP_FILE_WITH_TIME="${DUMP_FILE}_${TIMESTAMP}.sql"

    echo "Создаём дамп базы в файл $DUMP_FILE_WITH_TIME ..."
    docker exec -i storage_db-warehouse_db-1 pg_dump -F p -U postgres -d warehouse > "$DUMP_FILE_WITH_TIME"

    if [ $? -eq 0 ]; then
        echo "Дамп базы успешно создан."
        REMOVE_VOLUME=true
    else
        echo "Ошибка при создании дампа. Volume не будет удалён."
    fi
else
    echo "Дамп базы не создаётся, путь к файлу не указан."
fi

echo "Остановка Docker Compose..."
docker-compose down
echo "Контейнеры остановлены!"

if [ "$REMOVE_VOLUME" = true ]; then
    echo "Удаляем Docker volume storage_db_warehouse_db_data ..."
    docker volume rm storage_db_warehouse_db_data
    echo "Volume удалён."
fi