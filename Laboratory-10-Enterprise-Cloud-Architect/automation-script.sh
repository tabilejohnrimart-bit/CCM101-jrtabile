#!/usr/bin/env bash
set -Eeuo pipefail

# Mission 10: WordPress and MariaDB backup script

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_DIR/backups"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"

mkdir -p "$BACKUP_DIR"
cd "$PROJECT_DIR"

echo "Starting backup: $TIMESTAMP"

# Confirm both containers are running
docker compose exec -T mariadb true
docker compose exec -T wordpress true

# Back up the MariaDB database
docker compose exec -T mariadb sh -c \
  'mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"' \
  > "$BACKUP_DIR/database_${TIMESTAMP}.sql"

# Back up WordPress files
docker compose exec -T wordpress \
  tar -czf - -C /var/www/html . \
  > "$BACKUP_DIR/wordpress_${TIMESTAMP}.tar.gz"

# Verify that both backup files are non-empty
test -s "$BACKUP_DIR/database_${TIMESTAMP}.sql"
test -s "$BACKUP_DIR/wordpress_${TIMESTAMP}.tar.gz"

echo "Backup completed successfully."
echo "Files saved in: $BACKUP_DIR"
