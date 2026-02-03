#!/bin/bash

# timingle Backend Migrations 실행 스크립트
# 모든 SQL 마이그레이션을 순서대로 실행합니다.

set -e  # 에러 발생 시 스크립트 중단

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$BACKEND_DIR/.env"

echo "======================================"
echo "  timingle Backend Migrations"
echo "======================================"
echo ""

# .env 파일 확인 및 로드
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found at $ENV_FILE"
    echo "   Please create it from .env.example"
    exit 1
fi

echo "📄 Loading environment from: $ENV_FILE"

# .env 파일에서 환경 변수 읽기
set -a  # 자동으로 모든 변수 export
source "$ENV_FILE"
set +a  # export 자동화 해제

# 환경 변수 설정 (기본값 포함)
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_USER="${POSTGRES_USER:-timingle}"
DB_PASSWORD="${POSTGRES_PASSWORD:-timingle_dev_password}"
DB_NAME="${POSTGRES_DB:-timingle}"
CONTAINER_NAME="timingle-postgres"

echo "   🔹 Host: $DB_HOST:$DB_PORT"
echo "   🔹 User: $DB_USER"
echo "   🔹 Database: $DB_NAME"
echo ""

# 컨테이너 실행 확인
if ! podman ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ Error: PostgreSQL container '$CONTAINER_NAME' is not running!"
    echo "   Please start the container first:"
    echo "   cd /mnt/d/projects/timingle2/containers && podman-compose up -d"
    exit 1
fi

# 마이그레이션 파일 개수 확인
MIGRATION_FILES=($(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort))
TOTAL_FILES=${#MIGRATION_FILES[@]}

if [ $TOTAL_FILES -eq 0 ]; then
    echo "❌ No migration files found in $MIGRATIONS_DIR"
    exit 1
fi

echo "📁 Found $TOTAL_FILES migration files"
echo ""

# 각 마이그레이션 실행
SUCCESS_COUNT=0
FAILED_COUNT=0

for migration_file in "${MIGRATION_FILES[@]}"; do
    filename=$(basename "$migration_file")
    echo "🔄 Running: $filename"

    # PGPASSWORD 환경 변수 설정하여 비밀번호 자동 입력
    if PGPASSWORD="$DB_PASSWORD" podman exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" < "$migration_file" 2>&1 | grep -v "NOTICE"; then
        echo "   ✅ Success"
        ((SUCCESS_COUNT++))
    else
        echo "   ❌ Failed"
        ((FAILED_COUNT++))
        # 실패해도 계속 진행 (이미 적용된 마이그레이션은 에러 발생)
    fi
    echo ""
done

# 결과 요약
echo "======================================"
echo "  Migration Results"
echo "======================================"
echo "✅ Success: $SUCCESS_COUNT"
echo "❌ Failed:  $FAILED_COUNT"
echo "📊 Total:   $TOTAL_FILES"
echo ""

if [ $FAILED_COUNT -eq 0 ]; then
    echo "🎉 All migrations completed successfully!"
else
    echo "⚠️  Some migrations failed (may be already applied)"
fi
