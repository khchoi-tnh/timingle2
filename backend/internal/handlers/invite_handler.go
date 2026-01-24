package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/khchoi-tnh/timingle/internal/services"
)

// InviteHandler handles invite link HTTP requests
type InviteHandler struct {
	inviteService *services.InviteService
}

// NewInviteHandler creates a new invite handler
func NewInviteHandler(inviteService *services.InviteService) *InviteHandler {
	return &InviteHandler{
		inviteService: inviteService,
	}
}

// CreateInviteLink creates an invite link for an event
// POST /api/v1/events/:id/invite-link
func (h *InviteHandler) CreateInviteLink(c *gin.Context) {
	userID, _ := c.Get("userID")

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	var req models.CreateInviteLinkRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		// Use default values if no body provided
		req = models.CreateInviteLinkRequest{
			ExpiresInHours: 168, // 7 days
			MaxUses:        0,   // unlimited
		}
	}

	response, err := h.inviteService.CreateInviteLink(eventID, userID.(int64), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GetInviteInfo returns information about an invite link
// GET /api/v1/invite/:code
func (h *InviteHandler) GetInviteInfo(c *gin.Context) {
	userID, _ := c.Get("userID")
	code := c.Param("code")

	if code == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invite code is required"})
		return
	}

	response, err := h.inviteService.GetInviteInfo(code, userID.(int64))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// JoinViaInvite joins an event using an invite link
// POST /api/v1/invite/:code/join
func (h *InviteHandler) JoinViaInvite(c *gin.Context) {
	userID, _ := c.Get("userID")
	code := c.Param("code")

	if code == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invite code is required"})
		return
	}

	response, err := h.inviteService.JoinViaInvite(code, userID.(int64))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// AcceptInvite accepts an event invitation
// POST /api/v1/events/:id/accept
func (h *InviteHandler) AcceptInvite(c *gin.Context) {
	userID, _ := c.Get("userID")

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	err = h.inviteService.AcceptInvite(eventID, userID.(int64))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "초대를 수락했습니다"})
}

// DeclineInvite declines an event invitation
// POST /api/v1/events/:id/decline
func (h *InviteHandler) DeclineInvite(c *gin.Context) {
	userID, _ := c.Get("userID")

	eventID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
		return
	}

	err = h.inviteService.DeclineInvite(eventID, userID.(int64))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "초대를 거절했습니다"})
}
