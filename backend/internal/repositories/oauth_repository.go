package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/lib/pq"

	"github.com/khchoi-tnh/timingle/internal/models"
)

// OAuthRepository handles OAuth account data operations
type OAuthRepository struct {
	db *sql.DB
}

// NewOAuthRepository creates a new OAuth repository
func NewOAuthRepository(db *sql.DB) *OAuthRepository {
	return &OAuthRepository{db: db}
}

// FindByProviderUserID finds an OAuth account by provider and provider user ID
func (r *OAuthRepository) FindByProviderUserID(provider models.OAuthProvider, providerUserID string) (*models.OAuthAccount, error) {
	query := `
		SELECT id, user_id, provider, provider_user_id, email, name, picture_url,
		       access_token, refresh_token, token_expiry, scopes,
		       created_at, updated_at
		FROM oauth_accounts
		WHERE provider = $1 AND provider_user_id = $2
	`

	account := &models.OAuthAccount{}
	var scopes pq.StringArray
	err := r.db.QueryRow(query, provider, providerUserID).Scan(
		&account.ID,
		&account.UserID,
		&account.Provider,
		&account.ProviderUserID,
		&account.Email,
		&account.Name,
		&account.PictureURL,
		&account.AccessToken,
		&account.RefreshToken,
		&account.TokenExpiry,
		&scopes,
		&account.CreatedAt,
		&account.UpdatedAt,
	)
	account.Scopes = []string(scopes)

	if err == sql.ErrNoRows {
		return nil, nil // Not found
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find OAuth account: %w", err)
	}

	return account, nil
}

// FindByUserID finds all OAuth accounts linked to a user
func (r *OAuthRepository) FindByUserID(userID int64) ([]*models.OAuthAccount, error) {
	query := `
		SELECT id, user_id, provider, provider_user_id, email, name, picture_url,
		       access_token, refresh_token, token_expiry, scopes,
		       created_at, updated_at
		FROM oauth_accounts
		WHERE user_id = $1
		ORDER BY created_at ASC
	`

	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to find OAuth accounts: %w", err)
	}
	defer rows.Close()

	accounts := []*models.OAuthAccount{}
	for rows.Next() {
		account := &models.OAuthAccount{}
		var scopes pq.StringArray
		err := rows.Scan(
			&account.ID,
			&account.UserID,
			&account.Provider,
			&account.ProviderUserID,
			&account.Email,
			&account.Name,
			&account.PictureURL,
			&account.AccessToken,
			&account.RefreshToken,
			&account.TokenExpiry,
			&scopes,
			&account.CreatedAt,
			&account.UpdatedAt,
		)
		account.Scopes = []string(scopes)
		if err != nil {
			return nil, fmt.Errorf("failed to scan OAuth account: %w", err)
		}
		accounts = append(accounts, account)
	}

	return accounts, nil
}

// Create creates a new OAuth account link
func (r *OAuthRepository) Create(account *models.OAuthAccount) error {
	query := `
		INSERT INTO oauth_accounts (user_id, provider, provider_user_id, email, name, picture_url,
		                            access_token, refresh_token, token_expiry, scopes)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, created_at, updated_at
	`

	err := r.db.QueryRow(
		query,
		account.UserID,
		account.Provider,
		account.ProviderUserID,
		account.Email,
		account.Name,
		account.PictureURL,
		account.AccessToken,
		account.RefreshToken,
		account.TokenExpiry,
		pq.Array(account.Scopes),
	).Scan(&account.ID, &account.CreatedAt, &account.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to create OAuth account: %w", err)
	}

	return nil
}

// Update updates an OAuth account's profile information
func (r *OAuthRepository) Update(account *models.OAuthAccount) error {
	query := `
		UPDATE oauth_accounts
		SET email = $1, name = $2, picture_url = $3, updated_at = NOW()
		WHERE id = $4
		RETURNING updated_at
	`

	err := r.db.QueryRow(
		query,
		account.Email,
		account.Name,
		account.PictureURL,
		account.ID,
	).Scan(&account.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to update OAuth account: %w", err)
	}

	return nil
}

// Delete removes an OAuth account link
func (r *OAuthRepository) Delete(id int64) error {
	query := `DELETE FROM oauth_accounts WHERE id = $1`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete OAuth account: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("OAuth account not found")
	}

	return nil
}

// DeleteByUserIDAndProvider removes a specific OAuth provider link for a user
func (r *OAuthRepository) DeleteByUserIDAndProvider(userID int64, provider models.OAuthProvider) error {
	query := `DELETE FROM oauth_accounts WHERE user_id = $1 AND provider = $2`

	result, err := r.db.Exec(query, userID, provider)
	if err != nil {
		return fmt.Errorf("failed to delete OAuth account: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("OAuth account not found")
	}

	return nil
}

// UpdateTokens updates OAuth tokens for an account
func (r *OAuthRepository) UpdateTokens(accountID int64, accessToken, refreshToken *string, tokenExpiry *time.Time, scopes []string) error {
	query := `
		UPDATE oauth_accounts
		SET access_token = $1, refresh_token = $2, token_expiry = $3, scopes = $4, updated_at = NOW()
		WHERE id = $5
	`

	result, err := r.db.Exec(query, accessToken, refreshToken, tokenExpiry, pq.Array(scopes), accountID)
	if err != nil {
		return fmt.Errorf("failed to update OAuth tokens: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("OAuth account not found")
	}

	return nil
}

// FindByUserIDAndProvider finds an OAuth account by user ID and provider
func (r *OAuthRepository) FindByUserIDAndProvider(userID int64, provider models.OAuthProvider) (*models.OAuthAccount, error) {
	query := `
		SELECT id, user_id, provider, provider_user_id, email, name, picture_url,
		       access_token, refresh_token, token_expiry, scopes,
		       created_at, updated_at
		FROM oauth_accounts
		WHERE user_id = $1 AND provider = $2
	`

	account := &models.OAuthAccount{}
	var scopes pq.StringArray
	err := r.db.QueryRow(query, userID, provider).Scan(
		&account.ID,
		&account.UserID,
		&account.Provider,
		&account.ProviderUserID,
		&account.Email,
		&account.Name,
		&account.PictureURL,
		&account.AccessToken,
		&account.RefreshToken,
		&account.TokenExpiry,
		&scopes,
		&account.CreatedAt,
		&account.UpdatedAt,
	)
	account.Scopes = []string(scopes)

	if err == sql.ErrNoRows {
		return nil, nil // Not found
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find OAuth account: %w", err)
	}

	return account, nil
}

// FindAccountsWithCalendarScope finds all OAuth accounts that have Calendar scope
func (r *OAuthRepository) FindAccountsWithCalendarScope() ([]*models.OAuthAccount, error) {
	query := `
		SELECT id, user_id, provider, provider_user_id, email, name, picture_url,
		       access_token, refresh_token, token_expiry, scopes,
		       created_at, updated_at
		FROM oauth_accounts
		WHERE 'https://www.googleapis.com/auth/calendar' = ANY(scopes)
		   OR 'https://www.googleapis.com/auth/calendar.events' = ANY(scopes)
	`

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to find OAuth accounts with calendar scope: %w", err)
	}
	defer rows.Close()

	accounts := []*models.OAuthAccount{}
	for rows.Next() {
		account := &models.OAuthAccount{}
		var scopes pq.StringArray
		err := rows.Scan(
			&account.ID,
			&account.UserID,
			&account.Provider,
			&account.ProviderUserID,
			&account.Email,
			&account.Name,
			&account.PictureURL,
			&account.AccessToken,
			&account.RefreshToken,
			&account.TokenExpiry,
			&scopes,
			&account.CreatedAt,
			&account.UpdatedAt,
		)
		account.Scopes = []string(scopes)
		if err != nil {
			return nil, fmt.Errorf("failed to scan OAuth account: %w", err)
		}
		accounts = append(accounts, account)
	}

	return accounts, nil
}
