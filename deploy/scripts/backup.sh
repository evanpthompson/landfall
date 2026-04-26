#!/bin/sh
# Postgres backup script — runs inside the backup container via cron at 2 AM daily.
# Keeps the last 7 daily dumps; older files are pruned automatically.
#
# Env vars expected: PGHOST, PGUSER, PGPASSWORD, PGDATABASE (set by docker-compose.prod.yml)

set -e

BACKUP_DIR="/backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
FILE="${BACKUP_DIR}/landfall_${TIMESTAMP}.sql.gz"

mkdir -p "${BACKUP_DIR}"

pg_dump --no-password | gzip > "${FILE}"
echo "Backup written: ${FILE}"

# Prune to 7 most recent files
ls -t "${BACKUP_DIR}"/landfall_*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm --
echo "Old backups pruned"
