#!/bin/bash

set -e

POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-timingle}"
POSTGRES_DB="${POSTGRES_DB:-timingle}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-timingle_dev_password}"

MIGRATION_DIR="$(dirname "$0")"

echo "🚀 Running migrations on ${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}..."

for file in $(ls -v ${MIGRATION_DIR}/*.sql 2>/dev/null); do
  echo "📄 Applying $(basename $file)..."
  PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -f "$file"
done

echo "✅ All migrations applied successfully!"
