package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/khchoi-tnh/timingle/internal/services"
	ws "github.com/khchoi-tnh/timingle/internal/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// TODO: Production - validate origin against allowed domains
		return true
	},
}

// WebSocketHandler handles WebSocket connections
type WebSocketHandler struct {
	hub         *ws.Hub
	chatService *services.ChatService
}

// NewWebSocketHandler creates a new WebSocket handler
func NewWebSocketHandler(
	hub *ws.Hub,
	chatService *services.ChatService,
) *WebSocketHandler {
	return &WebSocketHandler{
		hub:         hub,
		chatService: chatService,
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

	// Verify user is a member (creator or participant) of the event
	if err := h.chatService.VerifyEventAccess(eventID, userID.(int64)); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a member of this event"})
		return
	}

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

	// Delegate to ChatService
	if err := h.chatService.SendMessage(userID, eventID, &wsMsg); err != nil {
		log.Printf("Failed to send message: %v", err)
		return
	}
}

// GetMessages handles retrieving chat messages
// GET /api/v1/events/:id/messages
func (h *WebSocketHandler) GetMessages(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	// Verify user has access to this event's messages
	if err := h.chatService.VerifyEventAccess(eventID, userID.(int64)); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a member of this event"})
		return
	}

	limitStr := c.DefaultQuery("limit", "50")
	limit, _ := strconv.Atoi(limitStr)

	messages, err := h.chatService.GetMessages(eventID, limit, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get messages"})
		return
	}

	c.JSON(http.StatusOK, messages)
}
