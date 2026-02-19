# 서버 코드 분석 문서 인덱스

> timingle 백엔드 서버 코드의 기능별 완전 분석 문서

---

## 문서 목록

| 문서 | 기능 | 설명 |
|------|------|------|
| [google-login.md](google-login.md) | Google 로그인 | Google OAuth + Calendar 로그인, 토큰 관리 |
| [auth.md](auth.md) | 인증 시스템 | 회원가입, 로그인, JWT, Middleware |
| [events.md](events.md) | 이벤트 관리 | CRUD, 상태 머신, 참가자 관리 |
| [chat.md](chat.md) | 채팅 시스템 | WebSocket, NATS, ScyllaDB |
| [calendar.md](calendar.md) | Calendar 연동 | Google Calendar API 동기화 |
| [invites.md](invites.md) | 초대 시스템 | 초대 링크, 참가 수락/거절 |
| [database.md](database.md) | DB 스키마 | PostgreSQL + ScyllaDB 전체 테이블 구조, 인덱스, 마이그레이션 |
| [scalability.md](scalability.md) | 확장성 전략 | 50명→1억 단계별 아키텍처 확장 로드맵, 병목 예측, 비용 추정 |

---

## 백엔드 전체 아키텍처

```
┌──────────────────────────────────────────────────────────────┐
│                        Flutter App                            │
└──────────────┬───────────────────────────────┬───────────────┘
               │ HTTP REST API                  │ WebSocket
               ▼                                ▼
┌──────────────────────────────┐  ┌────────────────────────────┐
│      Gin HTTP Router         │  │    WebSocket Handler        │
│  ┌────────────────────────┐  │  │  ┌──────────────────────┐  │
│  │ AuthHandler            │  │  │  │ Hub (Room-based)     │  │
│  │ EventHandler           │  │  │  │ Client (Read/Write)  │  │
│  │ CalendarHandler        │  │  │  └──────────────────────┘  │
│  │ InviteHandler          │  │  └────────────────────────────┘
│  └────────────────────────┘  │               │
└──────────────┬───────────────┘               │
               │                                │
               ▼                                ▼
┌──────────────────────────────────────────────────────────────┐
│                      Service Layer                            │
│  AuthService │ EventService │ ChatService                     │
│  CalendarService │ InviteService                              │
└──────────────┬──────────────────────────┬────────────────────┘
               │                          │
               ▼                          ▼
┌──────────────────────────┐  ┌────────────────────────────────┐
│    Repository Layer      │  │     External Services           │
│  UserRepo │ EventRepo    │  │  Google OAuth API               │
│  AuthRepo │ OAuthRepo    │  │  Google Calendar API            │
│  ChatRepo │ InviteRepo   │  │  NATS JetStream                │
└──────────┬───────────────┘  └────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│                      Data Layer                               │
│  PostgreSQL          │  ScyllaDB           │  Redis           │
│  (users, events,     │  (chat_messages,    │  (cache,         │
│   oauth_accounts,    │   event_history)    │   sessions)      │
│   refresh_tokens,    │                     │                  │
│   invite_links)      │                     │                  │
└──────────────────────────────────────────────────────────────┘
```

---

## API 전체 라우트 맵

### Public (인증 불필요)

| Method | Path | Handler | 문서 |
|--------|------|---------|------|
| GET | `/health` | Health Check | - |
| POST | `/api/v1/auth/register` | Register | [auth.md](auth.md) |
| POST | `/api/v1/auth/login` | Login | [auth.md](auth.md) |
| POST | `/api/v1/auth/refresh` | RefreshToken | [auth.md](auth.md) |
| POST | `/api/v1/auth/google` | GoogleLogin | [google-login.md](google-login.md) |
| POST | `/api/v1/auth/google/calendar` | GoogleCalendarLogin | [google-login.md](google-login.md) |

### Protected (JWT 인증 필요)

| Method | Path | Handler | 문서 |
|--------|------|---------|------|
| POST | `/api/v1/auth/logout` | Logout | [auth.md](auth.md) |
| GET | `/api/v1/auth/me` | Me | [auth.md](auth.md) |
| POST | `/api/v1/events` | CreateEvent | [events.md](events.md) |
| GET | `/api/v1/events` | GetUserEvents | [events.md](events.md) |
| GET | `/api/v1/events/:id` | GetEvent | [events.md](events.md) |
| PUT | `/api/v1/events/:id` | UpdateEvent | [events.md](events.md) |
| DELETE | `/api/v1/events/:id` | DeleteEvent | [events.md](events.md) |
| POST | `/api/v1/events/:id/participants` | AddParticipant | [events.md](events.md) |
| DELETE | `/api/v1/events/:id/participants/:pid` | RemoveParticipant | [events.md](events.md) |
| POST | `/api/v1/events/:id/confirm-participation` | ConfirmParticipation | [events.md](events.md) |
| POST | `/api/v1/events/:id/confirm` | ConfirmEvent | [events.md](events.md) |
| POST | `/api/v1/events/:id/cancel` | CancelEvent | [events.md](events.md) |
| POST | `/api/v1/events/:id/done` | MarkEventDone | [events.md](events.md) |
| GET | `/api/v1/events/:id/messages` | GetMessages | [chat.md](chat.md) |
| POST | `/api/v1/events/:id/invite-link` | CreateInviteLink | [invites.md](invites.md) |
| POST | `/api/v1/events/:id/accept` | AcceptInvite | [invites.md](invites.md) |
| POST | `/api/v1/events/:id/decline` | DeclineInvite | [invites.md](invites.md) |
| GET | `/api/v1/invite/:code` | GetInviteInfo | [invites.md](invites.md) |
| POST | `/api/v1/invite/:code/join` | JoinViaInvite | [invites.md](invites.md) |
| GET | `/api/v1/ws?event_id=N` | HandleWebSocket | [chat.md](chat.md) |
| GET | `/api/v1/calendar/status` | CheckCalendarAccess | [calendar.md](calendar.md) |
| GET | `/api/v1/calendar/events` | GetCalendarEvents | [calendar.md](calendar.md) |
| POST | `/api/v1/calendar/sync/:event_id` | SyncEventToCalendar | [calendar.md](calendar.md) |

---

## 기술 스택

| 구분 | 기술 | 용도 |
|------|------|------|
| **Framework** | Gin (Go) | HTTP Router + Middleware |
| **DB (관계형)** | PostgreSQL | 사용자, 이벤트, OAuth, 초대 |
| **DB (시계열)** | ScyllaDB | 채팅 메시지, 이벤트 히스토리 |
| **Cache** | Redis | 세션, 캐시 |
| **Message Queue** | NATS JetStream | 채팅 메시지 영속화 |
| **Real-time** | gorilla/websocket | 실시간 채팅 |
| **Auth** | JWT (HS256) | 인증 토큰 |
| **OAuth** | Google OAuth 2.0 | 소셜 로그인 |
| **Calendar** | Google Calendar API v3 | 캘린더 동기화 |

---

## 프로젝트 파일 구조

```
backend/
├── cmd/api/
│   └── main.go                          # 엔트리포인트, DI, 라우팅
├── internal/
│   ├── config/
│   │   └── config.go                    # 환경변수 설정
│   ├── db/
│   │   ├── postgres.go                  # PostgreSQL 연결
│   │   ├── redis.go                     # Redis 연결
│   │   ├── scylla.go                    # ScyllaDB 연결
│   │   └── nats.go                      # NATS 연결
│   ├── handlers/
│   │   ├── auth_handler.go              # 인증 API
│   │   ├── event_handler.go             # 이벤트 API
│   │   ├── calendar_handler.go          # Calendar API
│   │   ├── invite_handler.go            # 초대 API
│   │   └── websocket_handler.go         # WebSocket API
│   ├── services/
│   │   ├── auth_service.go              # 인증 비즈니스 로직
│   │   ├── event_service.go             # 이벤트 비즈니스 로직
│   │   ├── chat_service.go              # 채팅 비즈니스 로직
│   │   ├── calendar_service.go          # Calendar 비즈니스 로직
│   │   └── invite_service.go            # 초대 비즈니스 로직
│   ├── repositories/
│   │   ├── user_repository.go           # 사용자 DB
│   │   ├── event_repository.go          # 이벤트 DB
│   │   ├── auth_repository.go           # 인증 토큰 DB
│   │   ├── oauth_repository.go          # OAuth DB
│   │   ├── chat_repository.go           # 채팅 DB (ScyllaDB)
│   │   └── invite_repository.go         # 초대 DB
│   ├── models/
│   │   ├── user.go                      # 사용자 모델
│   │   ├── event.go                     # 이벤트 모델
│   │   ├── auth.go                      # 인증 모델
│   │   ├── oauth.go                     # OAuth 모델
│   │   ├── chat.go                      # 채팅 모델
│   │   └── invite.go                    # 초대 모델
│   ├── middleware/
│   │   ├── auth.go                      # JWT 인증 미들웨어
│   │   ├── cors.go                      # CORS 미들웨어
│   │   └── logger.go                    # 로거 미들웨어
│   └── websocket/
│       ├── hub.go                       # WebSocket Hub (Room 관리)
│       └── client.go                    # WebSocket Client
├── pkg/utils/
│   ├── jwt.go                           # JWT 토큰 관리
│   ├── google_oauth.go                  # Google OAuth 유틸리티
│   └── random.go                        # 랜덤 생성 유틸리티
└── migrations/
    ├── 001_create_users_table.sql
    ├── 002_create_events_table.sql
    ├── 003_create_event_participants_table.sql
    ├── 004_create_refresh_tokens_table.sql
    ├── 005_create_oauth_accounts_table.sql
    ├── 006_add_oauth_tokens.sql
    ├── 007_add_google_calendar_id.sql
    ├── 008_alter_phone_length.sql
    ├── 009_create_friendships_table.sql
    ├── 010_alter_event_participants.sql
    ├── 011_create_event_invite_links.sql
    ├── 012_add_admin_role.sql
    └── 013_create_audit_logs.sql
```

---

**작성일:** 2026-02-19
**대상:** Backend Go Server (Gin Framework)
