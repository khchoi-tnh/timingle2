# 채팅 시스템 서버 코드 분석

> WebSocket + NATS JetStream + ScyllaDB 실시간 채팅 전체 분석

---

## 개요

timingle의 실시간 채팅 시스템은 **이벤트(약속)에 종속된 채팅방** 구조입니다.

**핵심 원칙:** "약속 없이는 대화 불가" - 모든 채팅은 이벤트에 종속

**핵심 기능:**
- WebSocket 기반 실시간 메시지 전달
- NATS JetStream을 통한 메시지 영속화
- ScyllaDB에 메시지 저장 (시계열 데이터)
- Room 기반 Hub 패턴 (이벤트별 독립 채팅방)
- 이벤트 히스토리 (변경 이력 자동 기록)

---

## 아키텍처

```
┌──────────────────────────────────────────────────────────────────┐
│                      Flutter App (WebSocket Client)               │
└─────────────────────────┬────────────────────────────────────────┘
                          │ ws://host/api/v1/ws?event_id=N
                          ▼
┌──────────────────────────────────────────────────────────────────┐
│                    WebSocket Handler                              │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────────┐    │
│  │ Upgrade HTTP │ →  │ Auth Check   │ →  │ Create Client    │    │
│  │ → WebSocket  │    │ (JWT + Event)│    │ (ReadPump/       │    │
│  └─────────────┘    └──────────────┘    │  WritePump)      │    │
│                                          └──────────────────┘    │
└─────────────────────────┬────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────────┐
│                         Hub (Room Manager)                        │
│                                                                   │
│  rooms: map[eventID] → map[*Client]bool                          │
│                                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │ Event 1  │  │ Event 2  │  │ Event 3  │   ← 이벤트별 채팅방    │
│  │ Client A │  │ Client C │  │ Client E │                       │
│  │ Client B │  │ Client D │  │          │                       │
│  └──────────┘  └──────────┘  └──────────┘                       │
│                                                                   │
│  Channels: register | unregister | broadcast                     │
└─────────────────────────┬────────────────────────────────────────┘
                          │
              ┌───────────┼────────────┐
              ▼                        ▼
┌──────────────────────┐  ┌──────────────────────────┐
│   NATS JetStream     │  │   WebSocket Broadcast    │
│   (메시지 영속화)     │  │   (실시간 전달)           │
│                      │  │                          │
│  Subject:            │  │  hub.BroadcastToEvent()  │
│  chat.message.{id}   │  │  → 같은 방 클라이언트    │
└──────────┬───────────┘  └──────────────────────────┘
           │
           ▼
┌──────────────────────┐
│      ScyllaDB        │
│  chat_messages_by_   │
│  event               │
│  (시계열 저장)        │
└──────────────────────┘
```

---

## 파일 구조

| 레이어 | 파일 | 역할 |
|--------|------|------|
| Handler | `internal/handlers/websocket_handler.go` | WebSocket 연결, HTTP 메시지 조회 |
| Service | `internal/services/chat_service.go` | 채팅 비즈니스 로직 |
| Repository | `internal/repositories/chat_repository.go` | ScyllaDB CRUD |
| WebSocket | `internal/websocket/hub.go` | Room 기반 연결 관리 |
| WebSocket | `internal/websocket/client.go` | 개별 클라이언트 Read/Write |
| Model | `internal/models/chat.go` | 데이터 구조 |

---

## API 엔드포인트

### WebSocket 연결

| Method | Path | 설명 |
|--------|------|------|
| GET | `/api/v1/ws?event_id=N` | WebSocket 연결 (Protected) |

### REST API

| Method | Path | 설명 |
|--------|------|------|
| GET | `/api/v1/events/:id/messages` | 채팅 메시지 조회 (Protected) |

---

## WebSocket 연결 흐름

```mermaid
sequenceDiagram
    participant 📱 as Flutter
    participant 🖥️ as Backend
    participant 🔌 as Hub

    Note over 📱,🔌: WebSocket 연결

    📱->>🖥️: GET /ws?event_id=10 (Authorization: Bearer ...)
    🖥️->>🖥️: JWT 검증 (AuthMiddleware)
    🖥️->>🖥️: VerifyEventAccess(eventID, userID)
    🖥️->>🖥️: WebSocket Upgrade (gorilla/websocket)
    🖥️->>🔌: RegisterClient(client)
    🔌->>🔌: rooms[10][client] = true
    🖥️->>📱: WebSocket Connected ✅

    Note over 📱,🔌: 메시지 전송

    📱->>🖥️: WS Message: { type: "message", message: "안녕!" }
    🖥️->>🖥️: ChatService.SendMessage()
    🖥️->>🖥️: NATS Publish("chat.message.10", msg)
    🖥️->>🔌: hub.BroadcastToEvent(10, msgBytes)
    🔌->>📱: WS Message: { event_id: 10, message: "안녕!", sender_name: "홍길동" }

    Note over 📱,🔌: 연결 해제

    📱->>🖥️: WebSocket Close
    🖥️->>🔌: UnregisterClient(client)
    🔌->>🔌: delete rooms[10][client]
```

---

## 코드 상세 분석

### WebSocket Handler

```go
// HandleWebSocket - WebSocket 연결 처리
// GET /ws?event_id=1
func (h *WebSocketHandler) HandleWebSocket(c *gin.Context) {
    userID, _ := c.Get("userID")                    // JWT 미들웨어에서 설정
    eventID, _ := strconv.ParseInt(c.Query("event_id"), 10, 64)

    // 1. 이벤트 멤버 검증 (Creator 또는 Participant)
    h.chatService.VerifyEventAccess(eventID, userID.(int64))

    // 2. HTTP → WebSocket 업그레이드
    conn, _ := upgrader.Upgrade(c.Writer, c.Request, nil)

    // 3. Client 생성 및 Hub 등록
    client := ws.NewClient(h.hub, conn, userID.(int64), eventID)
    h.hub.RegisterClient(client)

    // 4. 비동기 Read/Write 고루틴 시작
    go client.ReadPump(func(message []byte) {
        h.handleIncomingMessage(userID.(int64), eventID, message)
    })
    go client.WritePump()
}

// WebSocket Upgrader 설정
var upgrader = websocket.Upgrader{
    ReadBufferSize:  1024,
    WriteBufferSize: 1024,
    CheckOrigin: func(r *http.Request) bool {
        return true  // TODO: Production에서 도메인 검증 필요
    },
}
```

### Hub (Room Manager)

```go
type Hub struct {
    rooms      map[int64]map[*Client]bool  // eventID → clients
    register   chan *Client                 // 등록 채널
    unregister chan *Client                 // 해제 채널
    broadcast  chan *BroadcastMessage       // 브로드캐스트 채널 (버퍼: 256)
    mu         sync.RWMutex                // 동시성 보호
}

// Run - Hub 메인 루프 (고루틴으로 실행)
func (h *Hub) Run() {
    for {
        select {
        case client := <-h.register:
            // Room이 없으면 생성, Client 추가
            h.rooms[client.EventID][client] = true

        case client := <-h.unregister:
            // Client 제거, 빈 Room 삭제
            delete(clients, client)
            close(client.send)
            if len(clients) == 0 {
                delete(h.rooms, client.EventID)
            }

        case message := <-h.broadcast:
            // 같은 이벤트의 모든 Client에게 전송
            for client := range h.rooms[message.EventID] {
                select {
                case client.send <- message.Data:
                default:
                    // 전송 실패 시 연결 정리
                    close(client.send)
                    delete(clients, client)
                }
            }
        }
    }
}
```

### Client (Read/Write Pump)

```go
type Client struct {
    hub     *Hub
    conn    *websocket.Conn
    send    chan []byte       // 송신 버퍼 (256)
    UserID  int64
    EventID int64
}

// 상수
const (
    writeWait      = 10 * time.Second    // 쓰기 타임아웃
    pongWait       = 60 * time.Second    // Pong 대기 시간
    pingPeriod     = 54 * time.Second    // Ping 주기 (pongWait * 9/10)
    maxMessageSize = 512 * 1024          // 최대 메시지 크기 (512KB)
)

// ReadPump - 클라이언트 → 서버 메시지 수신
func (c *Client) ReadPump(onMessage func([]byte)) {
    defer func() {
        c.hub.UnregisterClient(c)   // 연결 해제 시 Hub에서 제거
        c.conn.Close()
    }()
    c.conn.SetReadLimit(maxMessageSize)
    c.conn.SetReadDeadline(time.Now().Add(pongWait))
    c.conn.SetPongHandler(...)       // Pong 수신 시 ReadDeadline 갱신

    for {
        _, message, err := c.conn.ReadMessage()
        if err != nil { break }
        onMessage(message)           // handleIncomingMessage 콜백
    }
}

// WritePump - 서버 → 클라이언트 메시지 전송
func (c *Client) WritePump() {
    ticker := time.NewTicker(pingPeriod)
    defer func() {
        ticker.Stop()
        c.conn.Close()
    }()

    for {
        select {
        case message, ok := <-c.send:
            // 메시지 전송 + 큐에 쌓인 메시지 일괄 전송
            w, _ := c.conn.NextWriter(websocket.TextMessage)
            w.Write(message)
            n := len(c.send)
            for i := 0; i < n; i++ {
                w.Write([]byte{'\n'})
                w.Write(<-c.send)
            }
            w.Close()

        case <-ticker.C:
            // Ping 전송 (연결 유지)
            c.conn.WriteMessage(websocket.PingMessage, nil)
        }
    }
}
```

### Chat Service

```go
type ChatService struct {
    chatRepo     *repositories.ChatRepository
    userRepo     *repositories.UserRepository
    eventService *EventService
    hub          *ws.Hub
    nats         nats.JetStreamContext
}

// VerifyEventAccess - 이벤트 접근 권한 확인
func (s *ChatService) VerifyEventAccess(eventID, userID int64) error {
    isMember, _ := s.eventService.IsUserEventMember(eventID, userID)
    if !isMember {
        return fmt.Errorf("user is not a member of this event")
    }
    return nil
}

// SendMessage - 메시지 전송
func (s *ChatService) SendMessage(userID, eventID int64, wsMsg *models.WSMessage) error {
    // 1. 사용자 정보 조회
    user, _ := s.userRepo.FindByID(userID)

    // 2. ChatMessage 생성 (UUID, 타임스탬프)
    msg := &models.ChatMessage{
        EventID:     eventID,
        CreatedAt:   time.Now().UTC(),
        MessageID:   uuid.New(),
        SenderID:    userID,
        SenderName:  name,
        Message:     wsMsg.Message,
        MessageType: "text",
        ReplyTo:     wsMsg.ReplyTo,
    }

    // 3. NATS JetStream에 발행 (영속화)
    subject := "chat.message." + strconv.FormatInt(eventID, 10)
    s.nats.Publish(subject, msgBytes)

    // 4. Hub을 통해 실시간 브로드캐스트
    s.hub.BroadcastToEvent(eventID, msgBytes)

    return nil
}

// GetMessages - 메시지 조회 (페이지네이션)
func (s *ChatService) GetMessages(eventID int64, limit int, before *time.Time) ([]*models.ChatMessage, error) {
    return s.chatRepo.GetMessages(eventID, limit, before)
}
```

### Chat Repository (ScyllaDB)

```go
type ChatRepository struct {
    session *gocql.Session   // ScyllaDB 세션
}

// SaveMessage - ScyllaDB에 메시지 저장
// 테이블: chat_messages_by_event
func (r *ChatRepository) SaveMessage(msg *models.ChatMessage) error {
    query := `INSERT INTO chat_messages_by_event (...) VALUES (?, ?, ...)`
    return r.session.Query(query, msg.EventID, msg.CreatedAt, ...).Exec()
}

// GetMessages - 메시지 조회 (페이지네이션 지원)
func (r *ChatRepository) GetMessages(eventID int64, limit int, startTime *time.Time) ([]*models.ChatMessage, error) {
    if startTime != nil {
        // 커서 기반 페이지네이션: created_at < startTime
        query = `... WHERE event_id = ? AND created_at < ? ORDER BY created_at ASC LIMIT ?`
    } else {
        // 최신 메시지
        query = `... WHERE event_id = ? ORDER BY created_at ASC LIMIT ?`
    }
    // ... iter.Scan() → messages
}

// IncrementUnreadCount - 읽지 않은 메시지 카운터 증가
// 테이블: unread_message_counts (ScyllaDB Counter)
func (r *ChatRepository) IncrementUnreadCount(eventID, userID int64) error {
    query := `UPDATE unread_message_counts SET count = count + 1 WHERE event_id = ? AND user_id = ?`
    return r.session.Query(query, eventID, userID).Exec()
}

// ResetUnreadCount - 읽지 않은 메시지 카운터 리셋
func (r *ChatRepository) ResetUnreadCount(eventID, userID int64) error {
    query := `UPDATE unread_message_counts SET count = 0 WHERE event_id = ? AND user_id = ?`
}

// SaveEventHistory - 이벤트 변경 이력 저장
// 테이블: event_history
func (r *ChatRepository) SaveEventHistory(entry *models.EventHistoryEntry) error {
    query := `INSERT INTO event_history (...) VALUES (?, ?, ...)`
}

// GetEventHistory - 이벤트 변경 이력 조회
func (r *ChatRepository) GetEventHistory(eventID int64, limit int) ([]*models.EventHistoryEntry, error) {
    query := `... WHERE event_id = ? ORDER BY changed_at DESC LIMIT ?`
}
```

---

## 데이터 모델

### ChatMessage (ScyllaDB)

```go
type ChatMessage struct {
    EventID          int64             // Partition Key
    CreatedAt        time.Time         // Clustering Key (ASC)
    MessageID        uuid.UUID         // Unique ID
    SenderID         int64             // 보낸 사람 ID
    SenderName       string            // 보낸 사람 이름
    SenderProfileURL string            // 프로필 이미지 URL
    Message          string            // 메시지 내용
    MessageType      string            // "text" | "system" | "image"
    Attachments      []string          // 첨부파일 URL
    ReplyTo          *uuid.UUID        // 답장 대상 메시지 ID
    EditedAt         *time.Time        // 수정 시간
    IsDeleted        bool              // 삭제 여부
    Metadata         map[string]string // 추가 데이터
}
```

### EventHistoryEntry (ScyllaDB)

```go
type EventHistoryEntry struct {
    EventID    int64             // Partition Key
    ChangedAt  time.Time         // Clustering Key (DESC)
    ChangeID   uuid.UUID         // Unique ID
    ActorID    int64             // 변경한 사람 ID
    ActorName  string            // 변경한 사람 이름
    ChangeType string            // "CREATED" | "UPDATED" | "CONFIRMED" | "CANCELED"
    FieldName  string            // 변경된 필드명
    OldValue   string            // 이전 값
    NewValue   string            // 새 값
    Metadata   map[string]string // 추가 데이터
}
```

### WSMessage (WebSocket 프로토콜)

```go
type WSMessage struct {
    Type    string     `json:"type"`     // "message" | "typing" | "system"
    Message string     `json:"message"`
    ReplyTo *uuid.UUID `json:"reply_to"` // 답장 대상
}
```

---

## ScyllaDB 테이블 구조

### chat_messages_by_event

```sql
CREATE TABLE chat_messages_by_event (
    event_id          bigint,
    created_at        timestamp,
    message_id        uuid,
    sender_id         bigint,
    sender_name       text,
    sender_profile_url text,
    message           text,
    message_type      text,
    attachments       list<text>,
    reply_to          uuid,
    edited_at         timestamp,
    is_deleted        boolean,
    metadata          map<text, text>,
    PRIMARY KEY (event_id, created_at, message_id)
) WITH CLUSTERING ORDER BY (created_at ASC);
```

### unread_message_counts

```sql
CREATE TABLE unread_message_counts (
    event_id bigint,
    user_id  bigint,
    count    counter,
    PRIMARY KEY (event_id, user_id)
);
```

### event_history

```sql
CREATE TABLE event_history (
    event_id    bigint,
    changed_at  timestamp,
    change_id   uuid,
    actor_id    bigint,
    actor_name  text,
    change_type text,
    field_name  text,
    old_value   text,
    new_value   text,
    metadata    map<text, text>,
    PRIMARY KEY (event_id, changed_at, change_id)
) WITH CLUSTERING ORDER BY (changed_at DESC);
```

---

## 메시지 전송 이중 경로

```
메시지 전송 시 2가지 경로로 동시 처리:

1. 실시간 경로 (즉시 전달)
   SendMessage() → hub.BroadcastToEvent() → WebSocket → Flutter

2. 영속화 경로 (저장)
   SendMessage() → NATS Publish("chat.message.{eventID}") → Worker → ScyllaDB
```

| 경로 | 목적 | 지연 | 저장 |
|------|------|------|------|
| WebSocket Broadcast | 실시간 UI 업데이트 | ~ms | ❌ |
| NATS → ScyllaDB | 메시지 영구 저장 | ~100ms | ✅ |

---

## WebSocket 연결 관리

### Ping/Pong (연결 유지)

```
Client                    Server
  │                         │
  │◄── Ping (54초 주기) ────│
  │── Pong ────────────────►│
  │                         │  ReadDeadline 갱신 (60초)
  │                         │
  │  (60초 Pong 없으면)     │
  │        연결 해제        │
```

### 연결 해제 처리

```
1. ReadPump에서 에러 발생 (타임아웃, 클라이언트 종료)
2. defer: hub.UnregisterClient(client) + conn.Close()
3. Hub: rooms[eventID]에서 client 제거
4. Hub: send 채널 close
5. WritePump: send 채널 close 감지 → conn.Close()
6. Hub: Room에 클라이언트 0명이면 Room 삭제
```

---

## Request/Response 예시

### 메시지 조회

```http
GET /api/v1/events/10/messages?limit=20
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

**Response (200):**
```json
[
  {
    "event_id": 10,
    "created_at": "2026-02-19T14:30:00Z",
    "message_id": "550e8400-e29b-41d4-a716-446655440000",
    "sender_id": 1,
    "sender_name": "홍길동",
    "sender_profile_url": "https://...",
    "message": "내일 6시에 만나요!",
    "message_type": "text",
    "reply_to": null,
    "is_deleted": false
  }
]
```

### WebSocket 메시지 전송

```json
// Client → Server
{
  "type": "message",
  "message": "안녕하세요!",
  "reply_to": null
}

// Server → All Clients (Broadcast)
{
  "event_id": 10,
  "created_at": "2026-02-19T14:35:00Z",
  "message_id": "660e8400-e29b-41d4-a716-446655440001",
  "sender_id": 1,
  "sender_name": "홍길동",
  "message": "안녕하세요!",
  "message_type": "text",
  "is_deleted": false
}
```

---

## 에러 처리

| 상황 | HTTP/WS | 메시지 |
|------|---------|--------|
| JWT 없음/만료 | 401 | `unauthorized` |
| event_id 누락 | 400 | `invalid event_id` |
| 이벤트 멤버 아님 | 403 | `not a member of this event` |
| WebSocket Upgrade 실패 | - | 로그만 기록 |
| NATS Publish 실패 | - | 에러 반환 (실시간은 전달됨) |
| ScyllaDB 조회 실패 | 500 | `failed to get messages` |

---

## 관련 문서

- [이벤트 관리](events.md) - 이벤트 멤버십 (채팅 접근 권한)
- [인증 시스템](auth.md) - JWT 미들웨어 (WebSocket 인증)
- [전체 인덱스](README.md)

---

**작성일:** 2026-02-19
