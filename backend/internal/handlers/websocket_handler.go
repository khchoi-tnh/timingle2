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
	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/khchoi-tnh/timingle/internal/repositories"
	ws "github.com/khchoi-tnh/timingle/internal/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Production: validate origin
	},
}

// WebSocketHandler handles WebSocket connections
type WebSocketHandler struct {
	hub      *ws.Hub
	nats     nats.JetStreamContext
	chatRepo *repositories.ChatRepository
	userRepo *repositories.UserRepository
}

// NewWebSocketHandler creates a new WebSocket handler
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

// HandleWebSocket handles WebSocket connection
// GET /ws?event_id=1
func (h *WebSocketHandler) HandleWebSocket(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	eventIDStr := c.Query("event_id")
	eventID, err := strconv.ParseInt(eventIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event_id"})
		return
	}

	// TODO: Verify user is participant of the event

	// Upgrade to WebSocket
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket upgrade failed: %v", err)
		return
	}

	client := ws.NewClient(h.hub, conn, userID.(int64), eventID)

	// Register client
	h.hub.RegisterClient(client)

	// Handle incoming messages
	go client.ReadPump(func(message []byte) {
		h.handleIncomingMessage(userID.(int64), eventID, message)
	})

	// Send outgoing messages
	go client.WritePump()
}

func (h *WebSocketHandler) handleIncomingMessage(userID, eventID int64, data []byte) {
	var wsMsg models.WSMessage
	if err := json.Unmarshal(data, &wsMsg); err != nil {
		log.Printf("Failed to parse message: %v", err)
		return
	}

	// Get user info
	user, err := h.userRepo.FindByID(userID)
	if err != nil {
		log.Printf("User not found: %v", err)
		return
	}

	// Create chat message
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
	msgBytes, _ := json.Marshal(msg)
	subject := "chat.message." + strconv.FormatInt(eventID, 10)
	if _, err := h.nats.Publish(subject, msgBytes); err != nil {
		log.Printf("Failed to publish message to NATS: %v", err)
		return
	}

	// Immediate broadcast (real-time delivery)
	h.hub.BroadcastToEvent(eventID, msgBytes)
}

// GetMessages handles retrieving chat messages
// GET /api/v1/events/:id/messages
func (h *WebSocketHandler) GetMessages(c *gin.Context) {
	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	limitStr := c.DefaultQuery("limit", "50")
	limit, _ := strconv.Atoi(limitStr)

	messages, err := h.chatRepo.GetMessages(eventID, limit, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, messages)
}
