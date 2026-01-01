package services

import (
	"fmt"
	"time"

	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/khchoi-tnh/timingle/internal/repositories"
)

// EventService handles event business logic
type EventService struct {
	eventRepo *repositories.EventRepository
	userRepo  *repositories.UserRepository
}

// NewEventService creates a new event service
func NewEventService(
	eventRepo *repositories.EventRepository,
	userRepo *repositories.UserRepository,
) *EventService {
	return &EventService{
		eventRepo: eventRepo,
		userRepo:  userRepo,
	}
}

// CreateEvent creates a new event
func (s *EventService) CreateEvent(creatorID int64, req *models.CreateEventRequest) (*models.EventResponse, error) {
	// Validate times
	if req.EndTime.Before(req.StartTime) {
		return nil, fmt.Errorf("end time must be after start time")
	}

	// Create event
	event := &models.Event{
		Title:       req.Title,
		Description: req.Description,
		StartTime:   req.StartTime,
		EndTime:     req.EndTime,
		Location:    req.Location,
		CreatorID:   creatorID,
		Status:      models.EventStatusProposed,
	}

	if err := s.eventRepo.Create(event); err != nil {
		return nil, fmt.Errorf("failed to create event: %w", err)
	}

	// Add participants
	if len(req.ParticipantIDs) > 0 {
		for _, participantID := range req.ParticipantIDs {
			if err := s.eventRepo.AddParticipant(event.ID, participantID); err != nil {
				// Log error but continue
				fmt.Printf("Failed to add participant %d: %v\n", participantID, err)
			}
		}
	}

	// Load event with participants
	return s.GetEvent(event.ID)
}

// GetEvent gets an event by ID
func (s *EventService) GetEvent(eventID int64) (*models.EventResponse, error) {
	event, err := s.eventRepo.FindByID(eventID)
	if err != nil {
		return nil, fmt.Errorf("failed to find event: %w", err)
	}

	// Load creator
	creator, err := s.userRepo.FindByID(event.CreatorID)
	if err != nil {
		return nil, fmt.Errorf("failed to find creator: %w", err)
	}

	// Load participants
	participantIDs, err := s.eventRepo.FindParticipants(eventID)
	if err != nil {
		return nil, fmt.Errorf("failed to find participants: %w", err)
	}

	participants, err := s.userRepo.FindByIDs(participantIDs)
	if err != nil {
		return nil, fmt.Errorf("failed to load participants: %w", err)
	}

	// Build response
	eventWithParticipants := &models.EventWithParticipants{
		Event:        event,
		Creator:      creator,
		Participants: participants,
	}

	return eventWithParticipants.ToEventResponse(), nil
}

// UpdateEvent updates an event
func (s *EventService) UpdateEvent(eventID, userID int64, req *models.UpdateEventRequest) (*models.EventResponse, error) {
	// Get existing event
	event, err := s.eventRepo.FindByID(eventID)
	if err != nil {
		return nil, fmt.Errorf("event not found")
	}

	// Check if user is the creator
	if event.CreatorID != userID {
		return nil, fmt.Errorf("only creator can update event")
	}

	// Update fields
	if req.Title != nil {
		event.Title = *req.Title
	}
	if req.Description != nil {
		event.Description = req.Description
	}
	if req.StartTime != nil {
		event.StartTime = *req.StartTime
	}
	if req.EndTime != nil {
		event.EndTime = *req.EndTime
	}
	if req.Location != nil {
		event.Location = req.Location
	}
	if req.Status != nil {
		event.Status = *req.Status
	}

	// Validate times
	if event.EndTime.Before(event.StartTime) {
		return nil, fmt.Errorf("end time must be after start time")
	}

	// Update event
	if err := s.eventRepo.Update(event); err != nil {
		return nil, fmt.Errorf("failed to update event: %w", err)
	}

	// Return updated event
	return s.GetEvent(eventID)
}

// DeleteEvent deletes an event
func (s *EventService) DeleteEvent(eventID, userID int64) error {
	// Get existing event
	event, err := s.eventRepo.FindByID(eventID)
	if err != nil {
		return fmt.Errorf("event not found")
	}

	// Check if user is the creator
	if event.CreatorID != userID {
		return fmt.Errorf("only creator can delete event")
	}

	// Delete event
	return s.eventRepo.Delete(eventID)
}

// GetUserEvents gets all events for a user (created + participating)
func (s *EventService) GetUserEvents(userID int64, status string) ([]*models.EventResponse, error) {
	// Get events created by user
	createdEvents, err := s.eventRepo.FindByCreatorID(userID, status)
	if err != nil {
		return nil, fmt.Errorf("failed to find created events: %w", err)
	}

	// Get events user is participating in
	participatingEvents, err := s.eventRepo.FindByParticipantID(userID, status)
	if err != nil {
		return nil, fmt.Errorf("failed to find participating events: %w", err)
	}

	// Merge events (avoid duplicates)
	eventMap := make(map[int64]*models.Event)
	for _, event := range createdEvents {
		eventMap[event.ID] = event
	}
	for _, event := range participatingEvents {
		if _, exists := eventMap[event.ID]; !exists {
			eventMap[event.ID] = event
		}
	}

	// Convert to responses
	responses := []*models.EventResponse{}
	for _, event := range eventMap {
		response, err := s.GetEvent(event.ID)
		if err != nil {
			// Log error but continue
			fmt.Printf("Failed to load event %d: %v\n", event.ID, err)
			continue
		}
		responses = append(responses, response)
	}

	// Sort by start time (newest first)
	// Simple bubble sort for small datasets
	for i := 0; i < len(responses); i++ {
		for j := i + 1; j < len(responses); j++ {
			if responses[i].StartTime.Before(responses[j].StartTime) {
				responses[i], responses[j] = responses[j], responses[i]
			}
		}
	}

	return responses, nil
}

// AddParticipant adds a participant to an event
func (s *EventService) AddParticipant(eventID, userID, participantID int64) error {
	// Get event
	event, err := s.eventRepo.FindByID(eventID)
	if err != nil {
		return fmt.Errorf("event not found")
	}

	// Check if user is the creator
	if event.CreatorID != userID {
		return fmt.Errorf("only creator can add participants")
	}

	// Check if participant exists
	_, err = s.userRepo.FindByID(participantID)
	if err != nil {
		return fmt.Errorf("participant user not found")
	}

	// Add participant
	return s.eventRepo.AddParticipant(eventID, participantID)
}

// RemoveParticipant removes a participant from an event
func (s *EventService) RemoveParticipant(eventID, userID, participantID int64) error {
	// Get event
	event, err := s.eventRepo.FindByID(eventID)
	if err != nil {
		return fmt.Errorf("event not found")
	}

	// Check if user is the creator or the participant themselves
	if event.CreatorID != userID && participantID != userID {
		return fmt.Errorf("only creator or participant can remove participation")
	}

	// Remove participant
	return s.eventRepo.RemoveParticipant(eventID, participantID)
}

// ConfirmParticipation confirms a user's participation in an event
func (s *EventService) ConfirmParticipation(eventID, userID int64) error {
	// Get event
	_, err := s.eventRepo.FindByID(eventID)
	if err != nil {
		return fmt.Errorf("event not found")
	}

	// Confirm participation
	return s.eventRepo.ConfirmParticipant(eventID, userID)
}

// ConfirmEvent changes event status to CONFIRMED
func (s *EventService) ConfirmEvent(eventID, userID int64) error {
	// Get event
	event, err := s.eventRepo.FindByID(eventID)
	if err != nil {
		return fmt.Errorf("event not found")
	}

	// Check if user is the creator
	if event.CreatorID != userID {
		return fmt.Errorf("only creator can confirm event")
	}

	// Update status
	status := models.EventStatusConfirmed
	event.Status = status
	return s.eventRepo.Update(event)
}

// CancelEvent changes event status to CANCELED
func (s *EventService) CancelEvent(eventID, userID int64) error {
	// Get event
	event, err := s.eventRepo.FindByID(eventID)
	if err != nil {
		return fmt.Errorf("event not found")
	}

	// Check if user is the creator
	if event.CreatorID != userID {
		return fmt.Errorf("only creator can cancel event")
	}

	// Check if event is not already done
	if event.Status == models.EventStatusDone {
		return fmt.Errorf("cannot cancel completed event")
	}

	// Update status
	status := models.EventStatusCanceled
	event.Status = status
	return s.eventRepo.Update(event)
}

// MarkEventDone marks event as done (typically called after end_time)
func (s *EventService) MarkEventDone(eventID, userID int64) error {
	// Get event
	event, err := s.eventRepo.FindByID(eventID)
	if err != nil {
		return fmt.Errorf("event not found")
	}

	// Check if user is the creator
	if event.CreatorID != userID {
		return fmt.Errorf("only creator can mark event as done")
	}

	// Check if event is confirmed and past end time
	if event.Status != models.EventStatusConfirmed {
		return fmt.Errorf("only confirmed events can be marked as done")
	}

	if time.Now().Before(event.EndTime) {
		return fmt.Errorf("event has not ended yet")
	}

	// Update status
	status := models.EventStatusDone
	event.Status = status
	return s.eventRepo.Update(event)
}
