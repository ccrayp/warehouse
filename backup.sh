#!/bin/bash
set -e

PROJECT_NAME="warehouse"
DB_CONTAINER="warehouse_db"
DB_NAME="warehouse"
DB_USER="postgres"

IMAGES_VOLUME="product_images"

WORKDIR="warehouse_backup"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE="warehouse_backup_${TIMESTAMP}.tar.gz"

SCRIPTS=(
  start.sh
  stop.sh
  make_dump.sh
  debug.sh
)

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

docker compose exec -T "$DB_CONTAINER" \
  pg_dumpall -U "$DB_USER" --globals-only \
  > "$WORKDIR/roles.sql"

docker compose exec -T "$DB_CONTAINER" \
  pg_dump -U "$DB_USER" "$DB_NAME" \
  > "$WORKDIR/db_dump.sql"

docker run --rm \
  -v ${PROJECT_NAME}_${IMAGES_VOLUME}:/data \
  -v "$(pwd)/$WORKDIR":/backup \
  alpine \
  tar czf /backup/product_images.tar.gz -C /data .

cp docker-compose.yml "$WORKDIR/"

rsync -a \
  --exclude node_modules \
  --exclude dist \
  --exclude build \
  --exclude .git \
  backend frontend nginx \
  "$WORKDIR/"

for script in "${SCRIPTS[@]}"; do
  [ -f "$script" ] && cp "$script" "$WORKDIR/"
done

cat << 'EOF' > "$WORKDIR/restore.sh"
#!/bin/bash
set -e

docker compose up -d warehouse_db
sleep 10

if [ -f roles.sql ]; then
  docker compose exec -T warehouse_db \
    psql -U postgres < roles.sql
fi

docker compose exec -T warehouse_db \
  psql -U postgres -d warehouse < db_dump.sql

docker run --rm \
  -v warehouse_product_images:/data \
  -v $(pwd):/backup \
  alpine \
  tar xzf /backup/product_images.tar.gz -C /data

docker compose up -d

EOF

chmod +x "$WORKDIR/restore.sh"

tar czf "$ARCHIVE" "$WORKDIR"
rm -rf "$WORKDIR"