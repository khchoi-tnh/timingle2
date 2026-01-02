package services

import (
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/nats-io/nats.go"
	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/khchoi-tnh/timingle/internal/repositories"
	ws "github.com/khchoi-tnh/timingle/internal/websocket"
)

// ChatService handles chat business logic
type ChatService struct {
	chatRepo     *repositories.ChatRepository
	userRepo     *repositories.UserRepository
	eventService *EventService
	hub          *ws.Hub
	nats         nats.JetStreamContext
}

// NewChatService creates a new chat service
func NewChatService(
	chatRepo *repositories.ChatRepository,
	userRepo *repositories.UserRepository,
	eventService *EventService,
	hub *ws.Hub,
	nats nats.JetStreamContext,
) *ChatService {
	return &ChatService{
		chatRepo:     chatRepo,
		userRepo:     userRepo,
		eventService: eventService,
		hub:          hub,
		nats:         nats,
	}
}

// VerifyEventAccess checks if a user has access to an event's chat
func (s *ChatService) VerifyEventAccess(eventID, userID int64) error {
	isMember, err := s.eventService.IsUserEventMember(eventID, userID)
	if err != nil {
		return fmt.Errorf("failed to verify event access: %w", err)
	}

	if !isMember {
		return fmt.Errorf("user is not a member of this event")
	}

	return nil
}

// SendMessage handles sending a chat message
func (s *ChatService) SendMessage(userID, eventID int64, wsMsg *models.WSMessage) error {
	// Get user info
	user, err := s.userRepo.FindByID(userID)
	if err != nil {
		return fmt.Errorf("user not found: %w", err)
	}

	// Build chat message
	profileURL := ""
	if user.ProfileImageURL != nil {
		profileURL = *user.ProfileImageURL
	}

	name := "Unknown"
	if user.Name != nil {
		name = *user.Name
	}

	msg := &models.ChatMessage{
		EventID:          eventID,
		CreatedAt:        time.Now().UTC(),
		MessageID:        uuid.New(),
		SenderID:         userID,
		SenderName:       name,
		SenderProfileURL: profileURL,
		Message:          wsMsg.Message,
		MessageType:      "text",
		ReplyTo:          wsMsg.ReplyTo,
		IsDeleted:        false,
	}

	// Publish to NATS (Worker will save to ScyllaDB)
	msgBytes, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	subject := "chat.message." + strconv.FormatInt(eventID, 10)
	if _, err := s.nats.Publish(subject, msgBytes); err != nil {
		return fmt.Errorf("failed to publish message to NATS: %w", err)
	}

	// Immediate broadcast (real-time delivery)
	s.hub.BroadcastToEvent(eventID, msgBytes)

	return nil
}

// GetMessages retrieves chat messages for an event
func (s *ChatService) GetMessages(eventID int64, limit int, before *time.Time) ([]*models.ChatMessage, error) {
	messages, err := s.chatRepo.GetMessages(eventID, limit, before)
	if err != nil {
		return nil, fmt.Errorf("failed to get messages: %w", err)
	}

	return messages, nil
}
