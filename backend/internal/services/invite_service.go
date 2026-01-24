package services

import (
	"fmt"
	"time"

	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/khchoi-tnh/timingle/internal/repositories"
)

// InviteService handles invite link business logic
type InviteService struct {
	inviteRepo *repositories.InviteRepository
	eventRepo  *repositories.EventRepository
	userRepo   *repositories.UserRepository
	baseURL    string
}

// NewInviteService creates a new invite service
func NewInviteService(inviteRepo *repositories.InviteRepository, eventRepo *repositories.EventRepository, userRepo *repositories.UserRepository, baseURL string) *InviteService {
	return &InviteService{
		inviteRepo: inviteRepo,
		eventRepo:  eventRepo,
		userRepo:   userRepo,
		baseURL:    baseURL,
	}
}

// CreateInviteLink creates a new invite link for an event
func (s *InviteService) CreateInviteLink(eventID, userID int64, req *models.CreateInviteLinkRequest) (*models.InviteLinkResponse, error) {
	// Check if event exists and user is the creator or participant
	event, err := s.eventRepo.FindByID(eventID)
	if err != nil {
		return nil, fmt.Errorf("event not found")
	}

	// Only creator can create invite links
	if event.CreatorID != userID {
		return nil, fmt.Errorf("only event creator can create invite links")
	}

	// Check event status
	if event.Status == "CANCELED" || event.Status == "DONE" {
		return nil, fmt.Errorf("cannot create invite link for %s event", event.Status)
	}

	// Calculate expiry
	var expiresAt *time.Time
	if req.ExpiresInHours > 0 {
		exp := time.Now().Add(time.Duration(req.ExpiresInHours) * time.Hour)
		expiresAt = &exp
	} else {
		// Default: 7 days
		exp := time.Now().Add(168 * time.Hour)
		expiresAt = &exp
	}

	// Create invite link
	link, err := s.inviteRepo.Create(eventID, userID, expiresAt, req.MaxUses)
	if err != nil {
		return nil, err
	}

	return &models.InviteLinkResponse{
		Code:      link.Code,
		Link:      fmt.Sprintf("%s/invite/%s", s.baseURL, link.Code),
		ExpiresAt: link.ExpiresAt,
		MaxUses:   link.MaxUses,
	}, nil
}

// GetInviteInfo returns information about an invite link
func (s *InviteService) GetInviteInfo(code string, userID int64) (*models.InviteInfoResponse, error) {
	// Find invite link
	link, err := s.inviteRepo.FindByCode(code)
	if err != nil {
		return nil, err
	}
	if link == nil {
		return nil, fmt.Errorf("invite link not found")
	}

	// Check if link is valid
	if err := s.validateLink(link); err != nil {
		return nil, err
	}

	// Get event
	event, err := s.eventRepo.FindByID(link.EventID)
	if err != nil {
		return nil, fmt.Errorf("event not found")
	}

	// Get creator info
	creator, err := s.userRepo.FindByID(event.CreatorID)
	if err != nil {
		return nil, fmt.Errorf("creator not found")
	}

	// Check if user is already a participant
	isParticipant, err := s.inviteRepo.IsUserParticipant(link.EventID, userID)
	if err != nil {
		return nil, err
	}

	action := "confirm"
	if isParticipant {
		action = "already_joined"
	}

	return &models.InviteInfoResponse{
		Event: &models.EventSummary{
			ID:        event.ID,
			Title:     event.Title,
			StartTime: event.StartTime,
			Location:  event.Location,
		},
		Creator: &models.UserSummary{
			ID:   creator.ID,
			Name: creator.Name,
		},
		Action: action,
	}, nil
}

// JoinViaInvite joins an event using an invite link
func (s *InviteService) JoinViaInvite(code string, userID int64) (*models.JoinEventResponse, error) {
	// Find invite link
	link, err := s.inviteRepo.FindByCode(code)
	if err != nil {
		return nil, err
	}
	if link == nil {
		return nil, fmt.Errorf("invite link not found")
	}

	// Validate link
	if err := s.validateLink(link); err != nil {
		return nil, err
	}

	// Check if already a participant
	isParticipant, err := s.inviteRepo.IsUserParticipant(link.EventID, userID)
	if err != nil {
		return nil, err
	}
	if isParticipant {
		return nil, fmt.Errorf("you are already a participant of this event")
	}

	// Add as participant
	err = s.inviteRepo.AddParticipantWithDetails(link.EventID, userID, link.CreatedBy, models.InviteMethodLink)
	if err != nil {
		return nil, err
	}

	// Increment use count
	if err := s.inviteRepo.IncrementUseCount(link.ID); err != nil {
		// Log but don't fail
		fmt.Printf("Warning: failed to increment use count: %v\n", err)
	}

	return &models.JoinEventResponse{
		Message: "이벤트에 참가했습니다",
		EventID: link.EventID,
	}, nil
}

// AcceptInvite accepts an event invitation
func (s *InviteService) AcceptInvite(eventID, userID int64) error {
	// Check if user is a participant
	isParticipant, err := s.inviteRepo.IsUserParticipant(eventID, userID)
	if err != nil {
		return err
	}
	if !isParticipant {
		return fmt.Errorf("you are not invited to this event")
	}

	return s.inviteRepo.UpdateParticipantStatus(eventID, userID, models.ParticipantStatusAccepted)
}

// DeclineInvite declines an event invitation
func (s *InviteService) DeclineInvite(eventID, userID int64) error {
	// Check if user is a participant
	isParticipant, err := s.inviteRepo.IsUserParticipant(eventID, userID)
	if err != nil {
		return err
	}
	if !isParticipant {
		return fmt.Errorf("you are not invited to this event")
	}

	return s.inviteRepo.UpdateParticipantStatus(eventID, userID, models.ParticipantStatusDeclined)
}

// validateLink checks if an invite link is valid
func (s *InviteService) validateLink(link *models.InviteLink) error {
	if !link.IsActive {
		return fmt.Errorf("invite link is no longer active")
	}

	if link.ExpiresAt != nil && time.Now().After(*link.ExpiresAt) {
		return fmt.Errorf("invite link has expired")
	}

	if link.MaxUses > 0 && link.UseCount >= link.MaxUses {
		return fmt.Errorf("invite link has reached maximum uses")
	}

	return nil
}

// DeactivateLink deactivates an invite link
func (s *InviteService) DeactivateLink(linkID, userID int64) error {
	// For now, just deactivate - could add ownership check
	return s.inviteRepo.Deactivate(linkID)
}
