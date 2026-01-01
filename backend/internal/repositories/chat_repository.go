package repositories

import (
	"fmt"
	"time"

	"github.com/gocql/gocql"
	"github.com/khchoi-tnh/timingle/internal/models"
)

// ChatRepository handles chat data operations in ScyllaDB
type ChatRepository struct {
	session *gocql.Session
}

// NewChatRepository creates a new chat repository
func NewChatRepository(session *gocql.Session) *ChatRepository {
	return &ChatRepository{session: session}
}

// SaveMessage saves a chat message to ScyllaDB
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

// GetMessages retrieves chat messages for an event (with pagination)
func (r *ChatRepository) GetMessages(eventID int64, limit int, startTime *time.Time) ([]*models.ChatMessage, error) {
	if limit == 0 {
		limit = 50
	}

	var query string
	var args []interface{}

	if startTime != nil {
		// Pagination: messages before startTime
		query = `
			SELECT event_id, created_at, message_id, sender_id, sender_name, sender_profile_url,
			       message, message_type, attachments, reply_to, edited_at, is_deleted, metadata
			FROM chat_messages_by_event
			WHERE event_id = ? AND created_at < ?
			ORDER BY created_at ASC
			LIMIT ?
		`
		args = []interface{}{eventID, *startTime, limit}
	} else {
		// Latest messages
		query = `
			SELECT event_id, created_at, message_id, sender_id, sender_name, sender_profile_url,
			       message, message_type, attachments, reply_to, edited_at, is_deleted, metadata
			FROM chat_messages_by_event
			WHERE event_id = ?
			ORDER BY created_at ASC
			LIMIT ?
		`
		args = []interface{}{eventID, limit}
	}

	iter := r.session.Query(query, args...).Iter()

	messages := []*models.ChatMessage{}

	for {
		msg := &models.ChatMessage{}
		if !iter.Scan(
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
			break
		}
		messages = append(messages, msg)
	}

	if err := iter.Close(); err != nil {
		return nil, fmt.Errorf("failed to get messages: %w", err)
	}

	return messages, nil
}

// IncrementUnreadCount increments unread message counter
func (r *ChatRepository) IncrementUnreadCount(eventID, userID int64) error {
	query := `UPDATE unread_message_counts SET count = count + 1 WHERE event_id = ? AND user_id = ?`
	return r.session.Query(query, eventID, userID).Exec()
}

// ResetUnreadCount resets unread message counter
func (r *ChatRepository) ResetUnreadCount(eventID, userID int64) error {
	query := `UPDATE unread_message_counts SET count = 0 WHERE event_id = ? AND user_id = ?`
	return r.session.Query(query, eventID, userID).Exec()
}

// SaveEventHistory saves event history entry
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

// GetEventHistory retrieves event history
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

	for {
		entry := &models.EventHistoryEntry{}
		if !iter.Scan(
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
			break
		}
		entries = append(entries, entry)
	}

	if err := iter.Close(); err != nil {
		return nil, fmt.Errorf("failed to get event history: %w", err)
	}

	return entries, nil
}
