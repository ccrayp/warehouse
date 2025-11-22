#!/bin/bash
if [ -n "$1" ]; then
    BASE_NAME="$1"
else
    BASE_NAME="dump"
fi

# Добавляем временную метку
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DUMP_FILE="${BASE_NAME}_${TIMESTAMP}.sql"

echo "Создаём дамп базы в файл $DUMP_FILE ..."

docker exec -i storage_db-warehouse_db-1 pg_dump -F p -U postgres -d warehouse > "$DUMP_FILE"

if [ $? -eq 0 ]; then
    echo "Дамп базы успешно создан: $DUMP_FILE"
else
    echo "Ошибка при создании дампа базы!"
    exit 1
fi