#!/bin/bash

if [ -n "$1" ]; then
    DUMP_FILE="$1"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    DUMP_FILE_WITH_TIME="${DUMP_FILE}_${TIMESTAMP}.sql"

    echo "Creating DB dump using $DUMP_FILE_WITH_TIME ..."
    docker exec -i warehouse-warehouse_db-1 pg_dumpall -U postgres --globals-only > "$DUMP_FILE_WITH_TIME"

    if [ $? -eq 0 ]; then
        echo "Role's dump was successfully creates"
    else
        echo "Error while role's dump creating"
        docker-compose down
        exit 1
    fi

    docker exec -i warehouse-warehouse_db-1 pg_dump -F p -U postgres -d warehouse >> "$DUMP_FILE_WITH_TIME"

else
    echo "There is no file path to create dump"
fi


