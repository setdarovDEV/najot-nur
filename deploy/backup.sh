#!/usr/bin/env bash
# NotiqAI — back up Postgres database and critical files.
# Run via cron: 0 3 * * * /opt/notiqai/deploy/backup.sh
set -euo pipefail

cd "$(dirname "$0")/.."

BACKUP_DIR=/var/backups/notiqai
mkdir -p "$BACKUP_DIR"
TS=$(date -u +%Y%m%dT%H%M%SZ)

# 1) Postgres dump
docker exec notiq_postgres pg_dump -U "${POSTGRES_USER:-notiq}" -d "${POSTGRES_DB:-notiqai}" \
    | gzip > "$BACKUP_DIR/db-$TS.sql.gz"

# 2) .env (encrypted with age or just chmod 600)
cp .env "$BACKUP_DIR/env-$TS"
chmod 600 "$BACKUP_DIR/env-$TS"

# 3) Media folder tarball (small for now)
docker run --rm \
    -v notiqai_media:/data:ro \
    -v "$BACKUP_DIR":/backup \
    alpine:3.20 tar -czf "/backup/media-$TS.tar.gz" -C /data .

# 4) Retain only last 14 days
find "$BACKUP_DIR" -type f -mtime +14 -delete

echo "✓ Backup complete: $BACKUP_DIR"
ls -lh "$BACKUP_DIR" | tail -5
