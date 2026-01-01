package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/khchoi-tnh/timingle/internal/services"
)

// EventHandler handles event HTTP requests
type EventHandler struct {
	eventService *services.EventService
}

// NewEventHandler creates a new event handler
func NewEventHandler(eventService *services.EventService) *EventHandler {
	return &EventHandler{
		eventService: eventService,
	}
}

// CreateEvent handles event creation
// POST /api/v1/events
func (h *EventHandler) CreateEvent(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req models.CreateEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := h.eventService.CreateEvent(userID.(int64), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, response)
}

// GetEvent handles getting a single event
// GET /api/v1/events/:id
func (h *EventHandler) GetEvent(c *gin.Context) {
	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	response, err := h.eventService.GetEvent(eventID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// UpdateEvent handles event update
// PUT /api/v1/events/:id
func (h *EventHandler) UpdateEvent(c *gin.Context) {
	userID, _ := c.Get("userID")

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	var req models.UpdateEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := h.eventService.UpdateEvent(eventID, userID.(int64), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// DeleteEvent handles event deletion
// DELETE /api/v1/events/:id
func (h *EventHandler) DeleteEvent(c *gin.Context) {
	userID, _ := c.Get("userID")

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	err = h.eventService.DeleteEvent(eventID, userID.(int64))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "event deleted successfully"})
}

// GetUserEvents handles getting all events for current user
// GET /api/v1/events
func (h *EventHandler) GetUserEvents(c *gin.Context) {
	userID, _ := c.Get("userID")
	status := c.Query("status") // optional filter

	response, err := h.eventService.GetUserEvents(userID.(int64), status)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// AddParticipant handles adding a participant to event
// POST /api/v1/events/:id/participants
func (h *EventHandler) AddParticipant(c *gin.Context) {
	userID, _ := c.Get("userID")

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	var req struct {
		ParticipantID int64 `json:"participant_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.eventService.AddParticipant(eventID, userID.(int64), req.ParticipantID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "participant added successfully"})
}

// RemoveParticipant handles removing a participant from event
// DELETE /api/v1/events/:id/participants/:participant_id
func (h *EventHandler) RemoveParticipant(c *gin.Context) {
	userID, _ := c.Get("userID")

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	participantID, err := strconv.ParseInt(c.Param("participant_id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid participant ID"})
		return
	}

	err = h.eventService.RemoveParticipant(eventID, userID.(int64), participantID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "participant removed successfully"})
}

// ConfirmParticipation handles confirming user's participation
// POST /api/v1/events/:id/confirm-participation
func (h *EventHandler) ConfirmParticipation(c *gin.Context) {
	userID, _ := c.Get("userID")

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	err = h.eventService.ConfirmParticipation(eventID, userID.(int64))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "participation confirmed"})
}

// ConfirmEvent handles confirming an event
// POST /api/v1/events/:id/confirm
func (h *EventHandler) ConfirmEvent(c *gin.Context) {
	userID, _ := c.Get("userID")

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	err = h.eventService.ConfirmEvent(eventID, userID.(int64))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "event confirmed"})
}

// CancelEvent handles canceling an event
// POST /api/v1/events/:id/cancel
func (h *EventHandler) CancelEvent(c *gin.Context) {
	userID, _ := c.Get("userID")

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	err = h.eventService.CancelEvent(eventID, userID.(int64))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "event canceled"})
}

// MarkEventDone handles marking an event as done
// POST /api/v1/events/:id/done
func (h *EventHandler) MarkEventDone(c *gin.Context) {
	userID, _ := c.Get("userID")

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	err = h.eventService.MarkEventDone(eventID, userID.(int64))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "event marked as done"})
}
