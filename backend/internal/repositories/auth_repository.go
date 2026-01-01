package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/khchoi-tnh/timingle/internal/models"
)

// AuthRepository handles authentication data operations
type AuthRepository struct {
	db *sql.DB
}

// NewAuthRepository creates a new auth repository
func NewAuthRepository(db *sql.DB) *AuthRepository {
	return &AuthRepository{db: db}
}

// SaveRefreshToken saves a refresh token
func (r *AuthRepository) SaveRefreshToken(refreshToken *models.RefreshToken) error {
	query := `
		INSERT INTO refresh_tokens (user_id, token, expires_at)
		VALUES ($1, $2, $3)
		RETURNING id, created_at
	`

	err := r.db.QueryRow(
		query,
		refreshToken.UserID,
		refreshToken.Token,
		refreshToken.ExpiresAt,
	).Scan(&refreshToken.ID, &refreshToken.CreatedAt)

	if err != nil {
		return fmt.Errorf("failed to save refresh token: %w", err)
	}

	return nil
}

// FindRefreshToken finds a refresh token by token string
func (r *AuthRepository) FindRefreshToken(token string) (*models.RefreshToken, error) {
	query := `
		SELECT id, user_id, token, expires_at, created_at
		FROM refresh_tokens
		WHERE token = $1
	`

	refreshToken := &models.RefreshToken{}
	err := r.db.QueryRow(query, token).Scan(
		&refreshToken.ID,
		&refreshToken.UserID,
		&refreshToken.Token,
		&refreshToken.ExpiresAt,
		&refreshToken.CreatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("refresh token not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find refresh token: %w", err)
	}

	return refreshToken, nil
}

// DeleteRefreshToken deletes a refresh token
func (r *AuthRepository) DeleteRefreshToken(token string) error {
	query := `DELETE FROM refresh_tokens WHERE token = $1`

	result, err := r.db.Exec(query, token)
	if err != nil {
		return fmt.Errorf("failed to delete refresh token: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("refresh token not found")
	}

	return nil
}

// DeleteUserRefreshTokens deletes all refresh tokens for a user
func (r *AuthRepository) DeleteUserRefreshTokens(userID int64) error {
	query := `DELETE FROM refresh_tokens WHERE user_id = $1`

	_, err := r.db.Exec(query, userID)
	if err != nil {
		return fmt.Errorf("failed to delete user refresh tokens: %w", err)
	}

	return nil
}

// DeleteExpiredTokens deletes all expired refresh tokens
func (r *AuthRepository) DeleteExpiredTokens() error {
	query := `DELETE FROM refresh_tokens WHERE expires_at < $1`

	_, err := r.db.Exec(query, time.Now())
	if err != nil {
		return fmt.Errorf("failed to delete expired tokens: %w", err)
	}

	return nil
}
