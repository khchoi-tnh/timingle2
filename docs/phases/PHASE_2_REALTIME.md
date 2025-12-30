# Phase 2: 실시간 기능 구현 (Week 2)

**목표**: WebSocket, NATS JetStream, ScyllaDB 연동하여 실시간 채팅 시스템 구축

**소요 시간**: 5-7일

**완료 조건**:
- ✅ WebSocket Gateway 동작
- ✅ NATS JetStream 설정 완료
- ✅ ScyllaDB 연동 및 채팅 메시지 저장
- ✅ 실시간 메시지 송수신 동작
- ✅ 이벤트 히스토리 자동 기록

---

## 📋 사전 준비사항

### 완료 확인
- [ ] PHASE_1_BACKEND_CORE.md 완료
- [ ] REST API 서버 정상 동작
- [ ] PostgreSQL, Redis, NATS, ScyllaDB 컨테이너 실행 중

### 확인 명령
```bash
cd /home/khchoi/projects/timingle2/containers

# 모든 컨테이너 확인
podman-compose ps

# NATS 상태 확인
curl http://localhost:8222/varz | jq '.jetstream'

# ScyllaDB 상태 확인
podman exec -it timingle-scylla nodetool status
podman exec -it timingle-scylla cqlsh -e "DESCRIBE KEYSPACES;"
```

---

## 🗄️ Step 1: ScyllaDB 스키마 생성

### 1.1 Keyspace 생성
```bash
cat > containers/scylla/init.cql << 'EOF'
-- timingle Keyspace (Discord-level 확장성)
CREATE KEYSPACE IF NOT EXISTS timingle
  WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'datacenter1': 3  -- 복제 계수 3 (프로덕션)
    -- 개발 환경에서는 'SimpleStrategy', 'replication_factor': 1 사용 가능
  }
  AND durable_writes = true;

USE timingle;

-- 1. 채팅 메시지 (이벤트별)
CREATE TABLE IF NOT EXISTS chat_messages_by_event (
  event_id BIGINT,              -- Partition Key
  created_at TIMESTAMP,         -- Clustering Key 1
  message_id UUID,              -- Clustering Key 2
  sender_id BIGINT,
  sender_name TEXT,
  sender_profile_url TEXT,
  message TEXT,
  message_type TEXT,            -- 'text', 'system', 'image'
  attachments LIST<TEXT>,
  reply_to UUID,
  edited_at TIMESTAMP,
  is_deleted BOOLEAN,
  metadata MAP<TEXT, TEXT>,
  PRIMARY KEY ((event_id), created_at, message_id)
) WITH CLUSTERING ORDER BY (created_at ASC, message_id ASC)
  AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': 1,
    'compaction_window_unit': 'DAYS'
  }
  AND gc_grace_seconds = 86400
  AND caching = {'keys': 'ALL', 'rows_per_partition': '100'};

-- 2. 이벤트 히스토리 (변경 로그)
CREATE TABLE IF NOT EXISTS event_history (
  event_id BIGINT,
  changed_at TIMESTAMP,
  change_id UUID,
  actor_id BIGINT,
  actor_name TEXT,
  change_type TEXT,             -- 'CREATED', 'UPDATED', 'CONFIRMED', 'CANCELED'
  field_name TEXT,              -- 변경된 필드
  old_value TEXT,
  new_value TEXT,
  metadata MAP<TEXT, TEXT>,
  PRIMARY KEY ((event_id), changed_at, change_id)
) WITH CLUSTERING ORDER BY (changed_at DESC, change_id DESC)
  AND compaction = {'class': 'SizeTieredCompactionStrategy'}
  AND gc_grace_seconds = 864000; -- 10일 (노쇼 증거 보관)

-- 3. 읽지 않은 메시지 카운터
CREATE TABLE IF NOT EXISTS unread_message_counts (
  event_id BIGINT,
  user_id BIGINT,
  count COUNTER,
  PRIMARY KEY ((event_id, user_id))
);

-- 4. 타이핑 인디케이터 (TTL 10초)
CREATE TABLE IF NOT EXISTS typing_indicators (
  event_id BIGINT,
  user_id BIGINT,
  user_name TEXT,
  started_at TIMESTAMP,
  PRIMARY KEY ((event_id), user_id)
) WITH default_time_to_live = 10;

-- 5. 메시지 반응 (좋아요, 이모지)
CREATE TABLE IF NOT EXISTS message_reactions (
  message_id UUID,
  user_id BIGINT,
  reaction TEXT,                -- '👍', '❤️', '😂', etc.
  created_at TIMESTAMP,
  PRIMARY KEY ((message_id), user_id)
);

-- 6. 사용자별 채팅 메시지 인덱스 (선택적, 사용자 활동 추적)
CREATE TABLE IF NOT EXISTS chat_messages_by_user (
  user_id BIGINT,
  created_at TIMESTAMP,
  event_id BIGINT,
  message_id UUID,
  PRIMARY KEY ((user_id), created_at, event_id)
) WITH CLUSTERING ORDER BY (created_at DESC, event_id ASC);
EOF

# ScyllaDB 초기화
podman exec -it timingle-scylla cqlsh -f /etc/scylla/init.cql
```

**또는 직접 cqlsh로 실행**:
```bash
# 컨테이너 내부 접속
podman exec -it timingle-scylla cqlsh

# 위의 CQL 쿼리를 하나씩 실행
```

### 1.2 테이블 확인
```bash
podman exec -it timingle-scylla cqlsh -e "DESCRIBE TABLES;"
```

**예상 출력**:
```
chat_messages_by_event
event_history
unread_message_counts
typing_indicators
message_reactions
chat_messages_by_user
```

---

## 🔌 Step 2: ScyllaDB Go 드라이버 연동

### 2.1 internal/db/scylla.go
```bash
cat > backend/internal/db/scylla.go << 'EOF'
package db

import (
	"fmt"
	"log"
	"time"

	"github.com/gocql/gocql"
)

type ScyllaDB struct {
	Session *gocql.Session
}

func NewScyllaDB(hosts []string, keyspace string) (*ScyllaDB, error) {
	cluster := gocql.NewCluster(hosts...)
	cluster.Keyspace = keyspace
	cluster.Consistency = gocql.Quorum
	cluster.ProtoVersion = 4
	cluster.ConnectTimeout = 10 * time.Second
	cluster.Timeout = 5 * time.Second
	cluster.NumConns = 2

	session, err := cluster.CreateSession()
	if err != nil {
		return nil, fmt.Errorf("failed to connect to ScyllaDB: %w", err)
	}

	log.Println("✅ ScyllaDB connected successfully")

	return &ScyllaDB{Session: session}, nil
}

func (s *ScyllaDB) Close() {
	log.Println("🔌 Closing ScyllaDB connection...")
	s.Session.Close()
}
EOF
```

### 2.2 ScyllaDB 모델
```bash
cat > backend/internal/models/chat.go << 'EOF'
package models

import (
	"time"

	"github.com/google/uuid"
)

type ChatMessage struct {
	EventID          int64             `json:"event_id"`
	CreatedAt        time.Time         `json:"created_at"`
	MessageID        uuid.UUID         `json:"message_id"`
	SenderID         int64             `json:"sender_id"`
	SenderName       string            `json:"sender_name"`
	SenderProfileURL string            `json:"sender_profile_url"`
	Message          string            `json:"message"`
	MessageType      string            `json:"message_type"` // text, system, image
	Attachments      []string          `json:"attachments,omitempty"`
	ReplyTo          *uuid.UUID        `json:"reply_to,omitempty"`
	EditedAt         *time.Time        `json:"edited_at,omitempty"`
	IsDeleted        bool              `json:"is_deleted"`
	Metadata         map[string]string `json:"metadata,omitempty"`
}

type EventHistoryEntry struct {
	EventID    int64             `json:"event_id"`
	ChangedAt  time.Time         `json:"changed_at"`
	ChangeID   uuid.UUID         `json:"change_id"`
	ActorID    int64             `json:"actor_id"`
	ActorName  string            `json:"actor_name"`
	ChangeType string            `json:"change_type"` // CREATED, UPDATED, CONFIRMED, CANCELED
	FieldName  string            `json:"field_name"`
	OldValue   string            `json:"old_value"`
	NewValue   string            `json:"new_value"`
	Metadata   map[string]string `json:"metadata,omitempty"`
}

type SendMessageRequest struct {
	EventID     int64     `json:"event_id" binding:"required"`
	Message     string    `json:"message" binding:"required"`
	MessageType string    `json:"message_type"` // text, system, image
	ReplyTo     *uuid.UUID `json:"reply_to,omitempty"`
}

type GetMessagesRequest struct {
	EventID   int64      `json:"event_id" binding:"required"`
	Limit     int        `json:"limit"`      // 기본 50
	StartTime *time.Time `json:"start_time"` // 페이징용
}
EOF
```

---

## 📂 Step 3: ScyllaDB Repository

### 3.1 internal/repositories/chat_repository.go
```bash
cat > backend/internal/repositories/chat_repository.go << 'EOF'
package repositories

import (
	"time"

	"github.com/gocql/gocql"
	"github.com/google/uuid"
	"github.com/yourusername/timingle/internal/models"
)

type ChatRepository struct {
	session *gocql.Session
}

func NewChatRepository(session *gocql.Session) *ChatRepository {
	return &ChatRepository{session: session}
}

// 메시지 저장
func (r *ChatRepository) SaveMessage(msg *models.ChatMessage) error {
	query := `
		INSERT INTO chat_messages_by_event (
			event_id, created_at, message_id, sender_id, sender_name, sender_profile_url,
			message, message_type, attachments, reply_to, edited_at, is_deleted, metadata
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`

	return r.session.Query(query,
		msg.EventID,
		msg.CreatedAt,
		msg.MessageID,
		msg.SenderID,
		msg.SenderName,
		msg.SenderProfileURL,
		msg.Message,
		msg.MessageType,
		msg.Attachments,
		msg.ReplyTo,
		msg.EditedAt,
		msg.IsDeleted,
		msg.Metadata,
	).Exec()
}

// 메시지 조회 (최신 N개, 페이징 지원)
func (r *ChatRepository) GetMessages(eventID int64, limit int, startTime *time.Time) ([]*models.ChatMessage, error) {
	if limit == 0 {
		limit = 50
	}

	var query string
	var args []interface{}

	if startTime != nil {
		// 페이징: startTime 이전 메시지
		query = `
			SELECT event_id, created_at, message_id, sender_id, sender_name, sender_profile_url,
			       message, message_type, attachments, reply_to, edited_at, is_deleted, metadata
			FROM chat_messages_by_event
			WHERE event_id = ? AND created_at < ?
			ORDER BY created_at DESC
			LIMIT ?
		`
		args = []interface{}{eventID, *startTime, limit}
	} else {
		// 최신 메시지
		query = `
			SELECT event_id, created_at, message_id, sender_id, sender_name, sender_profile_url,
			       message, message_type, attachments, reply_to, edited_at, is_deleted, metadata
			FROM chat_messages_by_event
			WHERE event_id = ?
			ORDER BY created_at DESC
			LIMIT ?
		`
		args = []interface{}{eventID, limit}
	}

	iter := r.session.Query(query, args...).Iter()

	messages := []*models.ChatMessage{}
	msg := &models.ChatMessage{}

	for iter.Scan(
		&msg.EventID,
		&msg.CreatedAt,
		&msg.MessageID,
		&msg.SenderID,
		&msg.SenderName,
		&msg.SenderProfileURL,
		&msg.Message,
		&msg.MessageType,
		&msg.Attachments,
		&msg.ReplyTo,
		&msg.EditedAt,
		&msg.IsDeleted,
		&msg.Metadata,
	) {
		messages = append(messages, msg)
		msg = &models.ChatMessage{}
	}

	if err := iter.Close(); err != nil {
		return nil, err
	}

	return messages, nil
}

// 읽지 않은 메시지 카운터 증가
func (r *ChatRepository) IncrementUnreadCount(eventID, userID int64) error {
	query := `UPDATE unread_message_counts SET count = count + 1 WHERE event_id = ? AND user_id = ?`
	return r.session.Query(query, eventID, userID).Exec()
}

// 읽지 않은 메시지 카운터 초기화
func (r *ChatRepository) ResetUnreadCount(eventID, userID int64) error {
	query := `UPDATE unread_message_counts SET count = 0 WHERE event_id = ? AND user_id = ?`
	return r.session.Query(query, eventID, userID).Exec()
}

// 이벤트 히스토리 저장
func (r *ChatRepository) SaveEventHistory(entry *models.EventHistoryEntry) error {
	query := `
		INSERT INTO event_history (
			event_id, changed_at, change_id, actor_id, actor_name,
			change_type, field_name, old_value, new_value, metadata
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`

	return r.session.Query(query,
		entry.EventID,
		entry.ChangedAt,
		entry.ChangeID,
		entry.ActorID,
		entry.ActorName,
		entry.ChangeType,
		entry.FieldName,
		entry.OldValue,
		entry.NewValue,
		entry.Metadata,
	).Exec()
}

// 이벤트 히스토리 조회
func (r *ChatRepository) GetEventHistory(eventID int64, limit int) ([]*models.EventHistoryEntry, error) {
	if limit == 0 {
		limit = 100
	}

	query := `
		SELECT event_id, changed_at, change_id, actor_id, actor_name,
		       change_type, field_name, old_value, new_value, metadata
		FROM event_history
		WHERE event_id = ?
		ORDER BY changed_at DESC
		LIMIT ?
	`

	iter := r.session.Query(query, eventID, limit).Iter()

	entries := []*models.EventHistoryEntry{}
	entry := &models.EventHistoryEntry{}

	for iter.Scan(
		&entry.EventID,
		&entry.ChangedAt,
		&entry.ChangeID,
		&entry.ActorID,
		&entry.ActorName,
		&entry.ChangeType,
		&entry.FieldName,
		&entry.OldValue,
		&entry.NewValue,
		&entry.Metadata,
	) {
		entries = append(entries, entry)
		entry = &models.EventHistoryEntry{}
	}

	if err := iter.Close(); err != nil {
		return nil, err
	}

	return entries, nil
}
EOF
```

---

## 🚀 Step 4: NATS JetStream 설정

### 4.1 NATS 연결
```bash
cat > backend/internal/db/nats.go << 'EOF'
package db

import (
	"fmt"
	"log"

	"github.com/nats-io/nats.go"
)

type NATSClient struct {
	Conn *nats.Conn
	JS   nats.JetStreamContext
}

func NewNATSClient(url string) (*NATSClient, error) {
	nc, err := nats.Connect(url,
		nats.MaxReconnects(5),
		nats.ReconnectWait(2),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to NATS: %w", err)
	}

	// JetStream 활성화
	js, err := nc.JetStream()
	if err != nil {
		return nil, fmt.Errorf("failed to create JetStream context: %w", err)
	}

	log.Println("✅ NATS JetStream connected successfully")

	return &NATSClient{Conn: nc, JS: js}, nil
}

func (n *NATSClient) Close() {
	log.Println("🔌 Closing NATS connection...")
	n.Conn.Close()
}

// Stream 생성 (초기화 시 1회 실행)
func (n *NATSClient) CreateStreams() error {
	// Chat 메시지 스트림
	_, err := n.JS.AddStream(&nats.StreamConfig{
		Name:     "CHAT_MESSAGES",
		Subjects: []string{"chat.message.*"},
		MaxAge:   24 * 60 * 60 * 1000000000, // 24시간 보관
		Storage:  nats.FileStorage,
	})
	if err != nil && err != nats.ErrStreamNameAlreadyInUse {
		return fmt.Errorf("failed to create CHAT_MESSAGES stream: %w", err)
	}

	// Event 이벤트 스트림
	_, err = n.JS.AddStream(&nats.StreamConfig{
		Name:     "EVENTS",
		Subjects: []string{"event.*"},
		MaxAge:   7 * 24 * 60 * 60 * 1000000000, // 7일 보관
		Storage:  nats.FileStorage,
	})
	if err != nil && err != nats.ErrStreamNameAlreadyInUse {
		return fmt.Errorf("failed to create EVENTS stream: %w", err)
	}

	log.Println("✅ NATS JetStream streams created")

	return nil
}
EOF
```

---

## 🔌 Step 5: WebSocket Gateway

### 5.1 internal/websocket/hub.go
```bash
cat > backend/internal/websocket/hub.go << 'EOF'
package websocket

import (
	"log"
	"sync"

	"github.com/gorilla/websocket"
)

// Hub: WebSocket 연결 관리
type Hub struct {
	// Event ID -> Client 맵
	rooms      map[int64]map[*Client]bool
	register   chan *Client
	unregister chan *Client
	broadcast  chan *BroadcastMessage
	mu         sync.RWMutex
}

type BroadcastMessage struct {
	EventID int64
	Data    []byte
}

func NewHub() *Hub {
	return &Hub{
		rooms:      make(map[int64]map[*Client]bool),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		broadcast:  make(chan *BroadcastMessage, 256),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			if _, ok := h.rooms[client.EventID]; !ok {
				h.rooms[client.EventID] = make(map[*Client]bool)
			}
			h.rooms[client.EventID][client] = true
			h.mu.Unlock()
			log.Printf("Client %d joined event %d", client.UserID, client.EventID)

		case client := <-h.unregister:
			h.mu.Lock()
			if clients, ok := h.rooms[client.EventID]; ok {
				if _, ok := clients[client]; ok {
					delete(clients, client)
					close(client.send)
					if len(clients) == 0 {
						delete(h.rooms, client.EventID)
					}
				}
			}
			h.mu.Unlock()
			log.Printf("Client %d left event %d", client.UserID, client.EventID)

		case message := <-h.broadcast:
			h.mu.RLock()
			clients := h.rooms[message.EventID]
			h.mu.RUnlock()

			for client := range clients {
				select {
				case client.send <- message.Data:
				default:
					close(client.send)
					delete(clients, client)
				}
			}
		}
	}
}

func (h *Hub) BroadcastToEvent(eventID int64, data []byte) {
	h.broadcast <- &BroadcastMessage{
		EventID: eventID,
		Data:    data,
	}
}
EOF
```

### 5.2 internal/websocket/client.go
```bash
cat > backend/internal/websocket/client.go << 'EOF'
package websocket

import (
	"encoding/json"
	"log"
	"time"

	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512
)

type Client struct {
	hub     *Hub
	conn    *websocket.Conn
	send    chan []byte
	UserID  int64
	EventID int64
}

func NewClient(hub *Hub, conn *websocket.Conn, userID, eventID int64) *Client {
	return &Client{
		hub:     hub,
		conn:    conn,
		send:    make(chan []byte, 256),
		UserID:  userID,
		EventID: eventID,
	}
}

func (c *Client) ReadPump(onMessage func([]byte)) {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
			}
			break
		}
		onMessage(message)
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
EOF
```

### 5.3 WebSocket Handler
```bash
cat > backend/internal/handlers/websocket_handler.go << 'EOF'
package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/nats-io/nats.go"
	"github.com/yourusername/timingle/internal/models"
	"github.com/yourusername/timingle/internal/repositories"
	ws "github.com/yourusername/timingle/internal/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // 프로덕션에서는 Origin 검증 필요
	},
}

type WebSocketHandler struct {
	hub      *ws.Hub
	nats     nats.JetStreamContext
	chatRepo *repositories.ChatRepository
	userRepo *repositories.UserRepository
}

func NewWebSocketHandler(
	hub *ws.Hub,
	nats nats.JetStreamContext,
	chatRepo *repositories.ChatRepository,
	userRepo *repositories.UserRepository,
) *WebSocketHandler {
	return &WebSocketHandler{
		hub:      hub,
		nats:     nats,
		chatRepo: chatRepo,
		userRepo: userRepo,
	}
}

// GET /ws?event_id=1
func (h *WebSocketHandler) HandleWebSocket(c *gin.Context) {
	userID := c.GetInt64("user_id") // Middleware에서 설정
	eventIDStr := c.Query("event_id")
	eventID, err := strconv.ParseInt(eventIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event_id"})
		return
	}

	// TODO: 사용자가 해당 이벤트의 참여자인지 확인

	// WebSocket 업그레이드
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket upgrade failed: %v", err)
		return
	}

	client := ws.NewClient(h.hub, conn, userID, eventID)
	h.hub.register <- client

	// 메시지 수신 핸들러
	go client.ReadPump(func(message []byte) {
		h.handleIncomingMessage(userID, eventID, message)
	})

	// 메시지 송신
	go client.WritePump()
}

func (h *WebSocketHandler) handleIncomingMessage(userID, eventID int64, data []byte) {
	var req struct {
		Message string     `json:"message"`
		ReplyTo *uuid.UUID `json:"reply_to,omitempty"`
	}

	if err := json.Unmarshal(data, &req); err != nil {
		log.Printf("Failed to parse message: %v", err)
		return
	}

	// 사용자 정보 조회
	user, err := h.userRepo.GetByID(userID)
	if err != nil {
		log.Printf("User not found: %v", err)
		return
	}

	// 메시지 객체 생성
	msg := &models.ChatMessage{
		EventID:          eventID,
		CreatedAt:        time.Now().UTC(),
		MessageID:        uuid.New(),
		SenderID:         userID,
		SenderName:       user.Name,
		SenderProfileURL: user.ProfileImageURL,
		Message:          req.Message,
		MessageType:      "text",
		ReplyTo:          req.ReplyTo,
		IsDeleted:        false,
	}

	// NATS로 발행 (Worker가 ScyllaDB에 저장)
	msgBytes, _ := json.Marshal(msg)
	subject := "chat.message." + strconv.FormatInt(eventID, 10)
	if _, err := h.nats.Publish(subject, msgBytes); err != nil {
		log.Printf("Failed to publish message to NATS: %v", err)
		return
	}

	// 즉시 브로드캐스트 (실시간 전송)
	h.hub.BroadcastToEvent(eventID, msgBytes)
}
EOF
```

---

## 🛠️ Step 6: NATS Consumer (Chat Worker)

### 6.1 cmd/worker/main.go
```bash
cat > backend/cmd/worker/main.go << 'EOF'
package main

import (
	"encoding/json"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/nats-io/nats.go"
	"github.com/yourusername/timingle/internal/config"
	"github.com/yourusername/timingle/internal/db"
	"github.com/yourusername/timingle/internal/models"
	"github.com/yourusername/timingle/internal/repositories"
)

func main() {
	// 설정 로드
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// ScyllaDB 연결
	scyllaDB, err := db.NewScyllaDB(cfg.Scylla.Hosts, cfg.Scylla.Keyspace)
	if err != nil {
		log.Fatalf("Failed to connect to ScyllaDB: %v", err)
	}
	defer scyllaDB.Close()

	chatRepo := repositories.NewChatRepository(scyllaDB.Session)

	// NATS 연결
	natsClient, err := db.NewNATSClient(cfg.NATS.URL)
	if err != nil {
		log.Fatalf("Failed to connect to NATS: %v", err)
	}
	defer natsClient.Close()

	// JetStream Consumer 생성
	sub, err := natsClient.JS.Subscribe("chat.message.*", func(msg *nats.Msg) {
		// 메시지 파싱
		var chatMsg models.ChatMessage
		if err := json.Unmarshal(msg.Data, &chatMsg); err != nil {
			log.Printf("Failed to unmarshal message: %v", err)
			msg.Nak()
			return
		}

		// ScyllaDB에 저장
		if err := chatRepo.SaveMessage(&chatMsg); err != nil {
			log.Printf("Failed to save message to ScyllaDB: %v", err)
			msg.Nak()
			return
		}

		log.Printf("Saved message %s to event %d", chatMsg.MessageID, chatMsg.EventID)
		msg.Ack()
	}, nats.Durable("chat-worker"), nats.ManualAck())

	if err != nil {
		log.Fatalf("Failed to subscribe: %v", err)
	}
	defer sub.Unsubscribe()

	log.Println("🚀 Chat worker started. Listening for messages...")

	// Graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("👋 Chat worker shutting down...")
}
EOF
```

---

## 🎯 Step 7: 통합 및 테스트

### 7.1 API Server 업데이트 (WebSocket 라우트 추가)
```bash
# backend/cmd/api/main.go에 추가

// main() 함수 내부에 추가

	// ScyllaDB 연결
	scyllaDB, err := db.NewScyllaDB(cfg.Scylla.Hosts, cfg.Scylla.Keyspace)
	if err != nil {
		log.Fatalf("Failed to connect to ScyllaDB: %v", err)
	}
	defer scyllaDB.Close()

	// NATS 연결
	natsClient, err := db.NewNATSClient(cfg.NATS.URL)
	if err != nil {
		log.Fatalf("Failed to connect to NATS: %v", err)
	}
	defer natsClient.Close()

	// NATS Streams 생성
	if err := natsClient.CreateStreams(); err != nil {
		log.Fatalf("Failed to create NATS streams: %v", err)
	}

	// WebSocket Hub
	hub := websocket.NewHub()
	go hub.Run()

	// Repositories
	chatRepo := repositories.NewChatRepository(scyllaDB.Session)

	// Handlers
	wsHandler := handlers.NewWebSocketHandler(hub, natsClient.JS, chatRepo, userRepo)

	// Routes - Protected routes에 추가
	protected.GET("/ws", wsHandler.HandleWebSocket)
```

### 7.2 서버 실행
```bash
cd backend

# Terminal 1: API Server
export $(cat .env | grep -v '^#' | xargs)
go run cmd/api/main.go

# Terminal 2: Chat Worker
go run cmd/worker/main.go
```

### 7.3 WebSocket 테스트 (wscat)
```bash
# wscat 설치
npm install -g wscat

# WebSocket 연결 (ACCESS_TOKEN 필요)
wscat -c "ws://localhost:8080/ws?event_id=1" -H "Authorization: Bearer $ACCESS_TOKEN"

# 메시지 전송
> {"message": "안녕하세요!"}

# 응답 수신 (브로드캐스트)
< {"event_id":1,"created_at":"2025-01-10T...","message_id":"...","sender_id":1,"sender_name":"User_5678","message":"안녕하세요!","message_type":"text","is_deleted":false}
```

### 7.4 ScyllaDB 데이터 확인
```bash
podman exec -it timingle-scylla cqlsh

# CQL 쿼리
USE timingle;
SELECT * FROM chat_messages_by_event WHERE event_id = 1 LIMIT 10;
```

---

## ✅ 완료 체크리스트

- [ ] ScyllaDB 스키마 생성 완료 (6개 테이블)
- [ ] Go에서 ScyllaDB 연결 성공
- [ ] NATS JetStream 연결 성공
- [ ] NATS Streams 생성 완료 (CHAT_MESSAGES, EVENTS)
- [ ] WebSocket Gateway 실행 (`hub.Run()`)
- [ ] Chat Worker 실행 (`go run cmd/worker/main.go`)
- [ ] WebSocket 연결 성공 (`wscat` 테스트)
- [ ] 메시지 송신/수신 동작 확인
- [ ] ScyllaDB에 메시지 저장 확인 (`SELECT * FROM chat_messages_by_event`)
- [ ] 실시간 브로드캐스트 동작 확인 (여러 클라이언트)

---

## 🎯 다음 단계

**Phase 2 완료 후**:
- ➡️ **PHASE_3_FLUTTER.md**: Flutter 앱 구현
- ➡️ **PHASE_4_INTEGRATION.md**: 통합 및 테스트

**Phase 2 결과물**:
- WebSocket 실시간 채팅 시스템
- ScyllaDB 메시지 저장 (Discord-level)
- NATS JetStream 메시지 큐
- 채팅 Worker (비동기 저장)

---

**Phase 2 완료! 🎉 실시간 채팅 시스템 구축 완료!**
