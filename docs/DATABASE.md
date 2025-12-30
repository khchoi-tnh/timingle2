# timingle 데이터베이스 설계

## 🗄️ 데이터베이스 구조

### Primary: PostgreSQL
트랜잭션 무결성이 중요한 핵심 데이터
- 사용자 계정, 이벤트 메타데이터, 결제 정보
- ACID 트랜잭션 보장 필요

### Secondary: ScyllaDB (필수)
**대용량 채팅 메시지 및 이벤트 히스토리 저장 (Discord 수준의 확장성)**
- 채팅 메시지 (Write-heavy, 시계열 데이터)
- 이벤트 변경 히스토리 (감사 로그)
- 높은 쓰기 처리량 (10K+ writes/sec)
- 낮은 읽기 지연시간 (< 10ms)
- 수평 확장 가능 (샤딩)

---

## 📊 PostgreSQL 스키마

### users
```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  phone VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE,
  name VARCHAR(100),
  display_name VARCHAR(100),
  profile_image_url TEXT,
  region VARCHAR(50),
  interests TEXT[],
  role VARCHAR(20) DEFAULT 'USER', -- USER, BUSINESS
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_region ON users(region);
CREATE INDEX idx_users_role ON users(role);
```

### events
```sql
CREATE TABLE events (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL,
  location VARCHAR(200),
  creator_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'PROPOSED', -- PROPOSED, CONFIRMED, CANCELED, DONE
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_events_creator ON events(creator_id);
CREATE INDEX idx_events_start_time ON events(start_time);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_creator_status ON events(creator_id, status);
```

### event_participants
```sql
CREATE TABLE event_participants (
  event_id BIGINT REFERENCES events(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  confirmed BOOLEAN DEFAULT FALSE,
  confirmed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (event_id, user_id)
);

CREATE INDEX idx_participants_user ON event_participants(user_id);
CREATE INDEX idx_participants_event ON event_participants(event_id);
```

### open_slots
```sql
CREATE TABLE open_slots (
  id BIGSERIAL PRIMARY KEY,
  business_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  service_type VARCHAR(100) NOT NULL,
  title VARCHAR(200),
  description TEXT,
  start_time TIMESTAMP NOT NULL,
  duration_minutes INT NOT NULL DEFAULT 60,
  price DECIMAL(10,2),
  region VARCHAR(50),
  is_available BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_slots_business_user ON open_slots(business_user_id);
CREATE INDEX idx_slots_region ON open_slots(region);
CREATE INDEX idx_slots_start_time ON open_slots(start_time);
CREATE INDEX idx_slots_available ON open_slots(is_available);
CREATE INDEX idx_slots_region_time ON open_slots(region, start_time) WHERE is_available = TRUE;
```

### payments
```sql
CREATE TABLE payments (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT REFERENCES events(id) ON DELETE SET NULL,
  payer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'KRW',
  status VARCHAR(20) NOT NULL, -- PENDING, COMPLETED, REFUNDED, FAILED
  payment_method VARCHAR(50), -- TOSS, STRIPE, CARD, etc
  transaction_id VARCHAR(100) UNIQUE,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_payments_event ON payments(event_id);
CREATE INDEX idx_payments_payer ON payments(payer_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_transaction ON payments(transaction_id);
```

### oauth_tokens (선택적)
```sql
CREATE TABLE oauth_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider VARCHAR(50) NOT NULL, -- google, kakao, etc
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, provider)
);

CREATE INDEX idx_oauth_user ON oauth_tokens(user_id);
```

---

## 🔥 ScyllaDB 스키마 (필수)

### Keyspace 생성
```cql
CREATE KEYSPACE timingle
WITH replication = {
  'class': 'NetworkTopologyStrategy',
  'datacenter1': 3  -- Replication Factor: 3 (프로덕션)
}
AND durable_writes = true;

USE timingle;
```

### 1. chat_messages_by_event (채팅 메시지)
**Discord 수준의 대용량 채팅 메시지 저장**

```cql
CREATE TABLE chat_messages_by_event (
  event_id BIGINT,              -- Partition Key (이벤트별 샤딩)
  created_at TIMESTAMP,         -- Clustering Key 1 (시간순 정렬)
  message_id UUID,              -- Clustering Key 2 (고유성 보장)
  sender_id BIGINT,             -- 발신자 ID
  sender_name TEXT,             -- 발신자 이름 (역정규화)
  sender_profile_url TEXT,      -- 프로필 이미지 URL (역정규화)
  message TEXT,                 -- 메시지 내용
  message_type TEXT,            -- 메시지 타입 (text, system, image, file)
  attachments LIST<TEXT>,       -- 첨부 파일 URL 목록
  reply_to UUID,                -- 답장 대상 메시지 ID
  edited_at TIMESTAMP,          -- 수정 시간
  is_deleted BOOLEAN,           -- 삭제 여부
  metadata MAP<TEXT, TEXT>,     -- 추가 메타데이터 (JSON-like)
  PRIMARY KEY ((event_id), created_at, message_id)
) WITH CLUSTERING ORDER BY (created_at ASC, message_id ASC)
  AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': 1,
    'compaction_window_unit': 'DAYS'
  }
  AND gc_grace_seconds = 86400  -- 1일 (삭제된 데이터 보관)
  AND bloom_filter_fp_chance = 0.01
  AND caching = {
    'keys': 'ALL',
    'rows_per_partition': '100'  -- 최근 100개 메시지 캐싱
  }
  AND comment = 'Discord-level chat messages storage';
```

**성능 최적화 전략**:
- Partition Key: `event_id` → 이벤트별로 샤딩
- Clustering Key: `created_at` → 시간순 정렬 (최신 메시지 빠른 조회)
- Time Window Compaction: 일별 Compaction으로 쓰기 최적화
- Row Caching: 최근 100개 메시지 캐싱

### 2. chat_messages_by_user (사용자별 메시지 인덱스)
**사용자별 최근 활동 조회**

```cql
CREATE TABLE chat_messages_by_user (
  user_id BIGINT,               -- Partition Key
  created_at TIMESTAMP,         -- Clustering Key 1
  event_id BIGINT,              -- 이벤트 ID
  message_id UUID,              -- 메시지 ID
  message TEXT,                 -- 메시지 내용 (역정규화)
  PRIMARY KEY ((user_id), created_at, event_id)
) WITH CLUSTERING ORDER BY (created_at DESC)
  AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': 7,
    'compaction_window_unit': 'DAYS'
  }
  AND comment = 'User activity index';
```

### 3. event_history (이벤트 변경 히스토리)
**모든 변경사항 감사 로그 (노쇼 방지, 분쟁 해결)**

```cql
CREATE TABLE event_history (
  event_id BIGINT,              -- Partition Key
  changed_at TIMESTAMP,         -- Clustering Key 1 (최신순)
  change_id UUID,               -- Clustering Key 2 (고유성)
  actor_id BIGINT,              -- 변경 수행자 ID
  actor_name TEXT,              -- 변경 수행자 이름 (역정규화)
  change_type TEXT,             -- CREATED, UPDATED, CONFIRMED, CANCELED, PARTICIPANT_ADDED, etc
  field_name TEXT,              -- 변경된 필드 (예: start_time, location)
  old_value TEXT,               -- 이전 값 (JSON)
  new_value TEXT,               -- 새 값 (JSON)
  ip_address TEXT,              -- IP 주소 (감사 목적)
  user_agent TEXT,              -- User Agent (감사 목적)
  metadata MAP<TEXT, TEXT>,     -- 추가 정보
  PRIMARY KEY ((event_id), changed_at, change_id)
) WITH CLUSTERING ORDER BY (changed_at DESC, change_id DESC)
  AND compaction = {
    'class': 'SizeTieredCompactionStrategy'
  }
  AND gc_grace_seconds = 2592000  -- 30일 (법적 요구사항 대비)
  AND comment = 'Audit log for event changes (no-show prevention)';
```

**사용 사례**:
- 노쇼 방지: 누가 약속을 취소했는지 기록
- 분쟁 해결: 시간 변경 이력 추적
- PDF 내보내기: Pro 플랜 사용자용

### 4. message_reactions (메시지 반응)
**채팅 메시지에 대한 이모지 반응 (Discord 기능)**

```cql
CREATE TABLE message_reactions (
  message_id UUID,              -- Partition Key
  user_id BIGINT,               -- Clustering Key
  emoji TEXT,                   -- 이모지 (예: 👍, ❤️)
  created_at TIMESTAMP,         -- 반응 추가 시간
  PRIMARY KEY ((message_id), user_id)
) WITH comment = 'Message reactions (emoji)';
```

### 5. typing_indicators (타이핑 표시)
**실시간 타이핑 상태 (TTL 사용)**

```cql
CREATE TABLE typing_indicators (
  event_id BIGINT,              -- Partition Key
  user_id BIGINT,               -- Clustering Key
  started_at TIMESTAMP,         -- 타이핑 시작 시간
  PRIMARY KEY ((event_id), user_id)
) WITH default_time_to_live = 10  -- 10초 후 자동 삭제
  AND comment = 'Real-time typing indicators (auto-expire)';
```

### 6. unread_message_counts (읽지 않은 메시지 수)
**이벤트별 읽지 않은 메시지 카운터**

```cql
CREATE TABLE unread_message_counts (
  user_id BIGINT,               -- Partition Key
  event_id BIGINT,              -- Clustering Key
  unread_count COUNTER,         -- 카운터 (증감 가능)
  last_read_at TIMESTAMP,       -- 마지막 읽은 시간
  PRIMARY KEY ((user_id), event_id)
) WITH comment = 'Unread message counters per event';
```

**사용법**:
```cql
-- 읽지 않은 메시지 증가
UPDATE unread_message_counts
SET unread_count = unread_count + 1
WHERE user_id = 123 AND event_id = 456;

-- 메시지 읽음 처리
UPDATE unread_message_counts
SET unread_count = 0, last_read_at = toTimestamp(now())
WHERE user_id = 123 AND event_id = 456;
```

---

## 🔄 상태 전이 (State Machine)

### Event Status
```
PROPOSED → CONFIRMED → DONE
   ↓          ↓
CANCELED  CANCELED
```

**규칙**:
- PROPOSED: 초기 상태
- CONFIRMED: 모든 참여자 확인 필요
- DONE: start_time + duration 후 자동 전환 (또는 수동)
- CANCELED: 언제든지 가능 (이력 기록)

### Payment Status
```
PENDING → COMPLETED
   ↓          ↓
FAILED    REFUNDED
```

---

## 🔍 주요 쿼리 예시

### 1. 사용자의 예정된 이벤트 조회
```sql
SELECT e.*
FROM events e
JOIN event_participants ep ON e.id = ep.event_id
WHERE ep.user_id = $1
  AND e.status IN ('PROPOSED', 'CONFIRMED')
  AND e.start_time >= NOW()
ORDER BY e.start_time ASC;
```

### 2. 지역별 오픈 예약 조회
```sql
SELECT *
FROM open_slots
WHERE region = $1
  AND is_available = TRUE
  AND start_time >= NOW()
ORDER BY start_time ASC
LIMIT 50;
```

### 3. 이벤트 채팅 메시지 조회 (ScyllaDB)
```cql
-- 최근 100개 메시지 조회
SELECT *
FROM chat_messages_by_event
WHERE event_id = ?
ORDER BY created_at DESC
LIMIT 100;

-- 특정 시간 범위 조회
SELECT *
FROM chat_messages_by_event
WHERE event_id = ?
  AND created_at >= ?
  AND created_at <= ?
ORDER BY created_at ASC;

-- 페이지네이션 (created_at + message_id 기준)
SELECT *
FROM chat_messages_by_event
WHERE event_id = ?
  AND (created_at, message_id) > (?, ?)
ORDER BY created_at ASC
LIMIT 50;
```

### 4. 사용자별 최근 활동 조회 (ScyllaDB)
```cql
SELECT event_id, message, created_at
FROM chat_messages_by_user
WHERE user_id = ?
ORDER BY created_at DESC
LIMIT 20;
```

### 5. 읽지 않은 메시지 수 조회 (ScyllaDB)
```cql
SELECT event_id, unread_count, last_read_at
FROM unread_message_counts
WHERE user_id = ?;
```

---

## 🔐 보안 고려사항

### 1. Row-Level Security (RLS) - 선택적
```sql
-- 사용자는 자신이 참여한 이벤트만 조회 가능
CREATE POLICY event_participant_policy ON events
  FOR SELECT
  USING (
    id IN (
      SELECT event_id FROM event_participants WHERE user_id = current_user_id()
    )
  );
```

### 2. 민감 정보 암호화
- phone: 해싱 또는 암호화
- payment 정보: 암호화
- OAuth tokens: 암호화

### 3. Soft Delete
```sql
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP;
CREATE INDEX idx_users_deleted ON users(deleted_at);
```

---

## 📈 마이그레이션 전략

### 도구
- [golang-migrate](https://github.com/golang-migrate/migrate)

### 파일 구조
```
migrations/
├── 000001_create_users_table.up.sql
├── 000001_create_users_table.down.sql
├── 000002_create_events_table.up.sql
├── 000002_create_events_table.down.sql
...
```

### 실행
```bash
migrate -path ./migrations -database "postgresql://..." up
migrate -path ./migrations -database "postgresql://..." down 1
```

---

## 🚀 성능 최적화

### PostgreSQL 최적화

#### 1. 인덱스 전략
- 자주 조회되는 컬럼에 인덱스
- Composite Index (region, start_time)
- Partial Index (is_available = TRUE)

#### 2. Connection Pooling
```go
db.SetMaxOpenConns(25)
db.SetMaxIdleConns(5)
db.SetConnMaxLifetime(5 * time.Minute)
```

#### 3. Query 최적화
- N+1 문제 방지 (JOIN 활용)
- SELECT * 대신 필요한 컬럼만
- LIMIT 사용

### ScyllaDB 최적화 (Discord 수준)

#### 1. Partition 크기 관리
```cql
-- 권장: 파티션당 최대 100MB
-- 해결책: 이벤트별 샤딩 (event_id가 Partition Key)
-- 예상 크기: 1개 이벤트당 평균 1,000개 메시지 × 1KB = 1MB (안전)
```

#### 2. Read/Write 성능 튜닝
```go
// Go gocql 설정
cluster := gocql.NewCluster("scylla-node1", "scylla-node2", "scylla-node3")
cluster.Consistency = gocql.Quorum  // 읽기/쓰기 균형
cluster.NumConns = 4                // 노드당 연결 수
cluster.PageSize = 100              // 페이지 크기
cluster.Timeout = 10 * time.Second
```

#### 3. Compaction 전략
- **TimeWindowCompactionStrategy**: 채팅 메시지 (시계열)
  - 일별 또는 시간별 윈도우
  - 오래된 데이터 자동 압축
- **SizeTieredCompactionStrategy**: 이벤트 히스토리 (감사 로그)
  - 크기 기반 압축

#### 4. Caching 전략
```cql
-- Row Cache: 최근 메시지 캐싱
ALTER TABLE chat_messages_by_event
WITH caching = {
  'keys': 'ALL',
  'rows_per_partition': '100'
};
```

#### 5. Replication Factor
```cql
-- 프로덕션: RF=3 (3개 복제본)
-- 개발: RF=1
ALTER KEYSPACE timingle
WITH replication = {
  'class': 'NetworkTopologyStrategy',
  'datacenter1': 3
};
```

#### 6. 대용량 데이터 처리 (Discord 수준)
**예상 규모**:
- 이벤트: 10만 개
- 평균 메시지/이벤트: 100개
- 총 메시지: 1,000만 개
- 평균 메시지 크기: 500 bytes
- **총 스토리지: ~5GB** (압축 전)

**확장 전략**:
- 노드 추가 (수평 확장)
- Multi-datacenter 복제
- Partition Key 재설계 (필요 시)

---

## 📊 백업 전략

### PostgreSQL
- 일일 full backup
- WAL archiving (PITR)
- Replica for read scaling

### ScyllaDB
- 자동 스냅샷
- Multi-datacenter replication

---

자세한 스키마는 `backend/migrations/` 디렉토리 참조
