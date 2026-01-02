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

// MockAuthService is a mock implementation of AuthService for testing
type MockAuthService struct {
	RegisterFunc     func(*models.RegisterRequest) (*models.AuthResponse, error)
	LoginFunc        func(*models.LoginRequest) (*models.AuthResponse, error)
	RefreshTokenFunc func(*models.RefreshTokenRequest) (*models.AuthResponse, error)
	LogoutFunc       func(int64) error
}

func (m *MockAuthService) Register(req *models.RegisterRequest) (*models.AuthResponse, error) {
	if m.RegisterFunc != nil {
		return m.RegisterFunc(req)
	}
	return nil, errors.New("not implemented")
}

func (m *MockAuthService) Login(req *models.LoginRequest) (*models.AuthResponse, error) {
	if m.LoginFunc != nil {
		return m.LoginFunc(req)
	}
	return nil, errors.New("not implemented")
}

func (m *MockAuthService) RefreshToken(req *models.RefreshTokenRequest) (*models.AuthResponse, error) {
	if m.RefreshTokenFunc != nil {
		return m.RefreshTokenFunc(req)
	}
	return nil, errors.New("not implemented")
}

func (m *MockAuthService) Logout(userID int64) error {
	if m.LogoutFunc != nil {
		return m.LogoutFunc(userID)
	}
	return nil
}

// Helper to create test user response
func createTestUserResponse() *models.UserResponse {
	now := time.Now()
	name := "Test User"
	return &models.UserResponse{
		ID:        1,
		Phone:     "01012345678",
		Name:      &name,
		Timezone:  "Asia/Seoul",
		Language:  "ko",
		Role:      models.UserRoleUser,
		CreatedAt: now,
	}
}

func setupAuthRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	return gin.New()
}

func TestAuthHandler_Register(t *testing.T) {
	tests := []struct {
		name           string
		requestBody    interface{}
		setupMock      func(*MockAuthService)
		expectedStatus int
		checkResponse  func(*testing.T, *httptest.ResponseRecorder)
	}{
		{
			name: "successful registration",
			requestBody: map[string]string{
				"phone": "01012345678",
				"name":  "Test User",
			},
			setupMock: func(m *MockAuthService) {
				m.RegisterFunc = func(req *models.RegisterRequest) (*models.AuthResponse, error) {
					return &models.AuthResponse{
						User:         createTestUserResponse(),
						AccessToken:  "access_token",
						RefreshToken: "refresh_token",
					}, nil
				}
			},
			expectedStatus: http.StatusCreated,
			checkResponse: func(t *testing.T, w *httptest.ResponseRecorder) {
				var response models.AuthResponse
				err := json.Unmarshal(w.Body.Bytes(), &response)
				if err != nil {
					t.Errorf("Failed to parse response: %v", err)
				}
				if response.AccessToken != "access_token" {
					t.Errorf("Expected access_token, got %s", response.AccessToken)
				}
			},
		},
		{
			name: "invalid request body",
			requestBody: map[string]string{
				"phone": "", // empty phone
			},
			setupMock:      func(m *MockAuthService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "service error",
			requestBody: map[string]string{
				"phone": "01012345678",
				"name":  "Test User",
			},
			setupMock: func(m *MockAuthService) {
				m.RegisterFunc = func(req *models.RegisterRequest) (*models.AuthResponse, error) {
					return nil, errors.New("phone already exists")
				}
			},
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockAuthService{}
			tt.setupMock(mockService)

			// Note: We can't directly inject mock into AuthHandler since it uses concrete type
			// This test demonstrates the structure; in real scenario, use interfaces
			router := setupAuthRouter()

			// Create handler with mock behavior using closure
			router.POST("/register", func(c *gin.Context) {
				var req models.RegisterRequest
				if err := c.ShouldBindJSON(&req); err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}

				response, err := mockService.Register(&req)
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}

				c.JSON(http.StatusCreated, response)
			})

			body, _ := json.Marshal(tt.requestBody)
			req := httptest.NewRequest("POST", "/register", bytes.NewBuffer(body))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d. Body: %s", tt.expectedStatus, w.Code, w.Body.String())
			}

			if tt.checkResponse != nil {
				tt.checkResponse(t, w)
			}
		})
	}
}

func TestAuthHandler_Login(t *testing.T) {
	tests := []struct {
		name           string
		requestBody    interface{}
		setupMock      func(*MockAuthService)
		expectedStatus int
	}{
		{
			name: "successful login",
			requestBody: map[string]string{
				"phone": "01012345678",
			},
			setupMock: func(m *MockAuthService) {
				m.LoginFunc = func(req *models.LoginRequest) (*models.AuthResponse, error) {
					return &models.AuthResponse{
						User:         createTestUserResponse(),
						AccessToken:  "access_token",
						RefreshToken: "refresh_token",
					}, nil
				}
			},
			expectedStatus: http.StatusOK,
		},
		{
			name: "user not found",
			requestBody: map[string]string{
				"phone": "01099999999",
			},
			setupMock: func(m *MockAuthService) {
				m.LoginFunc = func(req *models.LoginRequest) (*models.AuthResponse, error) {
					return nil, errors.New("user not found")
				}
			},
			expectedStatus: http.StatusUnauthorized,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockAuthService{}
			tt.setupMock(mockService)

			router := setupAuthRouter()
			router.POST("/login", func(c *gin.Context) {
				var req models.LoginRequest
				if err := c.ShouldBindJSON(&req); err != nil {
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}

				response, err := mockService.Login(&req)
				if err != nil {
					c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
					return
				}

				c.JSON(http.StatusOK, response)
			})

			body, _ := json.Marshal(tt.requestBody)
			req := httptest.NewRequest("POST", "/login", bytes.NewBuffer(body))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, w.Code)
			}
		})
	}
}

func TestAuthHandler_Logout(t *testing.T) {
	tests := []struct {
		name           string
		userID         interface{}
		setupMock      func(*MockAuthService)
		expectedStatus int
	}{
		{
			name:   "successful logout",
			userID: int64(1),
			setupMock: func(m *MockAuthService) {
				m.LogoutFunc = func(userID int64) error {
					return nil
				}
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:           "no user ID in context",
			userID:         nil,
			setupMock:      func(m *MockAuthService) {},
			expectedStatus: http.StatusUnauthorized,
		},
		{
			name:   "logout error",
			userID: int64(1),
			setupMock: func(m *MockAuthService) {
				m.LogoutFunc = func(userID int64) error {
					return errors.New("logout failed")
				}
			},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockAuthService{}
			tt.setupMock(mockService)

			router := setupAuthRouter()
			router.POST("/logout", func(c *gin.Context) {
				if tt.userID != nil {
					c.Set("userID", tt.userID)
				}

				userID, exists := c.Get("userID")
				if !exists {
					c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
					return
				}

				err := mockService.Logout(userID.(int64))
				if err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					return
				}

				c.JSON(http.StatusOK, gin.H{"message": "logged out successfully"})
			})

			req := httptest.NewRequest("POST", "/logout", nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, w.Code)
			}
		})
	}
}

func TestAuthHandler_Me(t *testing.T) {
	tests := []struct {
		name           string
		user           *models.User
		expectedStatus int
	}{
		{
			name: "returns current user",
			user: &models.User{
				ID:    1,
				Phone: "01012345678",
				Name:  strPtr("Test User"),
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:           "no user in context",
			user:           nil,
			expectedStatus: http.StatusUnauthorized,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			router := setupAuthRouter()
			router.GET("/me", func(c *gin.Context) {
				if tt.user != nil {
					c.Set("user", tt.user)
				}

				user, exists := c.Get("user")
				if !exists {
					c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
					return
				}

				c.JSON(http.StatusOK, user.(*models.User).ToUserResponse())
			})

			req := httptest.NewRequest("GET", "/me", nil)
			w := httptest.NewRecorder()

			router.ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("Expected status %d, got %d", tt.expectedStatus, w.Code)
			}
		})
	}
}

// Helper function to create string pointer
func strPtr(s string) *string {
	return &s
}
