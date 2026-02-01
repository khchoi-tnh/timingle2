#!/bin/bash
# WSL 개발 환경 Podman 설정 및 실행 스크립트
#
# 사용법:
#   bash /mnt/d/projects/timingle2/containers/setup_podman.sh
#
# 참고: WSL에서는 nftables 문제로 network_mode: host 사용
# 자세한 내용: docs/troubleshooting/wsl.md

set -e

echo "=== timingle WSL 개발 환경 설정 ==="

# 기존 컨테이너 정리
echo "1. 기존 컨테이너 정리..."
podman rm -af 2>/dev/null || true

# WSL용 compose 파일로 컨테이너 시작
echo "2. 컨테이너 시작 (network_mode: host)..."
cd /root/projects/timingle2/containers
/root/.local/bin/podman-compose -f podman-compose-wsl.yml up -d

# 상태 확인
echo "3. 컨테이너 상태 확인..."
podman ps

# ScyllaDB 초기화 대기
echo "4. ScyllaDB 초기화 대기 (60초)..."
sleep 60

# ScyllaDB keyspace 생성
echo "5. ScyllaDB keyspace 생성..."
podman exec timingle-scylla cqlsh -e "
  CREATE KEYSPACE IF NOT EXISTS timingle
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
" 2>/dev/null || echo "   (keyspace가 이미 존재하거나 ScyllaDB가 아직 준비 중입니다)"

# 연결 테스트
echo "6. 서비스 연결 테스트..."
echo -n "   PostgreSQL: "
podman exec timingle-postgres psql -U timingle -d timingle -c "SELECT 1" > /dev/null 2>&1 && echo "OK" || echo "FAIL"
echo -n "   Redis: "
podman exec timingle-redis redis-cli ping > /dev/null 2>&1 && echo "OK" || echo "FAIL"
echo -n "   NATS: "
curl -s http://localhost:8222/healthz > /dev/null 2>&1 && echo "OK" || echo "FAIL"
echo -n "   ScyllaDB: "
podman exec timingle-scylla cqlsh -e "DESCRIBE KEYSPACES" > /dev/null 2>&1 && echo "OK" || echo "FAIL (계속 대기 필요)"

echo ""
echo "=== 설정 완료 ==="
echo ""
echo "포트 정보:"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo "  - NATS: localhost:4222 (HTTP: 8222)"
echo "  - ScyllaDB: localhost:9042"
echo ""
echo "Backend 실행: bash /mnt/d/projects/timingle2/backend/run.sh"
