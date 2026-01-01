package models

import (
	"time"
)

// RefreshToken represents a refresh token in the database
type RefreshToken struct {
	ID        int64     `json:"id" db:"id"`
	UserID    int64     `json:"user_id" db:"user_id"`
	Token     string    `json:"token" db:"token"`
	ExpiresAt time.Time `json:"expires_at" db:"expires_at"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// LoginRequest represents login request (using phone-based authentication)
type LoginRequest struct {
	Phone string `json:"phone" binding:"required"`
	// In production, this would include verification code
	// VerificationCode string `json:"verification_code" binding:"required"`
}

// AuthResponse represents authentication response with tokens
type AuthResponse struct {
	AccessToken  string        `json:"access_token"`
	RefreshToken string        `json:"refresh_token"`
	ExpiresIn    int64         `json:"expires_in"` // seconds
	User         *UserResponse `json:"user"`
}

// RefreshTokenRequest represents token refresh request
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// TokenClaims represents JWT claims
type TokenClaims struct {
	UserID int64    `json:"user_id"`
	Phone  string   `json:"phone"`
	Role   UserRole `json:"role"`
}
