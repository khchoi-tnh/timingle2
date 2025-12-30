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
Client → WebSocket Gateway → NATS (chat.event.{id})
                          → Chat Worker → ScyllaDB (메시지 저장)
                          → NATS (broadcast)
                          → WebSocket Gateway → All Clients
```

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

### NATS Subject 구조
```
chat.event.{event_id}     - 특정 이벤트 채팅
event.created             - 이벤트 생성 알림
event.updated             - 이벤트 변경 알림
event.confirmed           - 이벤트 확정 알림
```

### WebSocket 연결 관리
```
Redis에 연결 상태 저장:
- user:{user_id} → connection_id
- event:{event_id} → [connection_ids]

재연결 로직:
1. 연결 끊김 감지
2. 3초 후 재연결 시도
3. 최대 5회 재시도
4. 마지막 메시지 ID로 동기화
```

## 🗄️ 데이터베이스 전략

### PostgreSQL (주요 데이터)
- 트랜잭션 무결성 필요
- users, events, participants, open_slots, payments

### ScyllaDB (로그/채팅 - 선택적)
- 시계열 데이터
- chat_messages_by_event, event_history
- Write-heavy workload
- 초기에는 PostgreSQL로 시작 가능

### Redis (캐시)
- 세션 관리
- WebSocket 상태
- Rate limiting
- Pub/Sub (선택적)

## 🚀 확장성 고려사항

### Horizontal Scaling
```
API Server: Stateless → 여러 인스턴스 실행 가능
WebSocket Gateway: Redis로 상태 공유 → 스케일 가능
Chat Worker: NATS Consumer Group → 병렬 처리
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
