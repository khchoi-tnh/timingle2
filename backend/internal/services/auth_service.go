package services

import (
	"fmt"
	"time"

	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/khchoi-tnh/timingle/internal/repositories"
	"github.com/khchoi-tnh/timingle/pkg/utils"
)

// AuthService handles authentication business logic
type AuthService struct {
	userRepo  *repositories.UserRepository
	authRepo  *repositories.AuthRepository
	jwtManager *utils.JWTManager
}

// NewAuthService creates a new auth service
func NewAuthService(
	userRepo *repositories.UserRepository,
	authRepo *repositories.AuthRepository,
	jwtManager *utils.JWTManager,
) *AuthService {
	return &AuthService{
		userRepo:   userRepo,
		authRepo:   authRepo,
		jwtManager: jwtManager,
	}
}

// Register registers a new user
func (s *AuthService) Register(req *models.RegisterRequest) (*models.AuthResponse, error) {
	// Check if user already exists
	existingUser, _ := s.userRepo.FindByPhone(req.Phone)
	if existingUser != nil {
		return nil, fmt.Errorf("user with this phone already exists")
	}

	// Create new user
	user := &models.User{
		Phone:    req.Phone,
		Name:     &req.Name,
		Timezone: "UTC",
		Language: "ko",
		Role:     models.UserRoleUser,
	}

	if err := s.userRepo.Create(user); err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Generate tokens
	return s.generateAuthResponse(user)
}

// Login authenticates a user and returns tokens
func (s *AuthService) Login(req *models.LoginRequest) (*models.AuthResponse, error) {
	// Find user by phone
	user, err := s.userRepo.FindByPhone(req.Phone)
	if err != nil {
		return nil, fmt.Errorf("invalid phone number")
	}

	// In production, verify SMS code here
	// For now, we skip verification for development

	// Generate tokens
	return s.generateAuthResponse(user)
}

// RefreshToken generates new access token from refresh token
func (s *AuthService) RefreshToken(req *models.RefreshTokenRequest) (*models.AuthResponse, error) {
	// Find refresh token
	refreshToken, err := s.authRepo.FindRefreshToken(req.RefreshToken)
	if err != nil {
		return nil, fmt.Errorf("invalid refresh token")
	}

	// Check if expired
	if time.Now().After(refreshToken.ExpiresAt) {
		// Delete expired token
		_ = s.authRepo.DeleteRefreshToken(req.RefreshToken)
		return nil, fmt.Errorf("refresh token expired")
	}

	// Find user
	user, err := s.userRepo.FindByID(refreshToken.UserID)
	if err != nil {
		return nil, fmt.Errorf("user not found")
	}

	// Generate new access token (keep same refresh token)
	accessToken, err := s.jwtManager.GenerateAccessToken(user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	return &models.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: req.RefreshToken,
		ExpiresIn:    int64(s.jwtManager.GetAccessExpiry().Seconds()),
		User:         user.ToUserResponse(),
	}, nil
}

// Logout logs out a user by deleting their refresh tokens
func (s *AuthService) Logout(userID int64) error {
	return s.authRepo.DeleteUserRefreshTokens(userID)
}

// ValidateAccessToken validates an access token and returns claims
func (s *AuthService) ValidateAccessToken(tokenString string) (*utils.Claims, error) {
	return s.jwtManager.ValidateAccessToken(tokenString)
}

// generateAuthResponse generates access and refresh tokens for a user
func (s *AuthService) generateAuthResponse(user *models.User) (*models.AuthResponse, error) {
	// Generate access token
	accessToken, err := s.jwtManager.GenerateAccessToken(user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	// Generate refresh token
	refreshTokenString, err := s.jwtManager.GenerateRefreshToken()
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	// Save refresh token to database
	refreshToken := &models.RefreshToken{
		UserID:    user.ID,
		Token:     refreshTokenString,
		ExpiresAt: time.Now().Add(s.jwtManager.GetRefreshExpiry()),
	}

	if err := s.authRepo.SaveRefreshToken(refreshToken); err != nil {
		return nil, fmt.Errorf("failed to save refresh token: %w", err)
	}

	return &models.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshTokenString,
		ExpiresIn:    int64(s.jwtManager.GetAccessExpiry().Seconds()),
		User:         user.ToUserResponse(),
	}, nil
}
