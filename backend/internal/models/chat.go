package models

import (
	"time"

	"github.com/google/uuid"
)

// ChatMessage represents a chat message in ScyllaDB
type ChatMessage struct {
	EventID          int64             `json:"event_id"`
	CreatedAt        time.Time         `json:"created_at"`
	MessageID        uuid.UUID         `json:"message_id"`
	SenderID         int64             `json:"sender_id"`
	SenderName       string            `json:"sender_name"`
	SenderProfileURL string            `json:"sender_profile_url,omitempty"`
	Message          string            `json:"message"`
	MessageType      string            `json:"message_type"` // text, system, image
	Attachments      []string          `json:"attachments,omitempty"`
	ReplyTo          *uuid.UUID        `json:"reply_to,omitempty"`
	EditedAt         *time.Time        `json:"edited_at,omitempty"`
	IsDeleted        bool              `json:"is_deleted"`
	Metadata         map[string]string `json:"metadata,omitempty"`
}

// EventHistoryEntry represents an event change log in ScyllaDB
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

// SendMessageRequest represents a request to send a chat message
type SendMessageRequest struct {
	EventID     int64      `json:"event_id" binding:"required"`
	Message     string     `json:"message" binding:"required"`
	MessageType string     `json:"message_type"` // text, system, image
	ReplyTo     *uuid.UUID `json:"reply_to,omitempty"`
}

// GetMessagesRequest represents a request to retrieve chat messages
type GetMessagesRequest struct {
	EventID   int64      `json:"event_id" binding:"required"`
	Limit     int        `json:"limit"`      // default 50
	StartTime *time.Time `json:"start_time"` // for pagination
}

// WSMessage represents a WebSocket message format
type WSMessage struct {
	Type    string      `json:"type"` // "message", "typing", "system"
	Message string      `json:"message,omitempty"`
	ReplyTo *uuid.UUID  `json:"reply_to,omitempty"`
}
