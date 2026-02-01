package services

import (
	"context"
	"fmt"
	"time"

	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/khchoi-tnh/timingle/internal/repositories"
	"github.com/khchoi-tnh/timingle/pkg/utils"
)

// CalendarScope is the Google Calendar API scope
const CalendarScope = "https://www.googleapis.com/auth/calendar"

// AuthService handles authentication business logic
type AuthService struct {
	userRepo       *repositories.UserRepository
	authRepo       *repositories.AuthRepository
	oauthRepo      *repositories.OAuthRepository
	jwtManager     *utils.JWTManager
	googleVerifier *utils.GoogleOAuthVerifier
}

// NewAuthService creates a new auth service
func NewAuthService(
	userRepo *repositories.UserRepository,
	authRepo *repositories.AuthRepository,
	oauthRepo *repositories.OAuthRepository,
	jwtManager *utils.JWTManager,
	googleVerifier *utils.GoogleOAuthVerifier,
) *AuthService {
	return &AuthService{
		userRepo:       userRepo,
		authRepo:       authRepo,
		oauthRepo:      oauthRepo,
		jwtManager:     jwtManager,
		googleVerifier: googleVerifier,
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

// GoogleLogin handles Google OAuth login
// Flow:
// 1. Verify Google ID token
// 2. Find or create user based on Google email
// 3. Link/update OAuth account
// 4. Generate JWT tokens
func (s *AuthService) GoogleLogin(ctx context.Context, req *models.GoogleLoginRequest) (*models.AuthResponse, error) {
	// 1. Verify Google ID token
	googlePayload, err := s.googleVerifier.VerifyIDToken(ctx, req.IDToken)
	if err != nil {
		return nil, fmt.Errorf("invalid Google ID token: %w", err)
	}

	// 2. Check if OAuth account already exists
	oauthAccount, err := s.oauthRepo.FindByProviderUserID(models.OAuthProviderGoogle, googlePayload.Subject)
	if err != nil {
		return nil, fmt.Errorf("failed to check OAuth account: %w", err)
	}

	var user *models.User

	if oauthAccount != nil {
		// Existing OAuth account - get the linked user
		user, err = s.userRepo.FindByID(oauthAccount.UserID)
		if err != nil {
			return nil, fmt.Errorf("failed to find user: %w", err)
		}

		// Update OAuth account info if changed
		if needsUpdate(oauthAccount, googlePayload) {
			oauthAccount.Email = &googlePayload.Email
			oauthAccount.Name = &googlePayload.Name
			oauthAccount.PictureURL = &googlePayload.Picture
			_ = s.oauthRepo.Update(oauthAccount)
		}
	} else {
		// New OAuth account - check if user exists by email
		user, err = s.userRepo.FindByEmail(googlePayload.Email)
		if err != nil {
			return nil, fmt.Errorf("failed to find user by email: %w", err)
		}

		if user == nil {
			// Create new user
			user, err = s.userRepo.CreateOAuthUser(
				googlePayload.Email,
				googlePayload.Name,
				googlePayload.Picture,
			)
			if err != nil {
				return nil, fmt.Errorf("failed to create user: %w", err)
			}
		}

		// Create OAuth account link
		newOAuthAccount := &models.OAuthAccount{
			UserID:         user.ID,
			Provider:       models.OAuthProviderGoogle,
			ProviderUserID: googlePayload.Subject,
			Email:          &googlePayload.Email,
			Name:           &googlePayload.Name,
			PictureURL:     &googlePayload.Picture,
		}
		if err := s.oauthRepo.Create(newOAuthAccount); err != nil {
			return nil, fmt.Errorf("failed to link OAuth account: %w", err)
		}
	}

	// 3. Generate JWT tokens
	return s.generateAuthResponse(user)
}

// needsUpdate checks if OAuth account info needs to be updated
func needsUpdate(account *models.OAuthAccount, payload *models.GoogleTokenPayload) bool {
	if account.Email == nil || *account.Email != payload.Email {
		return true
	}
	if account.Name == nil || *account.Name != payload.Name {
		return true
	}
	if account.PictureURL == nil || *account.PictureURL != payload.Picture {
		return true
	}
	return false
}

// GoogleLoginWithCalendar handles Google OAuth login with Calendar scope
// This saves the access token and refresh token for Calendar API access
func (s *AuthService) GoogleLoginWithCalendar(ctx context.Context, req *models.GoogleCalendarLoginRequest) (*models.AuthResponse, error) {
	// 1. Verify Google ID token (same as regular login)
	googlePayload, err := s.googleVerifier.VerifyIDToken(ctx, req.IDToken)
	if err != nil {
		return nil, fmt.Errorf("invalid Google ID token: %w", err)
	}

	// 2. Check if OAuth account already exists
	oauthAccount, err := s.oauthRepo.FindByProviderUserID(models.OAuthProviderGoogle, googlePayload.Subject)
	if err != nil {
		return nil, fmt.Errorf("failed to check OAuth account: %w", err)
	}

	var user *models.User

	// Calculate token expiry (Google access tokens typically expire in 1 hour)
	tokenExpiry := time.Now().Add(1 * time.Hour)
	// Default Calendar scope
	scopes := []string{"https://www.googleapis.com/auth/calendar"}

	if oauthAccount != nil {
		// Existing OAuth account - get the linked user
		user, err = s.userRepo.FindByID(oauthAccount.UserID)
		if err != nil {
			return nil, fmt.Errorf("failed to find user: %w", err)
		}

		// Update OAuth account with new tokens
		refreshToken := oauthAccount.RefreshToken
		if req.RefreshToken != "" {
			refreshToken = &req.RefreshToken
		}

		err = s.oauthRepo.UpdateTokens(
			oauthAccount.ID,
			&req.AccessToken,
			refreshToken,
			&tokenExpiry,
			scopes,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to update OAuth tokens: %w", err)
		}

		// Update profile info if changed
		if needsUpdate(oauthAccount, googlePayload) {
			oauthAccount.Email = &googlePayload.Email
			oauthAccount.Name = &googlePayload.Name
			oauthAccount.PictureURL = &googlePayload.Picture
			_ = s.oauthRepo.Update(oauthAccount)
		}
	} else {
		// New OAuth account - check if user exists by email
		user, err = s.userRepo.FindByEmail(googlePayload.Email)
		if err != nil {
			return nil, fmt.Errorf("failed to find user by email: %w", err)
		}

		if user == nil {
			// Create new user
			user, err = s.userRepo.CreateOAuthUser(
				googlePayload.Email,
				googlePayload.Name,
				googlePayload.Picture,
			)
			if err != nil {
				return nil, fmt.Errorf("failed to create user: %w", err)
			}
		}

		// Create OAuth account link with tokens
		refreshToken := &req.RefreshToken
		if req.RefreshToken == "" {
			refreshToken = nil
		}

		newOAuthAccount := &models.OAuthAccount{
			UserID:         user.ID,
			Provider:       models.OAuthProviderGoogle,
			ProviderUserID: googlePayload.Subject,
			Email:          &googlePayload.Email,
			Name:           &googlePayload.Name,
			PictureURL:     &googlePayload.Picture,
			AccessToken:    &req.AccessToken,
			RefreshToken:   refreshToken,
			TokenExpiry:    &tokenExpiry,
			Scopes:         scopes,
		}
		if err := s.oauthRepo.Create(newOAuthAccount); err != nil {
			return nil, fmt.Errorf("failed to link OAuth account: %w", err)
		}
	}

	// 3. Generate JWT tokens
	return s.generateAuthResponse(user)
}

// GetValidAccessToken returns a valid access token for the user's Google account
// If the token is expired, it will be refreshed automatically
func (s *AuthService) GetValidAccessToken(ctx context.Context, userID int64) (string, error) {
	oauthAccount, err := s.oauthRepo.FindByUserIDAndProvider(userID, models.OAuthProviderGoogle)
	if err != nil {
		return "", fmt.Errorf("failed to find OAuth account: %w", err)
	}
	if oauthAccount == nil {
		return "", fmt.Errorf("no Google account linked")
	}
	if !oauthAccount.HasCalendarScope() {
		return "", fmt.Errorf("calendar permission not granted")
	}
	if oauthAccount.AccessToken == nil {
		return "", fmt.Errorf("no access token available")
	}

	// Check if token is expired
	if oauthAccount.IsTokenExpired() {
		if oauthAccount.RefreshToken == nil {
			return "", fmt.Errorf("access token expired and no refresh token available")
		}

		// Refresh the token
		tokenResp, err := s.googleVerifier.RefreshAccessToken(ctx, *oauthAccount.RefreshToken)
		if err != nil {
			return "", fmt.Errorf("failed to refresh token: %w", err)
		}

		// Update stored tokens
		tokenExpiry := utils.GetTokenExpiry(tokenResp.ExpiresIn)
		refreshToken := oauthAccount.RefreshToken
		if tokenResp.RefreshToken != "" {
			refreshToken = &tokenResp.RefreshToken
		}

		scopes := utils.ParseScopes(tokenResp.Scope)
		if len(scopes) == 0 {
			scopes = oauthAccount.Scopes
		}

		err = s.oauthRepo.UpdateTokens(
			oauthAccount.ID,
			&tokenResp.AccessToken,
			refreshToken,
			&tokenExpiry,
			scopes,
		)
		if err != nil {
			return "", fmt.Errorf("failed to update refreshed tokens: %w", err)
		}

		return tokenResp.AccessToken, nil
	}

	return *oauthAccount.AccessToken, nil
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
