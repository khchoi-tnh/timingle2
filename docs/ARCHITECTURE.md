# timingle 시스템 아키텍처

## 🏗️ 전체 구조

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                    │
│  (Clean Architecture + SOLID + Riverpod)                │
└────────────┬──────────────────────────────┬─────────────┘
             │ REST API                     │ WebSocket
             │ (HTTPS)                      │ (WSS)
             ▼                              ▼
┌────────────────────────┐    ┌─────────────────────────┐
│    API Server (Go)     │    │  WebSocket Gateway (Go) │
│  - JWT Auth            │    │  - Connection Management│
│  - Event CRUD          │    │  - Message Routing      │
│  - Business Logic      │    │  - NATS Publishing      │
└──────────┬─────────────┘    └────────┬────────────────┘
           │                           │
           ├───────────────────────────┤
           │                           │
           ▼                           ▼
┌──────────────────────┐    ┌─────────────────────────┐
│    PostgreSQL        │    │    NATS JetStream       │
│  - Users             │    │  - Real-time Messages   │
│  - Events            │    │  - Event Bus            │
│  - Participants      │    └────────┬────────────────┘
│  - Open Slots        │             │
│  - Payments          │             │ Subscribe
└──────────────────────┘             ▼
                         ┌─────────────────────────────┐
┌──────────────────────┐ │    Chat Worker (Go)        │
│      Redis           │ │  - Message Persistence      │
│  - Session Cache     │ │  - History Recording        │
│  - WebSocket State   │ └────────┬────────────────────┘
└──────────────────────┘          │
                                  ▼
                         ┌─────────────────────────────┐
                         │    ScyllaDB (Optional)      │
                         │  - Chat Messages            │
                         │  - Event History            │
                         └─────────────────────────────┘
```

## 📊 데이터 흐름

### 1. 이벤트 생성 플로우
```
Client → API Server → PostgreSQL (트랜잭션)
                   → NATS (event.created)
                   → Chat Worker → ScyllaDB (히스토리 기록)
```

### 2. 실시간 채팅 플로우
```
Client → WebSocket Gateway → NATS JetStream (chat.message.{event_id})
                          ↓
                    Immediate Broadcast (실시간 전송)
                          ↓
                    All Clients in Room

Chat Worker ← NATS JetStream (구독)
      ↓
  ScyllaDB (메시지 영구 저장)
```

**특징**:
- 즉시 브로드캐스트: 메시지 전송과 동시에 모든 클라이언트에게 실시간 전달
- 비동기 저장: NATS를 통해 Chat Worker가 별도로 ScyllaDB에 저장
- 메시지 보장: NATS JetStream의 Manual Ack를 통해 저장 실패 시 재시도

### 3. 오픈 예약 플로우
```
Business User → API Server → PostgreSQL (open_slots 저장)

User → API Server (GET /open_slots) → PostgreSQL (필터링)
    → API Server (POST /events + slot_id) → PostgreSQL (트랜잭션)
       - Event 생성
       - open_slot.is_available = FALSE
       - Payment (선택)
```

## 🔧 레이어 아키텍처

### Backend (Go - Clean Architecture)
```
handlers/     → HTTP 요청 처리
services/     → 비즈니스 로직
repositories/ → DB 쿼리
models/       → 데이터 모델
```

### Frontend (Flutter - Clean Architecture)
```
presentation/ → UI (Pages, Widgets, Bloc/Riverpod)
domain/       → 비즈니스 로직 (Entities, UseCases, Repository Interfaces)
data/         → 데이터 접근 (Models, DataSources, Repository Implementations)
```

## 🔐 인증 흐름

```
1. 로그인 요청 (Google OAuth / Phone)
   ↓
2. API Server → JWT 토큰 발급
   - Access Token (15분)
   - Refresh Token (7일)
   ↓
3. Client → 로컬 저장 (Hive)
   ↓
4. 모든 API 요청 → Authorization: Bearer {token}
   ↓
5. Token 만료 시 → Refresh Token으로 재발급
```

## 📡 실시간 통신

### NATS JetStream 구조

**Streams**:
```
CHAT_MESSAGES:
  - Subjects: chat.message.*
  - MaxAge: 24시간
  - Storage: FileStorage
  - Purpose: 채팅 메시지 임시 저장 및 Worker 전달

EVENTS:
  - Subjects: event.*
  - MaxAge: 7일
  - Storage: FileStorage
  - Purpose: 이벤트 변경 이력
```

**Subject 패턴**:
```
chat.message.{event_id}   - 특정 이벤트 채팅 메시지
event.created             - 이벤트 생성 알림
event.updated             - 이벤트 변경 알림
event.confirmed           - 이벤트 확정 알림
```

### WebSocket 연결 관리

**Hub 패턴**:
```
Hub (in-memory):
  - rooms: map[event_id]map[*Client]bool
  - register: channel for client registration
  - unregister: channel for client removal
  - broadcast: channel for message broadcasting

Room 기반 브로드캐스팅:
  - 각 event_id마다 독립적인 채팅방
  - 같은 event_id로 연결된 모든 클라이언트에게 메시지 전달
```

**연결 관리**:
```
1. WebSocket Upgrade (GET /api/v1/ws?event_id=X)
2. JWT 토큰에서 user_id 추출
3. Client 생성 및 Hub에 등록
4. ReadPump (메시지 수신) + WritePump (메시지 송신) goroutine 시작

Ping/Pong:
  - Ping 주기: 54초 (서버 → 클라이언트)
  - Pong 대기: 60초 (클라이언트 → 서버)
  - Read Deadline: 60초
  - Write Deadline: 10초
```

## 🗄️ 데이터베이스 전략

### PostgreSQL (주요 데이터)
- 트랜잭션 무결성 필요
- users, events, participants, open_slots, payments

### ScyllaDB (로그/채팅)
- 시계열 데이터
- Discord-level 확장성을 위한 NoSQL
- Write-heavy workload에 최적화

**테이블 구조**:
```
1. chat_messages_by_event (채팅 메시지)
   - Partition Key: event_id
   - Clustering Key: created_at, message_id
   - Compaction: TimeWindowCompactionStrategy (1일 단위)

2. event_history (이벤트 변경 이력)
   - Partition Key: event_id
   - Clustering Key: changed_at DESC, change_id DESC
   - Purpose: 노쇼 방지를 위한 모든 변경사항 추적

3. unread_message_counts (읽지 않은 메시지 카운터)
   - Counter Table
   - Primary Key: (event_id, user_id)

4. typing_indicators (타이핑 인디케이터)
   - TTL: 10초
   - Primary Key: (event_id, user_id)

5. message_reactions (메시지 반응)
   - Primary Key: (message_id, user_id)

6. chat_messages_by_user (사용자별 메시지 인덱스)
   - Partition Key: user_id
   - Clustering Key: created_at DESC, event_id
   - Purpose: 사용자 활동 추적
```

### Redis (캐시)
- 세션 관리 (JWT Refresh Token 저장)
- Rate limiting
- 캐시 (자주 조회되는 데이터)

**Note**: WebSocket 상태는 Hub 패턴으로 in-memory 관리

## 🚀 확장성 고려사항

### Horizontal Scaling
```
API Server: Stateless → 여러 인스턴스 실행 가능
WebSocket Gateway:
  - 현재: Hub 패턴 (in-memory, single instance)
  - 향후: Redis Pub/Sub으로 multi-instance 지원 가능
Chat Worker: NATS Consumer Group (Durable Subscription) → 병렬 처리
```

### Performance
- DB Connection Pooling (25 connections)
- Redis Caching (자주 조회되는 데이터)
- NATS JetStream (메시지 영속성)
- CDN (정적 파일)

## 📦 배포 아키텍처

### Development
```
Docker Compose
- PostgreSQL
- Redis
- NATS
- (ScyllaDB - 선택)
```

### Production
```
Kubernetes (선택) or Docker Swarm
- API Server (3 replicas)
- WebSocket Gateway (2 replicas)
- Chat Worker (2 replicas)
- PostgreSQL (primary + replica)
- Redis (cluster mode)
- NATS (3-node cluster)
```

## 🔍 모니터링

### Metrics
- Prometheus (메트릭 수집)
- Grafana (대시보드)

### Logging
- 구조화된 로그 (JSON)
- ELK Stack (선택)

### Tracing
- OpenTelemetry (선택)

---

자세한 내용은 각 컴포넌트별 문서를 참조하세요.
