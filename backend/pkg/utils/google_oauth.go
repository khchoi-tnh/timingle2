package utils

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"google.golang.org/api/idtoken"

	"github.com/khchoi-tnh/timingle/internal/models"
)

// GoogleOAuthVerifier verifies Google ID tokens and manages OAuth tokens
type GoogleOAuthVerifier struct {
	clientIDs    []string // All valid client IDs (Android, iOS, Web)
	clientID     string   // Web client ID (for token refresh)
	clientSecret string   // Web client secret (for token refresh)
}

// NewGoogleOAuthVerifier creates a new Google OAuth verifier
func NewGoogleOAuthVerifier(clientIDs ...string) *GoogleOAuthVerifier {
	// Filter out empty client IDs
	validIDs := make([]string, 0, len(clientIDs))
	for _, id := range clientIDs {
		if id != "" {
			validIDs = append(validIDs, id)
		}
	}

	return &GoogleOAuthVerifier{
		clientIDs: validIDs,
	}
}

// NewGoogleOAuthVerifierWithSecret creates a verifier with client secret for token refresh
func NewGoogleOAuthVerifierWithSecret(clientID, clientSecret string, clientIDs ...string) *GoogleOAuthVerifier {
	verifier := NewGoogleOAuthVerifier(clientIDs...)
	verifier.clientID = clientID
	verifier.clientSecret = clientSecret
	return verifier
}

// VerifyIDToken verifies a Google ID token and returns the payload
func (v *GoogleOAuthVerifier) VerifyIDToken(ctx context.Context, idToken string) (*models.GoogleTokenPayload, error) {
	if len(v.clientIDs) == 0 {
		return nil, fmt.Errorf("no Google client IDs configured")
	}

	// Try each client ID until one works
	var lastErr error
	for _, clientID := range v.clientIDs {
		payload, err := idtoken.Validate(ctx, idToken, clientID)
		if err != nil {
			lastErr = err
			continue
		}

		// Successfully validated
		return v.extractPayload(payload)
	}

	return nil, fmt.Errorf("failed to verify Google ID token: %w", lastErr)
}

// extractPayload extracts GoogleTokenPayload from idtoken.Payload
func (v *GoogleOAuthVerifier) extractPayload(payload *idtoken.Payload) (*models.GoogleTokenPayload, error) {
	claims := payload.Claims

	result := &models.GoogleTokenPayload{
		Issuer:     payload.Issuer,
		Audience:   payload.Audience,
		Subject:    payload.Subject,
		Expiration: payload.Expires,
		IssuedAt:   payload.IssuedAt,
	}

	// Extract optional claims
	if email, ok := claims["email"].(string); ok {
		result.Email = email
	}

	if emailVerified, ok := claims["email_verified"].(bool); ok {
		result.EmailVerified = emailVerified
	}

	if name, ok := claims["name"].(string); ok {
		result.Name = name
	}

	if picture, ok := claims["picture"].(string); ok {
		result.Picture = picture
	}

	if givenName, ok := claims["given_name"].(string); ok {
		result.GivenName = givenName
	}

	if familyName, ok := claims["family_name"].(string); ok {
		result.FamilyName = familyName
	}

	if locale, ok := claims["locale"].(string); ok {
		result.Locale = locale
	}

	// Validate required fields
	if result.Subject == "" {
		return nil, fmt.Errorf("missing subject in Google ID token")
	}

	if result.Email == "" {
		return nil, fmt.Errorf("missing email in Google ID token")
	}

	return result, nil
}

// TokenResponse represents Google OAuth token response
type TokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token,omitempty"`
	ExpiresIn    int    `json:"expires_in"` // seconds until expiration
	TokenType    string `json:"token_type"`
	Scope        string `json:"scope"`
}

// RefreshAccessToken refreshes an access token using a refresh token
func (v *GoogleOAuthVerifier) RefreshAccessToken(ctx context.Context, refreshToken string) (*TokenResponse, error) {
	if v.clientID == "" || v.clientSecret == "" {
		return nil, fmt.Errorf("client ID and secret required for token refresh")
	}

	data := url.Values{
		"client_id":     {v.clientID},
		"client_secret": {v.clientSecret},
		"refresh_token": {refreshToken},
		"grant_type":    {"refresh_token"},
	}

	req, err := http.NewRequestWithContext(ctx, "POST", "https://oauth2.googleapis.com/token", strings.NewReader(data.Encode()))
	if err != nil {
		return nil, fmt.Errorf("failed to create refresh request: %w", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to refresh token: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("token refresh failed: %s", string(body))
	}

	var tokenResp TokenResponse
	if err := json.Unmarshal(body, &tokenResp); err != nil {
		return nil, fmt.Errorf("failed to parse token response: %w", err)
	}

	return &tokenResp, nil
}

// GetTokenExpiry calculates token expiry time from expires_in seconds
func GetTokenExpiry(expiresIn int) time.Time {
	return time.Now().Add(time.Duration(expiresIn) * time.Second)
}

// ParseScopes splits a space-separated scope string into a slice
func ParseScopes(scopeString string) []string {
	if scopeString == "" {
		return []string{}
	}
	return strings.Split(scopeString, " ")
}
