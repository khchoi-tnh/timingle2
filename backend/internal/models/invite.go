package models

import "time"

// InviteLink represents an event invite link
type InviteLink struct {
	ID        int64      `json:"id"`
	EventID   int64      `json:"event_id"`
	Code      string     `json:"code"`
	CreatedBy int64      `json:"created_by"`
	ExpiresAt *time.Time `json:"expires_at,omitempty"`
	MaxUses   int        `json:"max_uses"`
	UseCount  int        `json:"use_count"`
	IsActive  bool       `json:"is_active"`
	CreatedAt time.Time  `json:"created_at"`
}

// CreateInviteLinkRequest is the request for creating an invite link
type CreateInviteLinkRequest struct {
	ExpiresInHours int `json:"expires_in_hours"` // 0 = no expiry
	MaxUses        int `json:"max_uses"`         // 0 = unlimited
}

// InviteLinkResponse is the response for invite link creation
type InviteLinkResponse struct {
	Code      string     `json:"code"`
	Link      string     `json:"link"`
	ExpiresAt *time.Time `json:"expires_at,omitempty"`
	MaxUses   int        `json:"max_uses"`
}

// InviteInfoResponse is the response when accessing an invite link
type InviteInfoResponse struct {
	Event   *EventSummary `json:"event"`
	Creator *UserSummary  `json:"creator"`
	Action  string        `json:"action"` // "confirm" or "already_joined"
}

// EventSummary is a summary of event info for invites
type EventSummary struct {
	ID        int64      `json:"id"`
	Title     string     `json:"title"`
	StartTime *time.Time `json:"start_time,omitempty"`
	Location  string     `json:"location,omitempty"`
}

// UserSummary is a summary of user info
type UserSummary struct {
	ID   int64  `json:"id"`
	Name string `json:"name"`
}

// JoinEventResponse is the response when joining via invite link
type JoinEventResponse struct {
	Message string `json:"message"`
	EventID int64  `json:"event_id"`
}

// ParticipantStatus constants
const (
	ParticipantStatusPending  = "PENDING"
	ParticipantStatusAccepted = "ACCEPTED"
	ParticipantStatusDeclined = "DECLINED"
)

// InviteMethod constants
const (
	InviteMethodFriend  = "FRIEND"
	InviteMethodLink    = "LINK"
	InviteMethodQR      = "QR"
	InviteMethodCreator = "CREATOR"
)
