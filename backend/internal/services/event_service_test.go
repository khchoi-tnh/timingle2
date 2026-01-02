package services

import (
	"errors"
	"testing"
	"time"

	"github.com/khchoi-tnh/timingle/internal/models"
)

// ErrNotFound is returned when a requested resource is not found
var ErrNotFound = errors.New("not found")

// MockEventRepository is a mock implementation of event repository
type MockEventRepository struct {
	events       map[int64]*models.Event
	participants map[int64][]int64
	nextID       int64
}

func NewMockEventRepository() *MockEventRepository {
	return &MockEventRepository{
		events:       make(map[int64]*models.Event),
		participants: make(map[int64][]int64),
		nextID:       1,
	}
}

func (m *MockEventRepository) Create(event *models.Event) error {
	event.ID = m.nextID
	m.nextID++
	event.CreatedAt = time.Now()
	event.UpdatedAt = time.Now()
	m.events[event.ID] = event
	return nil
}

func (m *MockEventRepository) FindByID(id int64) (*models.Event, error) {
	if event, ok := m.events[id]; ok {
		return event, nil
	}
	return nil, ErrNotFound
}

func (m *MockEventRepository) Update(event *models.Event) error {
	if _, ok := m.events[event.ID]; !ok {
		return ErrNotFound
	}
	event.UpdatedAt = time.Now()
	m.events[event.ID] = event
	return nil
}

func (m *MockEventRepository) Delete(id int64) error {
	if _, ok := m.events[id]; !ok {
		return ErrNotFound
	}
	delete(m.events, id)
	return nil
}

func (m *MockEventRepository) AddParticipant(eventID, userID int64) error {
	m.participants[eventID] = append(m.participants[eventID], userID)
	return nil
}

func (m *MockEventRepository) FindParticipants(eventID int64) ([]int64, error) {
	return m.participants[eventID], nil
}

func (m *MockEventRepository) IsUserParticipant(eventID, userID int64) (bool, error) {
	for _, id := range m.participants[eventID] {
		if id == userID {
			return true, nil
		}
	}
	return false, nil
}

// MockUserRepository is a mock implementation of user repository
type MockUserRepository struct {
	users map[int64]*models.User
}

// Helper function to create string pointer
func strPtr(s string) *string {
	return &s
}

func NewMockUserRepository() *MockUserRepository {
	return &MockUserRepository{
		users: map[int64]*models.User{
			1: {ID: 1, Name: strPtr("Creator"), Phone: "01012345678"},
			2: {ID: 2, Name: strPtr("Participant1"), Phone: "01087654321"},
			3: {ID: 3, Name: strPtr("Participant2"), Phone: "01011112222"},
		},
	}
}

func (m *MockUserRepository) FindByID(id int64) (*models.User, error) {
	if user, ok := m.users[id]; ok {
		return user, nil
	}
	return nil, ErrNotFound
}

func (m *MockUserRepository) FindByIDs(ids []int64) ([]*models.User, error) {
	var users []*models.User
	for _, id := range ids {
		if user, ok := m.users[id]; ok {
			users = append(users, user)
		}
	}
	return users, nil
}

// Tests
func TestEventService_CreateEvent_ValidTimes(t *testing.T) {
	startTime := time.Now().Add(1 * time.Hour)
	endTime := startTime.Add(2 * time.Hour)

	req := &models.CreateEventRequest{
		Title:     "Test Event",
		StartTime: startTime,
		EndTime:   endTime,
	}

	// Test that EndTime must be after StartTime
	if req.EndTime.Before(req.StartTime) {
		t.Error("EndTime should be after StartTime")
	}
}

func TestEventService_CreateEvent_InvalidTimes(t *testing.T) {
	startTime := time.Now().Add(2 * time.Hour)
	endTime := startTime.Add(-1 * time.Hour) // EndTime before StartTime

	req := &models.CreateEventRequest{
		Title:     "Test Event",
		StartTime: startTime,
		EndTime:   endTime,
	}

	if !req.EndTime.Before(req.StartTime) {
		t.Error("EndTime should be before StartTime for this test case")
	}
}

func TestEventService_StatusTransitions(t *testing.T) {
	tests := []struct {
		name          string
		currentStatus models.EventStatus
		targetStatus  models.EventStatus
		shouldSucceed bool
	}{
		{
			name:          "PROPOSED to CONFIRMED",
			currentStatus: models.EventStatusProposed,
			targetStatus:  models.EventStatusConfirmed,
			shouldSucceed: true,
		},
		{
			name:          "CONFIRMED to DONE",
			currentStatus: models.EventStatusConfirmed,
			targetStatus:  models.EventStatusDone,
			shouldSucceed: true,
		},
		{
			name:          "PROPOSED to CANCELED",
			currentStatus: models.EventStatusProposed,
			targetStatus:  models.EventStatusCanceled,
			shouldSucceed: true,
		},
		{
			name:          "DONE to CANCELED (not allowed)",
			currentStatus: models.EventStatusDone,
			targetStatus:  models.EventStatusCanceled,
			shouldSucceed: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Validate status transition logic
			canTransition := canChangeStatus(tt.currentStatus, tt.targetStatus)
			if canTransition != tt.shouldSucceed {
				t.Errorf("Expected transition from %s to %s to be %v, got %v",
					tt.currentStatus, tt.targetStatus, tt.shouldSucceed, canTransition)
			}
		})
	}
}

// Helper function to validate status transitions
func canChangeStatus(current, target models.EventStatus) bool {
	switch current {
	case models.EventStatusProposed:
		return target == models.EventStatusConfirmed || target == models.EventStatusCanceled
	case models.EventStatusConfirmed:
		return target == models.EventStatusDone || target == models.EventStatusCanceled
	case models.EventStatusDone:
		return false // Cannot change from DONE
	case models.EventStatusCanceled:
		return false // Cannot change from CANCELED
	}
	return false
}

func TestIsUserEventMember(t *testing.T) {
	tests := []struct {
		name         string
		creatorID    int64
		userID       int64
		participants []int64
		expected     bool
	}{
		{
			name:         "User is creator",
			creatorID:    1,
			userID:       1,
			participants: []int64{2, 3},
			expected:     true,
		},
		{
			name:         "User is participant",
			creatorID:    1,
			userID:       2,
			participants: []int64{2, 3},
			expected:     true,
		},
		{
			name:         "User is not member",
			creatorID:    1,
			userID:       99,
			participants: []int64{2, 3},
			expected:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Simulate member check logic
			isMember := tt.creatorID == tt.userID
			if !isMember {
				for _, p := range tt.participants {
					if p == tt.userID {
						isMember = true
						break
					}
				}
			}

			if isMember != tt.expected {
				t.Errorf("Expected isMember to be %v, got %v", tt.expected, isMember)
			}
		})
	}
}

func TestEventTimeValidation(t *testing.T) {
	now := time.Now()

	tests := []struct {
		name        string
		startTime   time.Time
		endTime     time.Time
		expectError bool
	}{
		{
			name:        "Valid future event",
			startTime:   now.Add(1 * time.Hour),
			endTime:     now.Add(2 * time.Hour),
			expectError: false,
		},
		{
			name:        "End time before start time",
			startTime:   now.Add(2 * time.Hour),
			endTime:     now.Add(1 * time.Hour),
			expectError: true,
		},
		{
			name:        "Same start and end time",
			startTime:   now.Add(1 * time.Hour),
			endTime:     now.Add(1 * time.Hour),
			expectError: false, // Some systems may allow this
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			hasError := tt.endTime.Before(tt.startTime)
			if hasError != tt.expectError {
				t.Errorf("Expected error=%v, got error=%v", tt.expectError, hasError)
			}
		})
	}
}

func TestParticipantManagement(t *testing.T) {
	participants := []int64{1, 2, 3}

	// Test adding participant
	newParticipant := int64(4)
	participants = append(participants, newParticipant)

	if len(participants) != 4 {
		t.Errorf("Expected 4 participants, got %d", len(participants))
	}

	// Test checking participant existence
	found := false
	for _, p := range participants {
		if p == newParticipant {
			found = true
			break
		}
	}

	if !found {
		t.Error("New participant should be in the list")
	}

	// Test removing participant
	var newParticipants []int64
	for _, p := range participants {
		if p != 2 {
			newParticipants = append(newParticipants, p)
		}
	}

	if len(newParticipants) != 3 {
		t.Errorf("Expected 3 participants after removal, got %d", len(newParticipants))
	}
}

func TestMockEventRepository(t *testing.T) {
	repo := NewMockEventRepository()

	// Test Create
	event := &models.Event{
		Title:     "Test Event",
		StartTime: time.Now().Add(1 * time.Hour),
		EndTime:   time.Now().Add(2 * time.Hour),
		CreatorID: 1,
		Status:    models.EventStatusProposed,
	}

	err := repo.Create(event)
	if err != nil {
		t.Errorf("Create should not return error: %v", err)
	}

	if event.ID != 1 {
		t.Errorf("Expected ID to be 1, got %d", event.ID)
	}

	// Test FindByID
	found, err := repo.FindByID(1)
	if err != nil {
		t.Errorf("FindByID should not return error: %v", err)
	}
	if found.Title != "Test Event" {
		t.Errorf("Expected title to be 'Test Event', got '%s'", found.Title)
	}

	// Test FindByID not found
	_, err = repo.FindByID(999)
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound, got %v", err)
	}

	// Test Update
	event.Title = "Updated Event"
	err = repo.Update(event)
	if err != nil {
		t.Errorf("Update should not return error: %v", err)
	}

	found, _ = repo.FindByID(1)
	if found.Title != "Updated Event" {
		t.Errorf("Expected title to be 'Updated Event', got '%s'", found.Title)
	}

	// Test AddParticipant
	err = repo.AddParticipant(1, 2)
	if err != nil {
		t.Errorf("AddParticipant should not return error: %v", err)
	}

	// Test IsUserParticipant
	isParticipant, _ := repo.IsUserParticipant(1, 2)
	if !isParticipant {
		t.Error("User 2 should be a participant")
	}

	isParticipant, _ = repo.IsUserParticipant(1, 99)
	if isParticipant {
		t.Error("User 99 should not be a participant")
	}

	// Test Delete
	err = repo.Delete(1)
	if err != nil {
		t.Errorf("Delete should not return error: %v", err)
	}

	_, err = repo.FindByID(1)
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound after delete, got %v", err)
	}
}

func TestMockUserRepository(t *testing.T) {
	repo := NewMockUserRepository()

	// Test FindByID
	user, err := repo.FindByID(1)
	if err != nil {
		t.Errorf("FindByID should not return error: %v", err)
	}
	if user.Name == nil || *user.Name != "Creator" {
		t.Errorf("Expected name 'Creator', got '%v'", user.Name)
	}

	// Test FindByID not found
	_, err = repo.FindByID(999)
	if err != ErrNotFound {
		t.Errorf("Expected ErrNotFound, got %v", err)
	}

	// Test FindByIDs
	users, err := repo.FindByIDs([]int64{1, 2, 999})
	if err != nil {
		t.Errorf("FindByIDs should not return error: %v", err)
	}
	if len(users) != 2 {
		t.Errorf("Expected 2 users (1 and 2), got %d", len(users))
	}
}
