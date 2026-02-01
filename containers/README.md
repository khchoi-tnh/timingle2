# timingle Containers

Podman Compose를 사용한 개발 환경 컨테이너 설정

## 📁 파일 구조

```
containers/
├── podman-compose.yml      # Linux/macOS용 (브릿지 네트워크)
├── podman-compose-wsl.yml  # Windows WSL용 (호스트 네트워크)
├── setup_podman.sh         # WSL 자동 설정 스크립트
├── postgres/
│   └── init.sql            # PostgreSQL 초기화
├── scylla/
│   └── scylla.yaml         # ScyllaDB 설정 (사용 안함)
├── redis/
└── nats/
```

## 🚀 빠른 시작

### Linux / macOS
```bash
cd containers
podman-compose up -d
```

### Windows (WSL) - 권장
```bash
# WSL 접속
wsl -d AlmaLinux-Kitten-10

# 자동 설정 스크립트 (권장)
bash /mnt/d/projects/timingle2/containers/setup_podman.sh

# 또는 수동 실행
cd ~/projects/timingle2/containers
~/.local/bin/podman-compose -f podman-compose-wsl.yml up -d

# ScyllaDB keyspace 생성 (60초 후)
podman exec timingle-scylla cqlsh -e "
  CREATE KEYSPACE IF NOT EXISTS timingle
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
"
```

> **WSL 주의**: `podman-compose-wsl.yml` 사용 필수 (nftables 문제 회피)
> 자세한 내용: [troubleshooting/wsl.md](../docs/troubleshooting/wsl.md)

## 🔍 상태 확인

```bash
# 컨테이너 상태
podman ps

# 로그 확인
podman-compose logs -f
podman-compose logs -f scylla

# 서비스 중지
podman-compose down

# 데이터 포함 완전 삭제
podman-compose down -v
```

## 📊 서비스 목록

### PostgreSQL
- **포트**: 5432
- **사용자**: timingle
- **비밀번호**: timingle_dev_password
- **데이터베이스**: timingle
- **볼륨**: postgres_data

**접속**:
```bash
podman exec -it timingle-postgres psql -U timingle -d timingle
```

### Redis
- **포트**: 6379
- **볼륨**: redis_data

**접속**:
```bash
podman exec -it timingle-redis redis-cli
```

### NATS
- **클라이언트 포트**: 4222
- **관리 포트**: 8222
- **클러스터 포트**: 6222
- **볼륨**: nats_data

**상태 확인**:
```bash
curl http://localhost:8222/varz
```

### ScyllaDB
- **CQL 포트**: 9042
- **REST API 포트**: 10000
- **볼륨**: scylla_data

**접속**:
```bash
# CQL 셸
podman exec -it timingle-scylla cqlsh

# 노드 상태
podman exec -it timingle-scylla nodetool status
```

## 🔧 트러블슈팅

### ScyllaDB가 시작되지 않음
ScyllaDB는 초기 부팅 시 1-2분이 소요됩니다. 로그를 확인하세요:
```bash
podman-compose logs -f scylla
```

### 포트 충돌
다른 서비스가 포트를 사용 중인지 확인:
```bash
# Linux/macOS
lsof -i :5432
lsof -i :6379
lsof -i :4222
lsof -i :9042

# Windows
netstat -ano | findstr :5432
```

### 데이터 초기화
모든 데이터를 삭제하고 다시 시작:
```bash
podman-compose down -v
podman-compose up -d
```

## 📝 설정 파일

| 파일 | 용도 |
|------|------|
| `podman-compose.yml` | Linux/macOS용 (브릿지 네트워크) |
| `podman-compose-wsl.yml` | Windows WSL용 (호스트 네트워크) |
| `setup_podman.sh` | WSL 자동 설정 스크립트 |
| `postgres/init.sql` | PostgreSQL 초기화 |

## 🔗 참고 문서

- [DEVELOPMENT.md](../docs/DEVELOPMENT.md) - 개발 환경 가이드
- [DATABASE.md](../docs/DATABASE.md) - 데이터베이스 스키마
- [troubleshooting/wsl.md](../docs/troubleshooting/wsl.md) - WSL 문제 해결
- [troubleshooting/scylladb.md](../docs/troubleshooting/scylladb.md) - ScyllaDB 문제 해결
- [troubleshooting/podman.md](../docs/troubleshooting/podman.md) - Podman 문제 해결
