# timingle 테스트 가이드

## 📋 목차

1. [테스트 환경 설정](#테스트-환경-설정)
2. [백엔드 통합 테스트](#백엔드-통합-테스트)
3. [WebSocket 테스트](#websocket-테스트)
4. [데이터베이스 확인](#데이터베이스-확인)

---

## 테스트 환경 설정

### 컨테이너 실행 확인
```bash
cd /home/khchoi/projects/timingle2/containers

# 모든 컨테이너 상태 확인
podman-compose ps

# 예상 출력:
# NAME                    STATUS
# timingle-postgres       Up
# timingle-redis          Up
# timingle-nats           Up
# timingle-scylla         Up
```

### 서버 실행

#### API Server
```bash
cd /home/khchoi/projects/timingle2/backend

# 환경변수 설정
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_USER=timingle
export POSTGRES_DB=timingle
export POSTGRES_PASSWORD=timingle_dev_password
export REDIS_HOST=localhost
export REDIS_PORT=6379
export NATS_URL=nats://localhost:4222
export SCYLLA_HOSTS=localhost
export SCYLLA_KEYSPACE=timingle

# 백그라운드 실행
nohup ./bin/api > /tmp/api.log 2>&1 &

# 또는 포그라운드 실행
./bin/api
```

#### Chat Worker
```bash
cd /home/khchoi/projects/timingle2/backend

# 환경변수 설정 (API Server와 동일)
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_USER=timingle
export POSTGRES_DB=timingle
export POSTGRES_PASSWORD=timingle_dev_password
export NATS_URL=nats://localhost:4222
export SCYLLA_HOSTS=localhost
export SCYLLA_KEYSPACE=timingle

# 백그라운드 실행
nohup ./bin/worker > /tmp/worker.log 2>&1 &
```

---

## 백엔드 통합 테스트

### 통합 테스트 스크립트 실행

```bash
cd /home/khchoi/projects/timingle2

# 실행 권한 부여
chmod +x test_integration.sh

# 테스트 실행
./test_integration.sh
```

### 테스트 시나리오

#### 1. Health Check
```bash
curl -s http://localhost:8080/health | python3 -m json.tool
```

**예상 응답**:
```json
{
  "status": "healthy",
  "timestamp": "2025-12-31T15:45:00Z"
}
```

#### 2. 사용자 등록
```bash
curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"01012345678","name":"테스터"}' | python3 -m json.tool
```

**예상 응답**:
```json
{
  "id": 1,
  "phone": "01012345678",
  "name": "테스터",
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "created_at": "2025-12-31T15:45:00Z"
}
```

#### 3. 이벤트 생성
```bash
# ACCESS_TOKEN 환경변수 설정 필요
ACCESS_TOKEN="your_access_token_here"

curl -s -X POST http://localhost:8080/api/v1/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "title":"테스트 이벤트",
    "description":"통합 테스트",
    "start_time":"2026-01-05T14:00:00Z",
    "end_time":"2026-01-05T16:00:00Z",
    "location":"테스트 룸"
  }' | python3 -m json.tool
```

**예상 응답**:
```json
{
  "id": 1,
  "title": "테스트 이벤트",
  "description": "통합 테스트",
  "start_time": "2026-01-05T14:00:00Z",
  "end_time": "2026-01-05T16:00:00Z",
  "location": "테스트 룸",
  "status": "PROPOSED",
  "creator_id": 1,
  "created_at": "2025-12-31T15:45:00Z"
}
```

#### 4. 이벤트 목록 조회
```bash
curl -s -X GET http://localhost:8080/api/v1/events \
  -H "Authorization: Bearer $ACCESS_TOKEN" | python3 -m json.tool
```

#### 5. 이벤트 확정
```bash
EVENT_ID=1

curl -s -X POST http://localhost:8080/api/v1/events/$EVENT_ID/confirm \
  -H "Authorization: Bearer $ACCESS_TOKEN" | python3 -m json.tool
```

**예상 응답**:
```json
{
  "id": 1,
  "status": "CONFIRMED",
  "confirmed_at": "2025-12-31T15:46:00Z"
}
```

#### 6. 채팅 메시지 조회
```bash
curl -s -X GET http://localhost:8080/api/v1/events/$EVENT_ID/messages \
  -H "Authorization: Bearer $ACCESS_TOKEN" | python3 -m json.tool
```

**예상 응답** (메시지 없을 경우):
```json
[]
```

---

## WebSocket 테스트

### wscat 설치
```bash
npm install -g wscat
```

### WebSocket 연결

```bash
# ACCESS_TOKEN과 EVENT_ID 설정
ACCESS_TOKEN="your_access_token_here"
EVENT_ID=1

# WebSocket 연결
wscat -c "ws://localhost:8080/api/v1/ws?event_id=$EVENT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### 메시지 전송

연결 후 다음 JSON을 입력:

```json
{"type":"message","message":"안녕하세요!"}
```

**예상 응답** (브로드캐스트):
```json
{
  "event_id": 1,
  "created_at": "2025-12-31T15:47:00Z",
  "message_id": "550e8400-e29b-41d4-a716-446655440000",
  "sender_id": 1,
  "sender_name": "테스터",
  "sender_profile_url": "",
  "message": "안녕하세요!",
  "message_type": "text",
  "attachments": null,
  "reply_to": null,
  "edited_at": null,
  "is_deleted": false,
  "metadata": null
}
```

### 답장 메시지 전송

```json
{
  "type":"message",
  "message":"답장입니다!",
  "reply_to":"550e8400-e29b-41d4-a716-446655440000"
}
```

### 다중 클라이언트 테스트

**Terminal 1**:
```bash
wscat -c "ws://localhost:8080/api/v1/ws?event_id=$EVENT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

**Terminal 2** (같은 이벤트):
```bash
wscat -c "ws://localhost:8080/api/v1/ws?event_id=$EVENT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN2"
```

Terminal 1에서 메시지 전송 시, Terminal 2에서도 즉시 수신 확인

---

## 데이터베이스 확인

### PostgreSQL

```bash
# 컨테이너 접속
podman exec -it timingle-postgres psql -U timingle -d timingle

# 사용자 조회
SELECT id, phone, name, role, created_at FROM users;

# 이벤트 조회
SELECT id, title, status, start_time, creator_id, created_at FROM events;

# 참여자 조회
SELECT event_id, user_id, confirmed, confirmed_at FROM event_participants;

# 종료
\q
```

### ScyllaDB

```bash
# 컨테이너 접속
podman exec -it timingle-scylla cqlsh

# Keyspace 사용
USE timingle;

# 테이블 목록
DESCRIBE TABLES;

# 채팅 메시지 조회
SELECT event_id, created_at, message_id, sender_name, message
FROM chat_messages_by_event
WHERE event_id = 1
LIMIT 10;

# 이벤트 히스토리 조회
SELECT event_id, changed_at, change_type, actor_name, field_name, old_value, new_value
FROM event_history
WHERE event_id = 1
LIMIT 10;

# 종료
exit
```

### Redis

```bash
# 컨테이너 접속
podman exec -it timingle-redis redis-cli

# Refresh Token 확인 (예시)
KEYS refresh_token:*

# 특정 토큰 조회
GET refresh_token:1

# 종료
exit
```

### NATS

```bash
# Stream 상태 확인
curl -s http://localhost:8222/jsz | python3 -m json.tool

# 예상 출력:
{
  "streams": [
    {
      "name": "CHAT_MESSAGES",
      "messages": 10,
      "bytes": 2048,
      "consumers": 1
    },
    {
      "name": "EVENTS",
      "messages": 5,
      "bytes": 1024,
      "consumers": 0
    }
  ]
}
```

---

## 로그 확인

### API Server 로그
```bash
# 백그라운드 실행 시
tail -f /tmp/api.log

# 예상 로그:
# 2025/12/31 15:45:00 ✅ Connected to PostgreSQL
# 2025/12/31 15:45:00 ✅ Connected to Redis
# 2025/12/31 15:45:00 ✅ Connected to NATS
# 2025/12/31 15:45:00 ✅ Connected to ScyllaDB
# 2025/12/31 15:45:00 🚀 Server started on :8080
```

### Chat Worker 로그
```bash
# 백그라운드 실행 시
tail -f /tmp/worker.log

# 예상 로그:
# 2025/12/31 15:45:40 ✅ Connected to ScyllaDB
# 2025/12/31 15:45:40 ✅ Connected to NATS JetStream
# 2025/12/31 15:45:40 🚀 Chat worker started. Listening for messages...
# 2025/12/31 15:47:00 Saved message 550e8400-e29b-41d4-a716-446655440000 to event 1
```

### 컨테이너 로그
```bash
# PostgreSQL
podman logs timingle-postgres

# Redis
podman logs timingle-redis

# NATS
podman logs timingle-nats

# ScyllaDB
podman logs timingle-scylla
```

---

## 문제 해결

### API Server 시작 실패

**증상**: `Failed to connect to PostgreSQL`

**해결**:
```bash
# PostgreSQL 컨테이너 상태 확인
podman ps | grep postgres

# 재시작
podman restart timingle-postgres

# 연결 테스트
podman exec -it timingle-postgres psql -U timingle -d timingle -c "SELECT 1;"
```

### WebSocket 연결 실패

**증상**: `401 Unauthorized`

**원인**: ACCESS_TOKEN 만료 또는 잘못된 토큰

**해결**:
```bash
# 새로운 토큰 발급
curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"01099998888","name":"New User"}' | python3 -m json.tool

# 반환된 access_token 사용
```

### Chat Worker 메시지 저장 실패

**증상**: `Failed to save message to ScyllaDB`

**해결**:
```bash
# ScyllaDB 상태 확인
podman exec -it timingle-scylla nodetool status

# Keyspace 확인
podman exec -it timingle-scylla cqlsh -e "DESCRIBE KEYSPACE timingle;"

# 스키마 재적용
podman exec -it timingle-scylla cqlsh -f /etc/scylla/init.cql
```

### NATS JetStream Stream 없음

**증상**: `stream not found`

**해결**:
```bash
# API Server 재시작 (Stream 자동 생성)
pkill -f "bin/api"
./backend/bin/api

# Stream 확인
curl -s http://localhost:8222/jsz | python3 -m json.tool
```

---

## 성능 테스트 (선택)

### Apache Bench (ab)

```bash
# API 성능 테스트
ab -n 1000 -c 10 -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8080/api/v1/events
```

### wrk

```bash
# 설치
sudo dnf install wrk

# 테스트
wrk -t4 -c100 -d30s -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8080/api/v1/events
```

---

## 자동화된 테스트 (향후)

### Go 테스트
```bash
cd backend
go test ./... -v
```

### Flutter 테스트
```bash
cd frontend
flutter test
```

---

**문서 작성일**: 2025-12-31
**최종 업데이트**: Phase 2 완료 후
