package models

import (
	"time"
)

// EventStatus represents event status types
type EventStatus string

const (
	EventStatusProposed  EventStatus = "PROPOSED"
	EventStatusConfirmed EventStatus = "CONFIRMED"
	EventStatusCanceled  EventStatus = "CANCELED"
	EventStatusDone      EventStatus = "DONE"
)

// Event represents an event/appointment in the system
type Event struct {
	ID               int64       `json:"id" db:"id"`
	Title            string      `json:"title" db:"title"`
	Description      *string     `json:"description,omitempty" db:"description"`
	StartTime        time.Time   `json:"start_time" db:"start_time"`
	EndTime          time.Time   `json:"end_time" db:"end_time"`
	Location         *string     `json:"location,omitempty" db:"location"`
	CreatorID        int64       `json:"creator_id" db:"creator_id"`
	Status           EventStatus `json:"status" db:"status"`
	GoogleCalendarID *string     `json:"google_calendar_id,omitempty" db:"google_calendar_id"` // Google Calendar 연동 ID
	CreatedAt        time.Time   `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time   `json:"updated_at" db:"updated_at"`
}

// EventParticipant represents a participant in an event
type EventParticipant struct {
	EventID     int64      `json:"event_id" db:"event_id"`
	UserID      int64      `json:"user_id" db:"user_id"`
	Confirmed   bool       `json:"confirmed" db:"confirmed"`
	ConfirmedAt *time.Time `json:"confirmed_at,omitempty" db:"confirmed_at"`
}

// CreateEventRequest represents event creation request
type CreateEventRequest struct {
	Title         string    `json:"title" binding:"required"`
	Description   *string   `json:"description,omitempty"`
	StartTime     time.Time `json:"start_time" binding:"required"`
	EndTime       time.Time `json:"end_time" binding:"required"`
	Location      *string   `json:"location,omitempty"`
	ParticipantIDs []int64  `json:"participant_ids,omitempty"`
}

// UpdateEventRequest represents event update request
type UpdateEventRequest struct {
	Title       *string     `json:"title,omitempty"`
	Description *string     `json:"description,omitempty"`
	StartTime   *time.Time  `json:"start_time,omitempty"`
	EndTime     *time.Time  `json:"end_time,omitempty"`
	Location    *string     `json:"location,omitempty"`
	Status      *EventStatus `json:"status,omitempty"`
}

// EventResponse represents event data in API responses
type EventResponse struct {
	ID           int64              `json:"id"`
	Title        string             `json:"title"`
	Description  *string            `json:"description,omitempty"`
	StartTime    time.Time          `json:"start_time"`
	EndTime      time.Time          `json:"end_time"`
	Location     *string            `json:"location,omitempty"`
	Creator      *UserResponse      `json:"creator"`
	Participants []*UserResponse    `json:"participants,omitempty"`
	Status       EventStatus        `json:"status"`
	CreatedAt    time.Time          `json:"created_at"`
	UpdatedAt    time.Time          `json:"updated_at"`
}

// EventWithParticipants represents an event with its participants
type EventWithParticipants struct {
	Event        *Event
	Creator      *User
	Participants []*User
}

// ToEventResponse converts EventWithParticipants to EventResponse
func (e *EventWithParticipants) ToEventResponse() *EventResponse {
	response := &EventResponse{
		ID:          e.Event.ID,
		Title:       e.Event.Title,
		Description: e.Event.Description,
		StartTime:   e.Event.StartTime,
		EndTime:     e.Event.EndTime,
		Location:    e.Event.Location,
		Status:      e.Event.Status,
		CreatedAt:   e.Event.CreatedAt,
		UpdatedAt:   e.Event.UpdatedAt,
	}

	if e.Creator != nil {
		response.Creator = e.Creator.ToUserResponse()
	}

	if len(e.Participants) > 0 {
		response.Participants = make([]*UserResponse, len(e.Participants))
		for i, participant := range e.Participants {
			response.Participants[i] = participant.ToUserResponse()
		}
	}

	return response
}
