package models

import (
	"time"
)

// OAuthProvider represents supported OAuth providers
type OAuthProvider string

const (
	OAuthProviderGoogle OAuthProvider = "google"
	OAuthProviderApple  OAuthProvider = "apple"
)

// OAuthAccount represents a linked OAuth account in the database
type OAuthAccount struct {
	ID             int64         `json:"id" db:"id"`
	UserID         int64         `json:"user_id" db:"user_id"`
	Provider       OAuthProvider `json:"provider" db:"provider"`
	ProviderUserID string        `json:"provider_user_id" db:"provider_user_id"`
	Email          *string       `json:"email,omitempty" db:"email"`
	Name           *string       `json:"name,omitempty" db:"name"`
	PictureURL     *string       `json:"picture_url,omitempty" db:"picture_url"`
	// Google Calendar 연동용 토큰 필드
	AccessToken  *string    `json:"-" db:"access_token"`  // Google API 호출용 (JSON 노출 안함)
	RefreshToken *string    `json:"-" db:"refresh_token"` // 토큰 갱신용 (JSON 노출 안함)
	TokenExpiry  *time.Time `json:"-" db:"token_expiry"`  // Access Token 만료 시간
	Scopes       []string   `json:"-" db:"scopes"`        // 부여된 OAuth Scope 목록
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at" db:"updated_at"`
}

// HasCalendarScope checks if this OAuth account has Calendar API access
func (o *OAuthAccount) HasCalendarScope() bool {
	for _, scope := range o.Scopes {
		if scope == "https://www.googleapis.com/auth/calendar" ||
			scope == "https://www.googleapis.com/auth/calendar.events" {
			return true
		}
	}
	return false
}

// IsTokenExpired checks if the access token is expired
func (o *OAuthAccount) IsTokenExpired() bool {
	if o.TokenExpiry == nil {
		return true
	}
	// 5분 여유를 두고 만료 체크
	return time.Now().Add(5 * time.Minute).After(*o.TokenExpiry)
}

// GoogleLoginRequest represents Google OAuth login request from Flutter
// Flutter sends the ID Token obtained from google_sign_in package
type GoogleLoginRequest struct {
	IDToken  string `json:"id_token" binding:"required"`
	Platform string `json:"platform"` // web, android, ios
}

// GoogleCalendarLoginRequest represents Google OAuth login with Calendar scope
// Flutter sends both ID Token and Access Token when Calendar permission is granted
type GoogleCalendarLoginRequest struct {
	IDToken      string `json:"id_token" binding:"required"`
	AccessToken  string `json:"access_token" binding:"required"`
	RefreshToken string `json:"refresh_token,omitempty"` // Optional, may not always be returned
	Platform     string `json:"platform"`                // web, android, ios
}

// GoogleTokenPayload represents the decoded Google ID Token payload
type GoogleTokenPayload struct {
	Issuer        string `json:"iss"`           // https://accounts.google.com
	Audience      string `json:"aud"`           // Your client ID
	Subject       string `json:"sub"`           // Unique Google user ID
	Email         string `json:"email"`         // User's email
	EmailVerified bool   `json:"email_verified"`
	Name          string `json:"name"`          // Full name
	Picture       string `json:"picture"`       // Profile picture URL
	GivenName     string `json:"given_name"`    // First name
	FamilyName    string `json:"family_name"`   // Last name
	Locale        string `json:"locale"`        // Locale (e.g., "ko")
	IssuedAt      int64  `json:"iat"`           // Issued at timestamp
	Expiration    int64  `json:"exp"`           // Expiration timestamp
}

// OAuthAccountResponse represents OAuth account info in API responses
type OAuthAccountResponse struct {
	Provider   OAuthProvider `json:"provider"`
	Email      *string       `json:"email,omitempty"`
	Name       *string       `json:"name,omitempty"`
	PictureURL *string       `json:"picture_url,omitempty"`
	LinkedAt   time.Time     `json:"linked_at"`
}

// ToResponse converts OAuthAccount to OAuthAccountResponse
func (o *OAuthAccount) ToResponse() *OAuthAccountResponse {
	return &OAuthAccountResponse{
		Provider:   o.Provider,
		Email:      o.Email,
		Name:       o.Name,
		PictureURL: o.PictureURL,
		LinkedAt:   o.CreatedAt,
	}
}
