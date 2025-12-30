# Phase 0: 환경 설정

> **목표**: 개발에 필요한 모든 환경을 로컬에 구축합니다.

**예상 소요 시간**: 1-2일
**난이도**: ⭐⭐ (쉬움)

---

## 📋 체크리스트

### 사전 준비
- [ ] Podman 설치 확인 (`podman --version`)
- [ ] podman-compose 설치 확인 (`podman-compose --version`)
- [ ] Go 1.22+ 설치 확인 (`go version`)
- [ ] Flutter 3.0+ 설치 확인 (`flutter --version`)
- [ ] Git 설치 확인 (`git --version`)

### Phase 0 목표
- [ ] Podman Compose로 모든 인프라 실행 중 (PostgreSQL, Redis, NATS, ScyllaDB)
- [ ] Backend 프로젝트 구조 생성
- [ ] Frontend 프로젝트 생성
- [ ] 기본 설정 파일 완료
- [ ] .gitignore 설정

---

## 🚀 단계별 실행

### Step 1: 프로젝트 디렉토리 구조 생성 (5분)

```bash
# 프로젝트 루트로 이동
cd /home/khchoi/projects/timingle2

# Backend 디렉토리 구조 생성
mkdir -p backend/{cmd/{api,gateway,worker},internal/{config,db,models,repositories,services,handlers,middleware,websocket},migrations,pkg/utils}

# Frontend 디렉토리 생성 (나중에 Flutter CLI로 생성)
# mkdir frontend (Flutter CLI가 생성)

# Podman containers 디렉토리
mkdir -p containers/{postgres,redis,nats,scylla}

# 문서 디렉토리 (이미 생성됨)
mkdir -p docs/phases
```

**확인**:
```bash
tree -L 3 backend
```

### Step 2: Podman Compose 설정 (10분)

**파일 생성**: `containers/podman-compose.yml`

```yaml
version: '3.8'

services:
  # PostgreSQL - 주요 데이터
  postgres:
    image: docker.io/postgres:15-alpine
    container_name: timingle-postgres
    environment:
      POSTGRES_USER: timingle
      POSTGRES_PASSWORD: timingle_dev_password
      POSTGRES_DB: timingle
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data:Z
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql:Z
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U timingle"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis - 캐시 및 세션
  redis:
    image: docker.io/redis:7-alpine
    container_name: timingle-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data:Z
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # NATS - 메시지 큐
  nats:
    image: docker.io/nats:2.10-alpine
    container_name: timingle-nats
    ports:
      - "4222:4222"  # Client
      - "8222:8222"  # HTTP Management
      - "6222:6222"  # Cluster
    command: >
      -js
      -sd /data
      -m 8222
    volumes:
      - nats_data:/data:Z
    healthcheck:
      test: ["CMD", "wget", "-q", "-O-", "http://localhost:8222/healthz"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ScyllaDB - 채팅 메시지 및 히스토리 (필수, Discord 수준)
  scylla:
    image: docker.io/scylladb/scylla:5.4
    container_name: timingle-scylla
    ports:
      - "9042:9042"  # CQL
      - "9160:9160"  # Thrift (legacy)
      - "10000:10000"  # REST API
    volumes:
      - scylla_data:/var/lib/scylla:Z
      - ./scylla/scylla.yaml:/etc/scylla/scylla.yaml:Z
    command: --smp 2 --memory 2G --overprovisioned 1 --api-address 0.0.0.0
    healthcheck:
      test: ["CMD", "cqlsh", "-e", "DESCRIBE KEYSPACES"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

volumes:
  postgres_data:
  redis_data:
  nats_data:
  scylla_data:

networks:
  default:
    name: timingle-network
```

**PostgreSQL 초기화 스크립트**: `containers/postgres/init.sql`

```sql
-- 초기 데이터베이스 설정
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 타임존 설정
SET timezone = 'Asia/Seoul';

-- 기본 사용자 확인 (이미 생성됨)
-- timingle / timingle_dev_password
```

**ScyllaDB 설정 파일**: `containers/scylla/scylla.yaml`
```yaml
cluster_name: 'timingle-cluster'
listen_address: 0.0.0.0
rpc_address: 0.0.0.0
broadcast_rpc_address: localhost
endpoint_snitch: SimpleSnitch
```

**Podman Compose 실행**:
```bash
cd containers
podman-compose up -d

# 상태 확인
podman-compose ps

# 로그 확인
podman-compose logs -f
```

**확인**:
```bash
# PostgreSQL 연결 테스트
podman exec -it timingle-postgres psql -U timingle -d timingle -c "SELECT version();"

# Redis 연결 테스트
podman exec -it timingle-redis redis-cli ping

# NATS 상태 확인
curl http://localhost:8222/healthz

# ScyllaDB 연결 테스트 (초기 부팅 시 1-2분 소요)
podman exec -it timingle-scylla nodetool status
podman exec -it timingle-scylla cqlsh -e "DESCRIBE KEYSPACES;"
```

### Step 3: Backend 프로젝트 초기화 (15분)

#### 3.1 Go 모듈 초기화

```bash
cd ../backend
go mod init github.com/yourusername/timingle/backend

# 기본 의존성 추가
go get github.com/gin-gonic/gin
go get github.com/lib/pq
go get github.com/golang-jwt/jwt/v5
go get github.com/redis/go-redis/v9
go get github.com/nats-io/nats.go
go get github.com/gorilla/websocket
go get github.com/joho/godotenv
```

#### 3.2 기본 파일 생성

**`backend/cmd/api/main.go`**:
```go
package main

import (
	"log"
	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
			"service": "timingle-api",
		})
	})

	log.Println("API Server starting on :8080")
	r.Run(":8080")
}
```

**`backend/.env.example`**:
```env
# Server
PORT=8080
ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=timingle
DB_PASSWORD=timingle_dev_password
DB_NAME=timingle
DB_SSL_MODE=disable

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# NATS
NATS_URL=nats://localhost:4222

# JWT
JWT_SECRET=your-super-secret-key-change-in-production
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d

# Google OAuth (나중에 설정)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URL=http://localhost:8080/auth/google/callback
```

**`.env` 파일 복사**:
```bash
cp .env.example .env
# .env 파일에서 필요한 값 수정
```

**서버 실행 테스트**:
```bash
go run cmd/api/main.go

# 다른 터미널에서 테스트
curl http://localhost:8080/health
```

### Step 4: Flutter 프로젝트 생성 (10분)

```bash
cd /home/khchoi/projects/timingle2

# Flutter 프로젝트 생성
flutter create --org com.timingle --platforms android,ios frontend

cd frontend

# Clean Architecture 디렉토리 구조 생성
mkdir -p lib/{core/{constants,error,network,usecases,di},features/{auth,timingle,timeline,open_timingle,friends,settings}/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc,pages,widgets}}}

# assets 디렉토리
mkdir -p assets/{images,fonts}
```

**`frontend/pubspec.yaml` 업데이트**:
```yaml
name: frontend
description: timingle mobile app
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management & DI
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

  # Network
  dio: ^5.3.3
  retrofit: ^4.0.3
  pretty_dio_logger: ^1.3.1

  # WebSocket
  web_socket_channel: ^2.4.0

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Utilities
  dartz: ^0.10.1
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  equatable: ^2.0.5

  # UI
  go_router: ^12.1.1
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

  build_runner: ^2.4.6
  freezed: ^2.4.5
  json_serializable: ^6.7.1
  retrofit_generator: ^8.0.3
  hive_generator: ^2.0.1
  riverpod_generator: ^2.3.9
  riverpod_lint: ^2.3.7

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/fonts/
```

**의존성 설치**:
```bash
flutter pub get
```

**Flutter 앱 실행 테스트**:
```bash
flutter run
```

### Step 5: .gitignore 설정 (5분)

**프로젝트 루트 `.gitignore`**:
```gitignore
# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.swp
*.swo

# Environment
.env
*.env
!.env.example

# Backend (Go)
backend/bin/
backend/vendor/
backend/*.exe
backend/*.dll
backend/*.so
backend/*.dylib
backend/*.test
backend/*.out

# Frontend (Flutter)
frontend/.dart_tool/
frontend/.flutter-plugins
frontend/.flutter-plugins-dependencies
frontend/.packages
frontend/.pub-cache/
frontend/.pub/
frontend/build/
frontend/ios/Flutter/.last_build_id
frontend/.metadata

# Docker
docker/postgres/data/
docker/redis/data/
docker/nats/data/
docker/scylla/data/

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp
.cache/
```

### Step 6: 디렉토리 구조 최종 확인 (2분)

```bash
cd /home/khchoi/projects/timingle2
tree -L 2 -I 'node_modules|vendor|.dart_tool|build'
```

**예상 출력**:
```
timingle2/
├── CLAUDE.md
├── README.md
├── backend/
│   ├── cmd/
│   ├── internal/
│   ├── migrations/
│   ├── pkg/
│   ├── go.mod
│   ├── go.sum
│   └── .env
├── docker/
│   ├── docker-compose.yml
│   └── postgres/
├── docs/
│   ├── PHASES.md
│   ├── images/
│   └── phases/
├── frontend/
│   ├── lib/
│   ├── assets/
│   └── pubspec.yaml
└── .gitignore
```

---

## ✅ Phase 0 완료 확인

### 인프라 확인
```bash
# 모든 서비스 실행 중인지 확인
docker-compose ps

# 예상 출력:
# NAME                  STATUS    PORTS
# timingle-postgres     Up        0.0.0.0:5432->5432/tcp
# timingle-redis        Up        0.0.0.0:6379->6379/tcp
# timingle-nats         Up        0.0.0.0:4222->4222/tcp
```

### Backend 확인
```bash
cd backend
go run cmd/api/main.go
# 다른 터미널: curl http://localhost:8080/health
```

### Frontend 확인
```bash
cd frontend
flutter pub get
flutter run
```

### 체크리스트
- [ ] Docker Compose 모든 서비스 `Up` 상태
- [ ] PostgreSQL 연결 성공
- [ ] Redis PING 성공
- [ ] NATS healthz 200 OK
- [ ] Backend API `/health` 200 OK
- [ ] Flutter 앱 실행 성공
- [ ] `.gitignore` 설정 완료
- [ ] `.env` 파일 생성 (`.env.example` 기반)

---

## 🔧 Troubleshooting

### 문제 1: Docker Compose 서비스가 시작되지 않음
```bash
# 포트 충돌 확인
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis
lsof -i :4222  # NATS

# 포트 사용 중이면 프로세스 종료 또는 docker-compose.yml 포트 변경

# 로그 확인
docker-compose logs [service-name]
```

### 문제 2: Go 모듈 다운로드 실패
```bash
# 프록시 설정
export GOPROXY=https://proxy.golang.org,direct

# 모듈 정리 및 재다운로드
go clean -modcache
go mod tidy
go mod download
```

### 문제 3: Flutter pub get 실패
```bash
# 캐시 정리
flutter clean
flutter pub cache repair

# 재시도
flutter pub get
```

### 문제 4: Permission denied (Docker)
```bash
# Docker 그룹에 사용자 추가
sudo usermod -aG docker $USER

# 로그아웃 후 재로그인
# 또는
newgrp docker
```

---

## 📚 다음 단계

Phase 0 완료 후:
1. [Phase 1: 백엔드 핵심](PHASE_1_BACKEND_CORE.md) 진행
2. 또는 [Phase 3: Flutter 앱](PHASE_3_FLUTTER.md)을 Mock 서버로 병렬 진행

---

## 📝 참고 자료

- [Docker Compose 문서](https://docs.docker.com/compose/)
- [Go Modules](https://go.dev/blog/using-go-modules)
- [Flutter 설치](https://docs.flutter.dev/get-started/install)
- [PostgreSQL](https://www.postgresql.org/docs/)
- [Redis](https://redis.io/docs/)
- [NATS](https://docs.nats.io/)

---

**Phase 0 완료!** 🎉

**다음: [Phase 1 - 백엔드 핵심 →](PHASE_1_BACKEND_CORE.md)**
