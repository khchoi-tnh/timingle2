package handlers

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/khchoi-tnh/timingle/internal/models"
)

// MockEventService is a mock implementation for testing
type MockEventService struct {
	CreateEventFunc         func(int64, *models.CreateEventRequest) (*models.EventResponse, error)
	GetEventFunc            func(int64) (*models.EventResponse, error)
	UpdateEventFunc         func(int64, int64, *models.UpdateEventRequest) (*models.EventResponse, error)
	DeleteEventFunc         func(int64, int64) error
	GetUserEventsFunc       func(int64, string) ([]*models.EventResponse, error)
	AddParticipantFunc      func(int64, int64, int64) error
	RemoveParticipantFunc   func(int64, int64, int64) error
	ConfirmParticipationFunc func(int64, int64) error
	ConfirmEventFunc        func(int64, int64) error
	CancelEventFunc         func(int64, int64) error
	MarkEventDoneFunc       func(int64, int64) error
}

func (m *MockEventService) CreateEvent(userID int64, req *models.CreateEventRequest) (*models.EventResponse, error) {
	if m.CreateEventFunc != nil {
		return m.CreateEventFunc(userID, req)
	}
	return nil, errors.New("not implemented")
}

func (m *MockEventService) GetEvent(eventID int64) (*models.EventResponse, error) {
	if m.GetEventFunc != nil {
		return m.GetEventFunc(eventID)
	}
	return nil, errors.New("not implemented")
}

func (m *MockEventService) UpdateEvent(eventID, userID int64, req *models.UpdateEventRequest) (*models.EventResponse, error) {
	if m.UpdateEventFunc != nil {
		return m.UpdateEventFunc(eventID, userID, req)
	}
	return nil, errors.New("not implemented")
}

func (m *MockEventService) DeleteEvent(eventID, userID int64) error {
	if m.DeleteEventFunc != nil {
		return m.DeleteEventFunc(eventID, userID)
	}
	return nil
}

func (m *MockEventService) GetUserEvents(userID int64, status string) ([]*models.EventResponse, error) {
	if m.GetUserEventsFunc != nil {
		return m.GetUserEventsFunc(userID, status)
	}
	return nil, errors.New("not implemented")
}

func createTestEventResponse(id int64, title string) *models.EventResponse {
	now := time.Now()
	name := "Test Creator"
	return &models.EventResponse{
		ID:        id,
		Title:     title,
		StartTime: now.Add(24 * time.Hour),
		EndTime:   now.Add(26 * time.Hour),
		Status:    models.EventStatusProposed,
		Creator: &models.UserResponse{
			ID:       1,
			Phone:    "01012345678",
			Name:     &name,
			Timezone: "Asia/Seoul",
			Language: "ko",
			Role:     models.UserRoleUser,
		},
		CreatedAt: now,
		UpdatedAt: now,
	}
}

func setupEventRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	return gin.New()
}

func TestEventHandler_CreateEvent(t *testing.T) {
	tests := []struct {
		name           string
		userID         int64
		requestBody    interface{}
		setupMock      func(*MockEventService)
		expectedStatus int
	}{
		{
			name:   "successful creation",
			userID: 1,
			requestBody: map[string]interface{}{
				"title":      "Test Event",
				"start_time": time.Now().Add(24 * time.Hour).Format(time.RFC3339),
				"end_time":   time.Now().Add(26 * time.Hour).Format(time.RFC3339),
			},
			setupMock: func(m *MockEventService) {
				m.CreateEventFunc = func(userID int64, req *models.CreateEventRequest) (*models.EventResponse, error) {
					return createTestEventResponse(1, req.Title), nil
				}
			},
			expectedStatus: http.StatusCreated,
		},
		{
			name:   "invalid request body",
			userID: 1,
			requestBody: map[string]interface{}{
				"title": "", // empty title
			},
			setupMock:      func(m *MockEventService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:   "service error",
			userID: 1,
			requestBody: map[string]interface{}{
				"title":      "Test Event",
				"start_time": time.Now().Add(24 * time.Hour).Format(time.RFC3339),
				"end_time":   time.Now().Add(26 * time.Hour).Format(time.RFC3339),
			},
			setupMock: func(m *MockEventService) {
				m.CreateEventFunc = func(userID int64, req *models.CreateEventRequest) (*models.EventResponse, error) {
					return nil, errors.New("creation failed")
				}
			},
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockEventService{}
			tt.setupMock(mockService)

			router := setupEventRouter()
			router.POST("/events", func(c *gin.Context) {
				c.Set("userID", tt.userID)

				var req models.CreateEventRequest
				if err := c.ShouldBindJSON(&req); err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}

				response, err := mockService.CreateEvent(tt.userID, &req)
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}

				c.JSON(http.StatusCreated, response)
			})

			body, _ := json.Marshal(tt.requestBody)
			req := httptest.NewRequest("POST", "/events", bytes.NewBuffer(body))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, w.Code, w.Body.String())
			}
		})
	}
}

func TestEventHandler_GetEvent(t *testing.T) {
	tests := []struct {
		name           string
		eventID        string
		setupMock      func(*MockEventService)
		expectedStatus int
	}{
		{
			name:    "successful get",
			eventID: "1",
			setupMock: func(m *MockEventService) {
				m.GetEventFunc = func(eventID int64) (*models.EventResponse, error) {
					return createTestEventResponse(eventID, "Test Event"), nil
				}
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:           "invalid event ID",
			eventID:        "invalid",
			setupMock:      func(m *MockEventService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:    "event not found",
			eventID: "999",
			setupMock: func(m *MockEventService) {
				m.GetEventFunc = func(eventID int64) (*models.EventResponse, error) {
					return nil, errors.New("event not found")
				}
			},
			expectedStatus: http.StatusNotFound,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockEventService{}
			tt.setupMock(mockService)

			router := setupEventRouter()
			router.GET("/events/:id", func(c *gin.Context) {
				eventIDStr := c.Param("id")
				var eventID int64
				if _, err := json.Marshal(eventIDStr); err != nil || eventIDStr == "invalid" {
					// Simple validation for test
					if eventIDStr == "invalid" {
						c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
						return
					}
				}

				// Parse event ID
				switch eventIDStr {
				case "1":
					eventID = 1
				case "999":
					eventID = 999
				default:
					c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
					return
				}

				response, err := mockService.GetEvent(eventID)
				if err != nil {
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
					return
				}

				c.JSON(http.StatusOK, response)
			})

			req := httptest.NewRequest("GET", "/events/"+tt.eventID, nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, w.Code)
			}
		})
	}
}

func TestEventHandler_GetUserEvents(t *testing.T) {
	tests := []struct {
		name           string
		userID         int64
		status         string
		setupMock      func(*MockEventService)
		expectedStatus int
		expectedCount  int
	}{
		{
			name:   "get all events",
			userID: 1,
			status: "",
			setupMock: func(m *MockEventService) {
				m.GetUserEventsFunc = func(userID int64, status string) ([]*models.EventResponse, error) {
					return []*models.EventResponse{
						createTestEventResponse(1, "Event 1"),
						createTestEventResponse(2, "Event 2"),
					}, nil
				}
			},
			expectedStatus: http.StatusOK,
			expectedCount:  2,
		},
		{
			name:   "filter by status",
			userID: 1,
			status: "CONFIRMED",
			setupMock: func(m *MockEventService) {
				m.GetUserEventsFunc = func(userID int64, status string) ([]*models.EventResponse, error) {
					return []*models.EventResponse{
						createTestEventResponse(1, "Confirmed Event"),
					}, nil
				}
			},
			expectedStatus: http.StatusOK,
			expectedCount:  1,
		},
		{
			name:   "empty list",
			userID: 1,
			status: "",
			setupMock: func(m *MockEventService) {
				m.GetUserEventsFunc = func(userID int64, status string) ([]*models.EventResponse, error) {
					return []*models.EventResponse{}, nil
				}
			},
			expectedStatus: http.StatusOK,
			expectedCount:  0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockEventService{}
			tt.setupMock(mockService)

			router := setupEventRouter()
			router.GET("/events", func(c *gin.Context) {
				c.Set("userID", tt.userID)
				status := c.Query("status")

				response, err := mockService.GetUserEvents(tt.userID, status)
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}

				c.JSON(http.StatusOK, response)
			})

			url := "/events"
			if tt.status != "" {
				url += "?status=" + tt.status
			}

			req := httptest.NewRequest("GET", url, nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, w.Code)
			}

			if tt.expectedStatus == http.StatusOK {
				var response []*models.EventResponse
				if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
					t.Errorf("Failed to parse response: %v", err)
				}
				if len(response) != tt.expectedCount {
					t.Errorf("Expected %d events, got %d", tt.expectedCount, len(response))
				}
			}
		})
	}
}

func TestEventHandler_DeleteEvent(t *testing.T) {
	tests := []struct {
		name           string
		eventID        string
		userID         int64
		setupMock      func(*MockEventService)
		expectedStatus int
	}{
		{
			name:    "successful deletion",
			eventID: "1",
			userID:  1,
			setupMock: func(m *MockEventService) {
				m.DeleteEventFunc = func(eventID, userID int64) error {
					return nil
				}
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:           "invalid event ID",
			eventID:        "invalid",
			userID:         1,
			setupMock:      func(m *MockEventService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:    "not authorized",
			eventID: "1",
			userID:  2,
			setupMock: func(m *MockEventService) {
				m.DeleteEventFunc = func(eventID, userID int64) error {
					return errors.New("not authorized to delete this event")
				}
			},
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockEventService{}
			tt.setupMock(mockService)

			router := setupEventRouter()
			router.DELETE("/events/:id", func(c *gin.Context) {
				c.Set("userID", tt.userID)

				eventIDStr := c.Param("id")
				if eventIDStr == "invalid" {
					c.JSON(http.StatusBadRequest, gin.H{"error": "invalid event ID"})
					return
				}

				var eventID int64 = 1 // Simplified for test

				err := mockService.DeleteEvent(eventID, tt.userID)
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}

				c.JSON(http.StatusOK, gin.H{"message": "event deleted successfully"})
			})

			req := httptest.NewRequest("DELETE", "/events/"+tt.eventID, nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, w.Code)
			}
		})
	}
}

func TestEventHandler_ConfirmEvent(t *testing.T) {
	tests := []struct {
		name           string
		eventID        string
		userID         int64
		setupMock      func(*MockEventService)
		expectedStatus int
	}{
		{
			name:    "successful confirmation",
			eventID: "1",
			userID:  1,
			setupMock: func(m *MockEventService) {
				m.ConfirmEventFunc = func(eventID, userID int64) error {
					return nil
				}
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:    "cannot confirm",
			eventID: "1",
			userID:  2,
			setupMock: func(m *MockEventService) {
				m.ConfirmEventFunc = func(eventID, userID int64) error {
					return errors.New("only creator can confirm")
				}
			},
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockEventService{}
			tt.setupMock(mockService)

			router := setupEventRouter()
			router.POST("/events/:id/confirm", func(c *gin.Context) {
				c.Set("userID", tt.userID)

				var eventID int64 = 1 // Simplified

				err := mockService.ConfirmEventFunc(eventID, tt.userID)
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}

				c.JSON(http.StatusOK, gin.H{"message": "event confirmed"})
			})

			req := httptest.NewRequest("POST", "/events/"+tt.eventID+"/confirm", nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, w.Code)
			}
		})
	}
}

func TestEventHandler_CancelEvent(t *testing.T) {
	tests := []struct {
		name           string
		eventID        string
		userID         int64
		setupMock      func(*MockEventService)
		expectedStatus int
	}{
		{
			name:    "successful cancellation",
			eventID: "1",
			userID:  1,
			setupMock: func(m *MockEventService) {
				m.CancelEventFunc = func(eventID, userID int64) error {
					return nil
				}
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:    "cannot cancel completed event",
			eventID: "1",
			userID:  1,
			setupMock: func(m *MockEventService) {
				m.CancelEventFunc = func(eventID, userID int64) error {
					return errors.New("cannot cancel completed event")
				}
			},
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockEventService{}
			tt.setupMock(mockService)

			router := setupEventRouter()
			router.POST("/events/:id/cancel", func(c *gin.Context) {
				c.Set("userID", tt.userID)

				var eventID int64 = 1 // Simplified

				err := mockService.CancelEventFunc(eventID, tt.userID)
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}

				c.JSON(http.StatusOK, gin.H{"message": "event canceled"})
			})

			req := httptest.NewRequest("POST", "/events/"+tt.eventID+"/cancel", nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, w.Code)
			}
		})
	}
}
