# timingle 개발 환경 가이드

## 📋 목차

1. [개발 환경 요구사항](#개발-환경-요구사항)
2. [로컬 개발 환경 설정](#로컬-개발-환경-설정)
3. [백엔드 개발](#백엔드-개발)
4. [프론트엔드 개발](#프론트엔드-개발)
5. [데이터베이스 관리](#데이터베이스-관리)
6. [테스트](#테스트)
7. [디버깅](#디버깅)
8. [문제 해결](#문제-해결)

---

## 개발 환경 요구사항

### 필수 소프트웨어

#### Backend
- **Go**: 1.22 이상
- **PostgreSQL**: 15 이상
- **Redis**: 7.0 이상
- **NATS**: 2.10 이상

#### Frontend
- **Flutter**: 3.19 이상
- **Dart**: 3.0 이상
- **Android Studio** 또는 **Xcode** (모바일 개발용)

#### 공통
- **Podman**: 4.0 이상 (rootless, daemonless 컨테이너)
- **podman-compose**: 1.0 이상
- **Git**: 2.40 이상

### 권장 IDE

#### Backend
- **VS Code** + Go 확장
- **GoLand** (JetBrains)

#### Frontend
- **VS Code** + Flutter/Dart 확장
- **Android Studio** + Flutter 플러그인

### OS별 설치 가이드

#### macOS
```bash
# Homebrew 설치
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Go 설치
brew install go

# Flutter 설치
brew install --cask flutter

# Podman 설치
brew install podman podman-compose

# Podman 머신 초기화
podman machine init
podman machine start

# PostgreSQL CLI 도구
brew install postgresql@15

# Redis CLI 도구
brew install redis
```

#### Ubuntu/Debian
```bash
# Go 설치
sudo snap install go --classic

# Flutter 설치
sudo snap install flutter --classic

# Podman 설치
sudo apt update
sudo apt install -y podman podman-compose

# PostgreSQL CLI 도구
sudo apt install postgresql-client-15

# Redis CLI 도구
sudo apt install redis-tools
```

#### Windows
```powershell
# Chocolatey 설치 (관리자 권한)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Go 설치
choco install golang

# Flutter 설치
choco install flutter

# Podman 설치 (Windows용)
choco install podman podman-compose

# Git 설치
choco install git
```

---

## 로컬 개발 환경 설정

### 1. 리포지토리 클론
```bash
git clone https://github.com/yourusername/timingle2.git
cd timingle2
```

### 2. 환경 변수 설정
```bash
# .env 파일 생성
cp .env.example .env

# 에디터로 .env 파일 수정
nano .env  # 또는 code .env
```

**필수 수정 항목**:
```env
# JWT Secret (32자 이상 랜덤 문자열)
JWT_SECRET=your-super-secret-key-change-in-production-minimum-32-characters

# Google OAuth (개발용)
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret

# SMS 인증 (선택)
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=+12345678901
```

### 3. Podman Compose로 서비스 실행
```bash
# 백그라운드로 모든 서비스 시작
cd containers
podman-compose up -d

# 로그 확인
podman-compose logs -f

# 특정 서비스 로그만 보기
podman-compose logs -f postgres
podman-compose logs -f redis
podman-compose logs -f nats
podman-compose logs -f scylla
```

### 4. 서비스 상태 확인
```bash
# 모든 컨테이너 상태 확인
podman-compose ps
# 또는
podman ps

# PostgreSQL 연결 테스트
podman exec -it timingle-postgres psql -U timingle -d timingle -c "SELECT version();"

# Redis 연결 테스트
podman exec -it timingle-redis redis-cli ping

# NATS 연결 테스트
curl http://localhost:8222/varz

# ScyllaDB 연결 테스트
podman exec -it timingle-scylla cqlsh -e "DESCRIBE KEYSPACES;"
```

---

## 백엔드 개발

### 프로젝트 초기화

```bash
cd backend

# Go 모듈 초기화 (처음 한 번만)
go mod init github.com/yourusername/timingle/backend

# 의존성 설치
go get github.com/gin-gonic/gin
go get github.com/lib/pq
go get github.com/go-redis/redis/v8
go get github.com/nats-io/nats.go
go get github.com/golang-jwt/jwt/v5
go get github.com/gocql/gocql  # ScyllaDB (선택)

# 의존성 정리
go mod tidy
```

### 프로젝트 구조 생성

```bash
# 디렉토리 구조 생성
mkdir -p cmd/{api,gateway,worker}
mkdir -p internal/{config,db,models,repositories,services,handlers,middleware,websocket}
mkdir -p pkg/utils
mkdir -p migrations
```

### 데이터베이스 마이그레이션

```bash
# golang-migrate 설치
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# 마이그레이션 파일 생성
migrate create -ext sql -dir migrations -seq create_users_table

# 마이그레이션 실행
migrate -path migrations -database "postgresql://timingle:timingle_dev_password@localhost:5432/timingle?sslmode=disable" up

# 롤백 (마지막 1개)
migrate -path migrations -database "postgresql://timingle:timingle_dev_password@localhost:5432/timingle?sslmode=disable" down 1
```

### API 서버 실행

#### 개발 모드 (Hot Reload)
```bash
# air 설치 (Hot Reload 도구)
go install github.com/cosmtrek/air@latest

# .air.toml 생성
air init

# 개발 서버 시작
air
```

#### 일반 실행
```bash
# API 서버 빌드
go build -o bin/api cmd/api/main.go

# 실행
./bin/api

# 또는 직접 실행
go run cmd/api/main.go
```

### 코드 스타일 및 린트

```bash
# gofmt (코드 포맷팅)
gofmt -w .

# golangci-lint 설치
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# 린트 실행
golangci-lint run ./...

# 자동 수정
golangci-lint run --fix ./...
```

### API 테스트

```bash
# 헬스 체크
curl http://localhost:8080/health

# 회원가입 테스트
curl -X POST http://localhost:8080/api/v1/auth/phone/send \
  -H "Content-Type: application/json" \
  -d '{"phone": "+821012345678"}'

# 이벤트 목록 조회 (인증 필요)
curl http://localhost:8080/api/v1/events \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 프론트엔드 개발

### Flutter 프로젝트 초기화

```bash
# Flutter 프로젝트 생성
flutter create --org com.timingle frontend
cd frontend

# 의존성 설치 (pubspec.yaml 수정 후)
flutter pub get

# 코드 생성 (build_runner)
flutter pub run build_runner build --delete-conflicting-outputs
```

### pubspec.yaml 설정

```yaml
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

dev_dependencies:
  flutter_test:
    sdk: flutter

  build_runner: ^2.4.6
  freezed: ^2.4.5
  json_serializable: ^6.7.1
  retrofit_generator: ^8.0.3
  hive_generator: ^2.0.1
  riverpod_generator: ^2.3.9
  riverpod_lint: ^2.3.7
  flutter_lints: ^3.0.0
```

### 프로젝트 구조 생성

```bash
cd lib

# Clean Architecture 구조
mkdir -p core/{constants,error,network,usecases,di}
mkdir -p features/{auth,timingle,timeline,open_timingle,friends,settings}/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc,pages,widgets}}
```

### 앱 실행

#### Android
```bash
# 에뮬레이터 목록 확인
flutter emulators

# 에뮬레이터 실행
flutter emulators --launch Pixel_5_API_33

# 앱 실행
flutter run
```

#### iOS (macOS only)
```bash
# 시뮬레이터 실행
open -a Simulator

# 앱 실행
flutter run
```

#### Chrome (웹 개발)
```bash
flutter run -d chrome
```

### Hot Reload 및 디버그

- **Hot Reload**: `r` (터미널에서)
- **Hot Restart**: `R`
- **DevTools 열기**: `d`
- **종료**: `q`

### 코드 생성

```bash
# build_runner 실행 (모델, API 클라이언트 생성)
flutter pub run build_runner build --delete-conflicting-outputs

# watch 모드 (파일 변경 시 자동 생성)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 린트 및 포맷팅

```bash
# 코드 분석
flutter analyze

# 코드 포맷팅
dart format .

# 린트 규칙 확인
flutter pub run custom_lint
```

---

## 데이터베이스 관리

### PostgreSQL

#### CLI 접속
```bash
# Podman 컨테이너 접속
podman exec -it timingle-postgres psql -U timingle -d timingle

# 또는 로컬 psql 사용
psql -h localhost -U timingle -d timingle
```

#### 자주 사용하는 명령어
```sql
-- 테이블 목록
\dt

-- 테이블 구조 확인
\d users

-- 쿼리 실행
SELECT * FROM users LIMIT 10;

-- 인덱스 확인
\di

-- 종료
\q
```

#### 데이터 백업 및 복원
```bash
# 백업
podman exec -t timingle-postgres pg_dump -U timingle timingle > backup.sql

# 복원
podman exec -i timingle-postgres psql -U timingle -d timingle < backup.sql
```

### ScyllaDB (필수)

#### CQL 접속
```bash
podman exec -it timingle-scylla cqlsh
```

#### 자주 사용하는 명령어
```cql
-- Keyspace 선택
USE timingle;

-- 테이블 목록
DESCRIBE TABLES;

-- 테이블 구조
DESCRIBE TABLE chat_messages_by_event;

-- 쿼리 실행
SELECT * FROM chat_messages_by_event WHERE event_id = 1 LIMIT 10;

-- 종료
exit
```

### Redis

#### CLI 접속
```bash
podman exec -it timingle-redis redis-cli
```

#### 자주 사용하는 명령어
```bash
# 키 목록 (주의: production에서는 사용 금지)
KEYS *

# 특정 키 조회
GET user:1

# 해시 조회
HGETALL session:abc123

# TTL 확인
TTL user:1

# 모든 키 삭제 (개발용)
FLUSHALL

# 종료
exit
```

---

## 테스트

### Backend 테스트

#### 단위 테스트
```bash
# 모든 테스트 실행
go test ./...

# verbose 모드
go test -v ./...

# 특정 패키지
go test ./internal/services

# 커버리지
go test -cover ./...
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

#### 통합 테스트
```bash
# 태그로 구분
go test -tags=integration ./...
```

### Frontend 테스트

#### 단위 테스트
```bash
# 모든 테스트 실행
flutter test

# 특정 파일
flutter test test/features/auth/data/repositories/auth_repository_impl_test.dart

# 커버리지
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

#### 위젯 테스트
```bash
flutter test test/features/auth/presentation/pages/login_page_test.dart
```

#### 통합 테스트
```bash
# integration_test 실행
flutter test integration_test/app_test.dart
```

---

## 디버깅

### Backend 디버깅

#### VS Code 설정 (.vscode/launch.json)
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch API Server",
      "type": "go",
      "request": "launch",
      "mode": "debug",
      "program": "${workspaceFolder}/backend/cmd/api",
      "env": {
        "ENV": "development"
      },
      "args": []
    }
  ]
}
```

#### 로그 레벨 조정
```bash
# .env 파일
LOG_LEVEL=debug  # debug, info, warn, error
```

### Frontend 디버깅

#### VS Code 설정 (.vscode/launch.json)
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Development)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": ["--dart-define", "ENV=development"]
    },
    {
      "name": "Flutter (Chrome)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "deviceId": "chrome"
    }
  ]
}
```

#### DevTools 사용
```bash
# DevTools 열기
flutter pub global activate devtools
flutter pub global run devtools

# 앱 실행 중 DevTools 연결
flutter run --observatory-port=9200
```

---

## 문제 해결

### Backend 문제

#### PostgreSQL 연결 실패
```bash
# 컨테이너 상태 확인
podman-compose ps

# 로그 확인
podman-compose logs postgres

# 재시작
podman-compose restart postgres

# 포트 충돌 확인
lsof -i :5432  # macOS/Linux
netstat -ano | findstr :5432  # Windows
```

#### NATS 연결 실패
```bash
# NATS 상태 확인
curl http://localhost:8222/varz

# 재시작
podman-compose restart nats
```

#### ScyllaDB 연결 실패
```bash
# ScyllaDB 상태 확인
podman exec timingle-scylla nodetool status

# 로그 확인
podman-compose logs scylla

# 재시작
podman-compose restart scylla
```

#### "Port already in use" 에러
```bash
# 포트 사용 중인 프로세스 찾기
lsof -i :8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows

# 프로세스 종료
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

### Frontend 문제

#### "Waiting for another flutter command to release the startup lock"
```bash
# Lock 파일 삭제
rm -rf ~/flutter/bin/cache/lockfile  # macOS/Linux
del %USERPROFILE%\flutter\bin\cache\lockfile  # Windows
```

#### 의존성 충돌
```bash
# 캐시 삭제
flutter clean
flutter pub get

# pubspec.lock 삭제 후 재설치
rm pubspec.lock
flutter pub get
```

#### 빌드 오류 (build_runner)
```bash
# 생성 파일 삭제 후 재생성
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Podman 문제

#### 디스크 공간 부족
```bash
# 사용하지 않는 이미지/컨테이너 삭제
podman system prune -a

# 볼륨 삭제
podman volume prune
```

#### 컨테이너 재시작 루프
```bash
# 로그 확인
podman-compose logs <service_name>

# 컨테이너 중지 후 삭제
podman-compose down
podman-compose up -d
```

#### Rootless Podman 권한 문제
```bash
# 사용자 네임스페이스 확인
podman unshare cat /proc/self/uid_map

# SELinux 문제 (Fedora/RHEL)
sudo setsebool -P container_manage_cgroup on

# 포트 바인딩 권한 (<1024 포트)
sudo sysctl net.ipv4.ip_unprivileged_port_start=80
```

---

## 개발 워크플로우

### 1. 새 기능 개발

```bash
# 새 브랜치 생성
git checkout -b feature/user-authentication

# 개발 진행...

# 커밋
git add .
git commit -m "feat: Add user authentication"

# Push
git push origin feature/user-authentication

# Pull Request 생성 (GitHub)
```

### 2. 코드 리뷰

- GitHub에서 PR 생성
- 자동 CI/CD 체크 (린트, 테스트)
- 팀원 리뷰 요청
- 승인 후 Merge

### 3. 배포

```bash
# 개발 환경
git push origin develop

# 프로덕션 (태그)
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

---

## 유용한 스크립트

### Makefile (backend)

```makefile
# backend/Makefile
.PHONY: run build test lint migrate-up migrate-down

run:
	go run cmd/api/main.go

build:
	go build -o bin/api cmd/api/main.go

test:
	go test -v ./...

lint:
	golangci-lint run ./...

migrate-up:
	migrate -path migrations -database "postgresql://timingle:timingle_dev_password@localhost:5432/timingle?sslmode=disable" up

migrate-down:
	migrate -path migrations -database "postgresql://timingle:timingle_dev_password@localhost:5432/timingle?sslmode=disable" down 1
```

사용:
```bash
make run
make test
make migrate-up
```

### 스크립트 (전체)

#### scripts/dev-setup.sh
```bash
#!/bin/bash
# 개발 환경 초기 설정

set -e

echo "🚀 Setting up timingle development environment..."

# .env 파일 생성
if [ ! -f .env ]; then
  cp .env.example .env
  echo "✅ Created .env file"
fi

# Podman 서비스 시작
cd containers
podman-compose up -d
echo "✅ Podman services started"

# Backend 의존성 설치
cd ../backend
go mod download
echo "✅ Backend dependencies installed"

# Frontend 의존성 설치
cd ../frontend
flutter pub get
echo "✅ Frontend dependencies installed"

echo "🎉 Development environment setup complete!"
```

실행:
```bash
chmod +x scripts/dev-setup.sh
./scripts/dev-setup.sh
```

---

자세한 내용은 [PHASES.md](PHASES.md) 및 각 Phase별 문서를 참조하세요.
