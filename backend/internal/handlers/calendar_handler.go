package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/khchoi-tnh/timingle/internal/services"
)

// CalendarHandler handles Google Calendar HTTP requests
type CalendarHandler struct {
	calendarService *services.CalendarService
}

// NewCalendarHandler creates a new calendar handler
func NewCalendarHandler(calendarService *services.CalendarService) *CalendarHandler {
	return &CalendarHandler{
		calendarService: calendarService,
	}
}

// GetCalendarEventsRequest represents the request for getting calendar events
type GetCalendarEventsRequest struct {
	StartTime string `form:"start_time"` // RFC3339 format
	EndTime   string `form:"end_time"`   // RFC3339 format
}

// GetCalendarEvents returns events from user's Google Calendar
// GET /api/v1/calendar/events?start_time=2024-01-01T00:00:00Z&end_time=2024-01-31T23:59:59Z
func (h *CalendarHandler) GetCalendarEvents(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	var req GetCalendarEventsRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Default to current month if not specified
	var startTime, endTime time.Time
	var err error

	if req.StartTime != "" {
		startTime, err = time.Parse(time.RFC3339, req.StartTime)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid start_time format, use RFC3339"})
			return
		}
	} else {
		now := time.Now()
		startTime = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
	}

	if req.EndTime != "" {
		endTime, err = time.Parse(time.RFC3339, req.EndTime)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid end_time format, use RFC3339"})
			return
		}
	} else {
		endTime = startTime.AddDate(0, 1, 0).Add(-time.Second) // End of current month
	}

	events, err := h.calendarService.GetCalendarEvents(c.Request.Context(), userID.(int64), startTime, endTime)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"events":     events,
		"start_time": startTime,
		"end_time":   endTime,
		"count":      len(events),
	})
}

// SyncEventToCalendar syncs a single timingle event to Google Calendar
// POST /api/v1/calendar/sync/:event_id
func (h *CalendarHandler) SyncEventToCalendar(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	eventIDStr := c.Param("event_id")
	eventID, err := strconv.ParseInt(eventIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event_id"})
		return
	}

	calEvent, err := h.calendarService.SyncEventToCalendar(c.Request.Context(), userID.(int64), eventID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":        "event synced to Google Calendar",
		"calendar_event": calEvent,
	})
}

// CheckCalendarAccess checks if user has Google Calendar access
// GET /api/v1/calendar/status
func (h *CalendarHandler) CheckCalendarAccess(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	hasAccess, err := h.calendarService.HasCalendarAccess(c.Request.Context(), userID.(int64))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"has_calendar_access": hasAccess,
	})
}
