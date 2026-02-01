package services

import (
	"context"
	"fmt"
	"time"

	"golang.org/x/oauth2"
	"google.golang.org/api/calendar/v3"
	"google.golang.org/api/option"

	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/khchoi-tnh/timingle/internal/repositories"
)

// CalendarService handles Google Calendar integration
type CalendarService struct {
	authService *AuthService
	eventRepo   *repositories.EventRepository
	oauthRepo   *repositories.OAuthRepository
}

// NewCalendarService creates a new calendar service
func NewCalendarService(
	authService *AuthService,
	eventRepo *repositories.EventRepository,
	oauthRepo *repositories.OAuthRepository,
) *CalendarService {
	return &CalendarService{
		authService: authService,
		eventRepo:   eventRepo,
		oauthRepo:   oauthRepo,
	}
}

// CalendarEvent represents a Google Calendar event for API responses
type CalendarEvent struct {
	ID          string    `json:"id"`
	Summary     string    `json:"summary"`
	Description string    `json:"description,omitempty"`
	Location    string    `json:"location,omitempty"`
	StartTime   time.Time `json:"start_time"`
	EndTime     time.Time `json:"end_time"`
	HtmlLink    string    `json:"html_link,omitempty"`
}

// getCalendarService creates a Google Calendar API client for a user
func (s *CalendarService) getCalendarService(ctx context.Context, userID int64) (*calendar.Service, error) {
	accessToken, err := s.authService.GetValidAccessToken(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get access token: %w", err)
	}

	// Create OAuth2 token source
	token := &oauth2.Token{
		AccessToken: accessToken,
		TokenType:   "Bearer",
	}
	tokenSource := oauth2.StaticTokenSource(token)

	// Create calendar service
	calendarService, err := calendar.NewService(ctx, option.WithTokenSource(tokenSource))
	if err != nil {
		return nil, fmt.Errorf("failed to create calendar service: %w", err)
	}

	return calendarService, nil
}

// GetCalendarEvents retrieves events from user's Google Calendar
func (s *CalendarService) GetCalendarEvents(ctx context.Context, userID int64, startTime, endTime time.Time) ([]*CalendarEvent, error) {
	calendarService, err := s.getCalendarService(ctx, userID)
	if err != nil {
		return nil, err
	}

	events, err := calendarService.Events.List("primary").
		TimeMin(startTime.Format(time.RFC3339)).
		TimeMax(endTime.Format(time.RFC3339)).
		SingleEvents(true).
		OrderBy("startTime").
		MaxResults(100).
		Do()
	if err != nil {
		return nil, fmt.Errorf("failed to get calendar events: %w", err)
	}

	result := make([]*CalendarEvent, 0, len(events.Items))
	for _, item := range events.Items {
		event := &CalendarEvent{
			ID:          item.Id,
			Summary:     item.Summary,
			Description: item.Description,
			Location:    item.Location,
			HtmlLink:    item.HtmlLink,
		}

		// Parse start time
		if item.Start != nil {
			if item.Start.DateTime != "" {
				t, _ := time.Parse(time.RFC3339, item.Start.DateTime)
				event.StartTime = t
			} else if item.Start.Date != "" {
				t, _ := time.Parse("2006-01-02", item.Start.Date)
				event.StartTime = t
			}
		}

		// Parse end time
		if item.End != nil {
			if item.End.DateTime != "" {
				t, _ := time.Parse(time.RFC3339, item.End.DateTime)
				event.EndTime = t
			} else if item.End.Date != "" {
				t, _ := time.Parse("2006-01-02", item.End.Date)
				event.EndTime = t
			}
		}

		result = append(result, event)
	}

	return result, nil
}

// CreateCalendarEvent creates a new event in user's Google Calendar
func (s *CalendarService) CreateCalendarEvent(ctx context.Context, userID int64, event *models.Event) (*CalendarEvent, error) {
	calendarService, err := s.getCalendarService(ctx, userID)
	if err != nil {
		return nil, err
	}

	description := ""
	if event.Description != nil {
		description = *event.Description
	}

	location := ""
	if event.Location != nil {
		location = *event.Location
	}

	calEvent := &calendar.Event{
		Summary:     event.Title,
		Description: description,
		Location:    location,
		Start: &calendar.EventDateTime{
			DateTime: event.StartTime.Format(time.RFC3339),
			TimeZone: "Asia/Seoul",
		},
		End: &calendar.EventDateTime{
			DateTime: event.EndTime.Format(time.RFC3339),
			TimeZone: "Asia/Seoul",
		},
	}

	createdEvent, err := calendarService.Events.Insert("primary", calEvent).Do()
	if err != nil {
		return nil, fmt.Errorf("failed to create calendar event: %w", err)
	}

	startTime, _ := time.Parse(time.RFC3339, createdEvent.Start.DateTime)
	endTime, _ := time.Parse(time.RFC3339, createdEvent.End.DateTime)

	return &CalendarEvent{
		ID:          createdEvent.Id,
		Summary:     createdEvent.Summary,
		Description: createdEvent.Description,
		Location:    createdEvent.Location,
		StartTime:   startTime,
		EndTime:     endTime,
		HtmlLink:    createdEvent.HtmlLink,
	}, nil
}

// UpdateCalendarEvent updates an existing event in user's Google Calendar
func (s *CalendarService) UpdateCalendarEvent(ctx context.Context, userID int64, calendarEventID string, event *models.Event) (*CalendarEvent, error) {
	calendarService, err := s.getCalendarService(ctx, userID)
	if err != nil {
		return nil, err
	}

	description := ""
	if event.Description != nil {
		description = *event.Description
	}

	location := ""
	if event.Location != nil {
		location = *event.Location
	}

	calEvent := &calendar.Event{
		Summary:     event.Title,
		Description: description,
		Location:    location,
		Start: &calendar.EventDateTime{
			DateTime: event.StartTime.Format(time.RFC3339),
			TimeZone: "Asia/Seoul",
		},
		End: &calendar.EventDateTime{
			DateTime: event.EndTime.Format(time.RFC3339),
			TimeZone: "Asia/Seoul",
		},
	}

	updatedEvent, err := calendarService.Events.Update("primary", calendarEventID, calEvent).Do()
	if err != nil {
		return nil, fmt.Errorf("failed to update calendar event: %w", err)
	}

	startTime, _ := time.Parse(time.RFC3339, updatedEvent.Start.DateTime)
	endTime, _ := time.Parse(time.RFC3339, updatedEvent.End.DateTime)

	return &CalendarEvent{
		ID:          updatedEvent.Id,
		Summary:     updatedEvent.Summary,
		Description: updatedEvent.Description,
		Location:    updatedEvent.Location,
		StartTime:   startTime,
		EndTime:     endTime,
		HtmlLink:    updatedEvent.HtmlLink,
	}, nil
}

// DeleteCalendarEvent deletes an event from user's Google Calendar
func (s *CalendarService) DeleteCalendarEvent(ctx context.Context, userID int64, calendarEventID string) error {
	calendarService, err := s.getCalendarService(ctx, userID)
	if err != nil {
		return err
	}

	err = calendarService.Events.Delete("primary", calendarEventID).Do()
	if err != nil {
		return fmt.Errorf("failed to delete calendar event: %w", err)
	}

	return nil
}

// SyncEventToCalendar syncs a timingle event to user's Google Calendar
// Returns the Google Calendar event ID
func (s *CalendarService) SyncEventToCalendar(ctx context.Context, userID int64, eventID int64) (*CalendarEvent, error) {
	// Get the timingle event
	event, err := s.eventRepo.FindByID(eventID)
	if err != nil {
		return nil, fmt.Errorf("failed to find event: %w", err)
	}
	if event == nil {
		return nil, fmt.Errorf("event not found")
	}

	// Check if event already has a Google Calendar ID
	if event.GoogleCalendarID != nil && *event.GoogleCalendarID != "" {
		// Update existing calendar event
		return s.UpdateCalendarEvent(ctx, userID, *event.GoogleCalendarID, event)
	}

	// Create new calendar event
	calEvent, err := s.CreateCalendarEvent(ctx, userID, event)
	if err != nil {
		return nil, err
	}

	// Save the Google Calendar ID to the event
	err = s.eventRepo.UpdateGoogleCalendarID(eventID, calEvent.ID)
	if err != nil {
		// Log but don't fail - the event was created successfully
		fmt.Printf("Warning: failed to save Google Calendar ID: %v\n", err)
	}

	return calEvent, nil
}

// HasCalendarAccess checks if a user has Google Calendar access
func (s *CalendarService) HasCalendarAccess(ctx context.Context, userID int64) (bool, error) {
	oauthAccount, err := s.oauthRepo.FindByUserIDAndProvider(userID, models.OAuthProviderGoogle)
	if err != nil {
		return false, err
	}
	if oauthAccount == nil {
		return false, nil
	}
	return oauthAccount.HasCalendarScope(), nil
}
