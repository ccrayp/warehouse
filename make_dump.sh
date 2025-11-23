#!/bin/bash

REMOVE_VOLUME=false

if [ -n "$1" ]; then
    DUMP_FILE="$1"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    DUMP_FILE_WITH_TIME="${DUMP_FILE}_${TIMESTAMP}.sql"

    # Создаём дамп ролей и пишем в файл
    echo "Создаём дамп ролей в файл $DUMP_FILE_WITH_TIME ..."
    docker exec -i storage_db-warehouse_db-1 pg_dumpall -U postgres --globals-only > "$DUMP_FILE_WITH_TIME"

    if [ $? -eq 0 ]; then
        echo "Дамп ролей успешно создан."
    else
        echo "Ошибка при создании дампа ролей. Volume не будет удалён."
        REMOVE_VOLUME=false
        echo "Остановка Docker Compose..."
        docker-compose down
        exit 1
    fi

    # Создаём дамп базы и добавляем в тот же файл
    echo "Создаём дамп базы и добавляем в файл $DUMP_FILE_WITH_TIME ..."
    docker exec -i storage_db-warehouse_db-1 pg_dump -F p -U postgres -d warehouse >> "$DUMP_FILE_WITH_TIME"

    if [ $? -eq 0 ]; then
        echo "Дамп базы успешно добавлен в файл: $DUMP_FILE_WITH_TIME"
        REMOVE_VOLUME=true
    else
        echo "Ошибка при создании дампа базы. Volume не будет удалён."
        REMOVE_VOLUME=false
    fi
else
    echo "Дамп базы не создаётся, путь к файлу не указан."
fi