# 데이터베이스 스키마 서버 코드 분석

> PostgreSQL + ScyllaDB 전체 테이블 구조, 인덱스, 마이그레이션 분석

---

## 개요

timingle은 **2종 데이터베이스**를 사용합니다.

| DB | 용도 | 특성 |
|----|------|------|
| **PostgreSQL** | 관계형 데이터 (사용자, 이벤트, 인증, 초대) | ACID, FK, 트랜잭션 |
| **ScyllaDB** | 시계열 데이터 (채팅 메시지, 이벤트 히스토리) | 고속 쓰기, 시계열 최적화 |

---

## ER 다이어그램 (PostgreSQL)

```
┌──────────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│      users       │     │       events          │     │   event_invite_     │
│──────────────────│     │──────────────────────│     │   links             │
│ id (PK)          │◄─┐  │ id (PK)              │◄─┐  │─────────────────────│
│ phone (UNIQUE)   │  │  │ title                │  │  │ id (PK)            │
│ name             │  │  │ description          │  │  │ event_id (FK)──────│──►events
│ email            │  │  │ start_time           │  │  │ code (UNIQUE)      │
│ profile_image_url│  │  │ end_time             │  │  │ created_by (FK)────│──►users
│ region           │  │  │ location             │  │  │ expires_at         │
│ interests        │  │  │ creator_id (FK)──────│──┘  │ max_uses           │
│ timezone         │  │  │ status               │     │ use_count          │
│ language         │  │  │ google_calendar_id   │     │ is_active          │
│ role             │  │  │ created_at           │     │ created_at         │
│ status           │  │  │ updated_at           │     └─────────────────────┘
│ created_at       │  │  └──────────────────────┘
│ updated_at       │  │           │
└──────────────────┘  │           │ 1:N
        │             │           ▼
        │             │  ┌──────────────────────────┐
        │             │  │  event_participants       │
        │             │  │──────────────────────────│
        │             ├──│ event_id (PK, FK)────────│──►events
        │             │  │ user_id (PK, FK)─────────│──►users
        │             │  │ confirmed               │
        │             │  │ confirmed_at            │
        │             │  │ status                  │
        │             │  │ invited_by (FK)──────────│──►users
        │             │  │ invited_at              │
        │             │  │ responded_at            │
        │             │  │ invite_method           │
        │             │  └──────────────────────────┘
        │             │
        │  ┌──────────┘
        │  │
        ▼  ▼
┌──────────────────────┐     ┌──────────────────────┐
│   oauth_accounts     │     │   refresh_tokens     │
│──────────────────────│     │──────────────────────│
│ id (PK)              │     │ id (PK)              │
│ user_id (FK)─────────│──►  │ user_id (FK)─────────│──►users
│ provider             │     │ token (UNIQUE)       │
│ provider_user_id     │     │ expires_at           │
│ email                │     │ created_at           │
│ name                 │     └──────────────────────┘
│ picture_url          │
│ access_token         │     ┌──────────────────────┐
│ refresh_token        │     │    friendships       │
│ token_expiry         │     │──────────────────────│
│ scopes               │     │ id (PK)              │
│ created_at           │     │ user_id (FK)─────────│──►users
│ updated_at           │     │ friend_id (FK)───────│──►users
│ UNIQUE(provider,     │     │ status               │
│   provider_user_id)  │     │ created_at           │
└──────────────────────┘     │ updated_at           │
                             └──────────────────────┘

                             ┌──────────────────────┐
                             │    audit_logs        │
                             │──────────────────────│
                             │ id (PK)              │
                             │ admin_id (FK)────────│──►users
                             │ action               │
                             │ target_type          │
                             │ target_id            │
                             │ old_value (JSONB)    │
                             │ new_value (JSONB)    │
                             │ ip_address (INET)    │
                             │ user_agent           │
                             │ created_at           │
                             └──────────────────────┘
```

---

## PostgreSQL 테이블 상세

### 1. users (사용자)

```sql
CREATE TABLE users (
  id                BIGSERIAL PRIMARY KEY,
  phone             VARCHAR(50) UNIQUE NOT NULL,    -- 전화번호 또는 OAuth placeholder
  name              VARCHAR(100),                   -- nullable
  email             VARCHAR(255),                   -- nullable
  profile_image_url TEXT,                           -- nullable
  region            VARCHAR(50),                    -- nullable
  interests         TEXT[],                         -- 배열
  timezone          VARCHAR(50) DEFAULT 'UTC',
  language          VARCHAR(10) DEFAULT 'ko',
  role              VARCHAR(20) DEFAULT 'USER',     -- USER | BUSINESS | ADMIN | SUPER_ADMIN
  status            VARCHAR(20) DEFAULT 'ACTIVE',   -- ACTIVE | SUSPENDED | DELETED
  created_at        TIMESTAMP DEFAULT NOW(),
  updated_at        TIMESTAMP DEFAULT NOW()         -- 트리거로 자동 갱신
);
```

**인덱스:**

| 인덱스 | 컬럼 | 용도 |
|--------|------|------|
| `idx_users_phone` | phone | 전화번호 로그인 조회 |
| `idx_users_region` | region | 지역별 사용자 조회 |
| `idx_users_role` | role | 역할별 필터링 |
| `idx_users_timezone` | timezone | 타임존별 조회 |
| `idx_users_language` | language | 언어별 조회 |
| `idx_users_status` | status | 상태별 필터링 |

**트리거:** `update_users_updated_at` - UPDATE 시 `updated_at` 자동 갱신

**Role 변경 이력:**
- 초기(001): `USER`, `BUSINESS`
- 확장(012): `USER`, `BUSINESS`, `ADMIN`, `SUPER_ADMIN`

**Phone 변경 이력:**
- 초기(001): `VARCHAR(20)` - 전화번호만
- 확장(008): `VARCHAR(50)` - OAuth placeholder (`oauth_<nanosecond>`) 수용

---

### 2. events (이벤트/약속)

```sql
CREATE TABLE events (
  id                 BIGSERIAL PRIMARY KEY,
  title              VARCHAR(200) NOT NULL,
  description        TEXT,                          -- nullable
  start_time         TIMESTAMPTZ NOT NULL,
  end_time           TIMESTAMPTZ NOT NULL,
  location           VARCHAR(200),                  -- nullable
  creator_id         BIGINT REFERENCES users(id) ON DELETE CASCADE,
  status             VARCHAR(20) DEFAULT 'PROPOSED',  -- PROPOSED | CONFIRMED | CANCELED | DONE
  google_calendar_id VARCHAR(255),                  -- Google Calendar 연동 ID (nullable)
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  updated_at         TIMESTAMPTZ DEFAULT NOW()      -- 트리거로 자동 갱신
);
```

**인덱스:**

| 인덱스 | 컬럼 | 용도 |
|--------|------|------|
| `idx_events_creator_id` | creator_id | Creator의 이벤트 조회 |
| `idx_events_start_time` | start_time | 시간순 이벤트 조회 |
| `idx_events_status` | status | 상태별 필터링 |
| `idx_events_creator_status` | creator_id, status | Creator + 상태 복합 조회 |
| `idx_events_google_calendar_id` | google_calendar_id | Calendar 연동 이벤트 조회 |

**상태 머신:** `PROPOSED` → `CONFIRMED` → `DONE` / `CANCELED`

---

### 3. event_participants (이벤트 참가자)

```sql
CREATE TABLE event_participants (
  event_id      BIGINT REFERENCES events(id) ON DELETE CASCADE,
  user_id       BIGINT REFERENCES users(id) ON DELETE CASCADE,
  confirmed     BOOLEAN DEFAULT FALSE,              -- 레거시 (status로 대체)
  confirmed_at  TIMESTAMPTZ,                        -- 레거시
  status        VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING | ACCEPTED | DECLINED
  invited_by    BIGINT REFERENCES users(id) ON DELETE SET NULL,
  invited_at    TIMESTAMPTZ DEFAULT NOW(),
  responded_at  TIMESTAMPTZ,                        -- 수락/거절 시간
  invite_method VARCHAR(20),                        -- FRIEND | LINK | QR | CREATOR
  PRIMARY KEY (event_id, user_id)
);
```

**인덱스:**

| 인덱스 | 컬럼 | 용도 |
|--------|------|------|
| `idx_event_participants_user_id` | user_id | 사용자의 참가 이벤트 조회 |
| `idx_event_participants_event_confirmed` | event_id, confirmed | 확인된 참가자 조회 |
| `idx_event_participants_status` | status | 상태별 필터링 |
| `idx_event_participants_invited_by` | invited_by | 초대한 사람별 조회 |

**확장 이력 (Migration 010):**
- `status` 추가 (confirmed → status 대체)
- `invited_by`, `invited_at`, `responded_at`, `invite_method` 추가
- 기존 데이터 마이그레이션: `confirmed=true` → `status='ACCEPTED'`

---

### 4. refresh_tokens (리프레시 토큰)

```sql
CREATE TABLE refresh_tokens (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT REFERENCES users(id) ON DELETE CASCADE,
  token      VARCHAR(500) UNIQUE NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**인덱스:**

| 인덱스 | 컬럼 | 용도 |
|--------|------|------|
| `idx_refresh_tokens_user_id` | user_id | 사용자의 토큰 조회/삭제 |
| `idx_refresh_tokens_token` | token | 토큰으로 조회 |
| `idx_refresh_tokens_expires_at` | expires_at | 만료 토큰 정리 |

---

### 5. oauth_accounts (OAuth 계정)

```sql
CREATE TABLE oauth_accounts (
  id               BIGSERIAL PRIMARY KEY,
  user_id          BIGINT REFERENCES users(id) ON DELETE CASCADE,
  provider         VARCHAR(50) NOT NULL,          -- 'google', 'apple' 등
  provider_user_id VARCHAR(255) NOT NULL,         -- Provider 고유 사용자 ID
  email            VARCHAR(255),
  name             VARCHAR(100),
  picture_url      TEXT,
  access_token     TEXT,                          -- Google API 호출용 (Migration 006)
  refresh_token    TEXT,                          -- Access Token 갱신용 (Migration 006)
  token_expiry     TIMESTAMPTZ,                   -- Access Token 만료 시간 (Migration 006)
  scopes           TEXT[],                        -- OAuth Scope 목록 (Migration 006)
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(provider, provider_user_id)
);
```

**인덱스:**

| 인덱스 | 컬럼 | 용도 |
|--------|------|------|
| `idx_oauth_accounts_user_id` | user_id | 사용자의 OAuth 계정 조회 |
| `idx_oauth_accounts_provider` | provider | Provider별 조회 |
| `idx_oauth_accounts_provider_user_id` | provider, provider_user_id | Provider + ID 복합 조회 |
| `idx_oauth_accounts_email` | email | 이메일로 조회 |
| `idx_oauth_accounts_token_expiry` | token_expiry | 만료 토큰 갱신 대상 조회 |

**확장 이력 (Migration 006):**
- `access_token`, `refresh_token`, `token_expiry`, `scopes` 추가
- Google Calendar 연동을 위한 토큰 저장

---

### 6. friendships (친구 관계)

```sql
CREATE TABLE friendships (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status     VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING | ACCEPTED | BLOCKED
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, friend_id),
  CONSTRAINT chk_not_self_friend CHECK (user_id != friend_id)
);
```

**인덱스:**

| 인덱스 | 컬럼 | 용도 |
|--------|------|------|
| `idx_friendships_user` | user_id | 내 친구 목록 |
| `idx_friendships_friend` | friend_id | 나를 추가한 사람 |
| `idx_friendships_status` | status | 상태별 필터링 |
| `idx_friendships_user_status` | user_id, status | 내 수락된 친구 조회 |

**친구 관계 방식:** 단방향 레코드, 수락 시 양방향 레코드 생성
**자기 자신 차단:** `chk_not_self_friend` CHECK 제약조건

---

### 7. event_invite_links (초대 링크)

```sql
CREATE TABLE event_invite_links (
  id         BIGSERIAL PRIMARY KEY,
  event_id   BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  code       VARCHAR(20) NOT NULL UNIQUE,     -- 랜덤 코드 (6바이트 base64)
  created_by BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ,                     -- NULL = 만료 없음
  max_uses   INT NOT NULL DEFAULT 0,          -- 0 = 무제한
  use_count  INT NOT NULL DEFAULT 0,
  is_active  BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**인덱스:**

| 인덱스 | 컬럼 | 용도 |
|--------|------|------|
| `idx_invite_links_code` | code | 코드로 링크 조회 |
| `idx_invite_links_event` | event_id | 이벤트별 링크 조회 |
| `idx_invite_links_active` | is_active (partial) | 활성 링크만 조회 (WHERE is_active=true) |

---

### 8. audit_logs (감사 로그)

```sql
CREATE TABLE audit_logs (
  id          BIGSERIAL PRIMARY KEY,
  admin_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action      VARCHAR(100) NOT NULL,          -- 'USER_SUSPENDED', 'EVENT_DELETED' 등
  target_type VARCHAR(50) NOT NULL,           -- 'user', 'event', 'setting'
  target_id   BIGINT,
  old_value   JSONB,                          -- 변경 전 값
  new_value   JSONB,                          -- 변경 후 값
  ip_address  INET,                           -- 관리자 IP
  user_agent  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

**인덱스:**

| 인덱스 | 컬럼 | 용도 |
|--------|------|------|
| `idx_audit_logs_admin_id` | admin_id | 관리자별 로그 조회 |
| `idx_audit_logs_action` | action | 액션별 필터링 |
| `idx_audit_logs_target` | target_type, target_id | 대상별 로그 조회 |
| `idx_audit_logs_created_at` | created_at DESC | 최신순 로그 조회 |

---

## ScyllaDB 테이블 상세

### 1. chat_messages_by_event (채팅 메시지)

```sql
CREATE TABLE chat_messages_by_event (
  event_id           bigint,
  created_at         timestamp,
  message_id         uuid,
  sender_id          bigint,
  sender_name        text,
  sender_profile_url text,
  message            text,
  message_type       text,             -- 'text', 'system', 'image'
  attachments        list<text>,
  reply_to           uuid,
  edited_at          timestamp,
  is_deleted         boolean,
  metadata           map<text, text>,
  PRIMARY KEY (event_id, created_at, message_id)
) WITH CLUSTERING ORDER BY (created_at ASC);
```

| 키 | 역할 |
|----|------|
| `event_id` | Partition Key (이벤트별 분산) |
| `created_at` | Clustering Key (시간순 정렬, ASC) |
| `message_id` | Clustering Key (동일 시간 메시지 구분) |

### 2. unread_message_counts (읽지 않은 메시지 카운터)

```sql
CREATE TABLE unread_message_counts (
  event_id bigint,
  user_id  bigint,
  count    counter,
  PRIMARY KEY (event_id, user_id)
);
```

| 키 | 역할 |
|----|------|
| `event_id` | Partition Key |
| `user_id` | Clustering Key |
| `count` | ScyllaDB Counter 타입 (원자적 증감) |

### 3. event_history (이벤트 변경 이력)

```sql
CREATE TABLE event_history (
  event_id    bigint,
  changed_at  timestamp,
  change_id   uuid,
  actor_id    bigint,
  actor_name  text,
  change_type text,             -- 'CREATED', 'UPDATED', 'CONFIRMED', 'CANCELED'
  field_name  text,
  old_value   text,
  new_value   text,
  metadata    map<text, text>,
  PRIMARY KEY (event_id, changed_at, change_id)
) WITH CLUSTERING ORDER BY (changed_at DESC);
```

| 키 | 역할 |
|----|------|
| `event_id` | Partition Key (이벤트별 분산) |
| `changed_at` | Clustering Key (최신순 정렬, DESC) |
| `change_id` | Clustering Key (동일 시간 변경 구분) |

---

## 마이그레이션 이력

| # | 파일 | 내용 |
|---|------|------|
| 001 | `001_create_users_table.sql` | users 테이블 + 인덱스 + updated_at 트리거 |
| 002 | `002_create_events_table.sql` | events 테이블 + 인덱스 + 트리거 |
| 003 | `003_create_event_participants_table.sql` | event_participants (PK 복합키) |
| 004 | `004_create_refresh_tokens_table.sql` | refresh_tokens 테이블 |
| 005 | `005_create_oauth_accounts_table.sql` | oauth_accounts + UNIQUE 제약 |
| 006 | `006_add_oauth_tokens.sql` | oauth_accounts에 토큰 컬럼 추가 |
| 007 | `007_add_google_calendar_id.sql` | events에 google_calendar_id 추가 |
| 008 | `008_alter_phone_length.sql` | users.phone VARCHAR(20)→(50) |
| 009 | `009_create_friendships_table.sql` | friendships + 자기 참조 방지 |
| 010 | `010_alter_event_participants.sql` | 참가자 확장 (status, invited_by 등) |
| 011 | `011_create_event_invite_links.sql` | event_invite_links + partial index |
| 012 | `012_add_admin_role.sql` | role 확장 + users.status 추가 |
| 013 | `013_create_audit_logs.sql` | audit_logs (JSONB, INET) |

---

## 테이블 관계 요약

```
users ─┬─ 1:N ─── events (creator_id)
       ├─ N:M ─── events (via event_participants)
       ├─ 1:N ─── refresh_tokens
       ├─ 1:N ─── oauth_accounts
       ├─ N:M ─── users (via friendships: user_id ↔ friend_id)
       └─ 1:N ─── audit_logs (admin_id)

events ─┬─ N:M ─── users (via event_participants)
        ├─ 1:N ─── event_invite_links
        ├─ 1:N ─── chat_messages_by_event (ScyllaDB)
        └─ 1:N ─── event_history (ScyllaDB)
```

---

## 외래 키 삭제 정책

| 테이블 | FK | ON DELETE |
|--------|-----|-----------|
| events.creator_id | → users.id | CASCADE |
| event_participants.event_id | → events.id | CASCADE |
| event_participants.user_id | → users.id | CASCADE |
| event_participants.invited_by | → users.id | SET NULL |
| refresh_tokens.user_id | → users.id | CASCADE |
| oauth_accounts.user_id | → users.id | CASCADE |
| friendships.user_id | → users.id | CASCADE |
| friendships.friend_id | → users.id | CASCADE |
| event_invite_links.event_id | → events.id | CASCADE |
| event_invite_links.created_by | → users.id | CASCADE |
| audit_logs.admin_id | → users.id | CASCADE |

---

## 트리거

### update_updated_at_column

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**적용 대상:**
- `users` → `update_users_updated_at`
- `events` → `update_events_updated_at`

---

## 인덱스 전략 요약

| 패턴 | 예시 | 목적 |
|------|------|------|
| 단일 컬럼 | `idx_users_phone` | 기본 조회 |
| 복합 컬럼 | `idx_events_creator_status` | 자주 함께 사용되는 조건 |
| Partial Index | `idx_invite_links_active WHERE is_active=true` | 활성 데이터만 인덱싱 |
| DESC 정렬 | `idx_audit_logs_created_at DESC` | 최신순 조회 최적화 |

---

## 관련 문서

- [인증 시스템](auth.md) - users, refresh_tokens 사용
- [Google 로그인](google-login.md) - oauth_accounts 사용
- [이벤트 관리](events.md) - events, event_participants 사용
- [채팅 시스템](chat.md) - ScyllaDB 테이블 사용
- [초대 시스템](invites.md) - event_invite_links 사용
- [전체 인덱스](README.md)

---

**작성일:** 2026-02-19
