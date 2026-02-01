package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/lib/pq"
)

// UserRepository handles user data operations
type UserRepository struct {
	db *sql.DB
}

// NewUserRepository creates a new user repository
func NewUserRepository(db *sql.DB) *UserRepository {
	return &UserRepository{db: db}
}

// Create creates a new user
func (r *UserRepository) Create(user *models.User) error {
	query := `
		INSERT INTO users (phone, name, email, profile_image_url, region, interests, timezone, language, role)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING id, created_at, updated_at
	`

	err := r.db.QueryRow(
		query,
		user.Phone,
		user.Name,
		user.Email,
		user.ProfileImageURL,
		user.Region,
		pq.Array(user.Interests),
		user.Timezone,
		user.Language,
		user.Role,
	).Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to create user: %w", err)
	}

	return nil
}

// FindByID finds a user by ID
func (r *UserRepository) FindByID(id int64) (*models.User, error) {
	query := `
		SELECT id, phone, name, email, profile_image_url, region, interests, timezone, language, role, created_at, updated_at
		FROM users
		WHERE id = $1
	`

	user := &models.User{}
	err := r.db.QueryRow(query, id).Scan(
		&user.ID,
		&user.Phone,
		&user.Name,
		&user.Email,
		&user.ProfileImageURL,
		&user.Region,
		pq.Array(&user.Interests),
		&user.Timezone,
		&user.Language,
		&user.Role,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find user: %w", err)
	}

	return user, nil
}

// FindByPhone finds a user by phone number
func (r *UserRepository) FindByPhone(phone string) (*models.User, error) {
	query := `
		SELECT id, phone, name, email, profile_image_url, region, interests, timezone, language, role, created_at, updated_at
		FROM users
		WHERE phone = $1
	`

	user := &models.User{}
	err := r.db.QueryRow(query, phone).Scan(
		&user.ID,
		&user.Phone,
		&user.Name,
		&user.Email,
		&user.ProfileImageURL,
		&user.Region,
		pq.Array(&user.Interests),
		&user.Timezone,
		&user.Language,
		&user.Role,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find user by phone: %w", err)
	}

	return user, nil
}

// Update updates a user
func (r *UserRepository) Update(user *models.User) error {
	query := `
		UPDATE users
		SET name = $1, email = $2, profile_image_url = $3, region = $4, interests = $5,
		    timezone = $6, language = $7, updated_at = NOW()
		WHERE id = $8
		RETURNING updated_at
	`

	err := r.db.QueryRow(
		query,
		user.Name,
		user.Email,
		user.ProfileImageURL,
		user.Region,
		pq.Array(user.Interests),
		user.Timezone,
		user.Language,
		user.ID,
	).Scan(&user.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	return nil
}

// Delete deletes a user
func (r *UserRepository) Delete(id int64) error {
	query := `DELETE FROM users WHERE id = $1`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user not found")
	}

	return nil
}

// FindByIDs finds multiple users by their IDs
func (r *UserRepository) FindByIDs(ids []int64) ([]*models.User, error) {
	if len(ids) == 0 {
		return []*models.User{}, nil
	}

	query := `
		SELECT id, phone, name, email, profile_image_url, region, interests, timezone, language, role, created_at, updated_at
		FROM users
		WHERE id = ANY($1)
	`

	rows, err := r.db.Query(query, pq.Array(ids))
	if err != nil {
		return nil, fmt.Errorf("failed to find users by IDs: %w", err)
	}
	defer rows.Close()

	users := []*models.User{}
	for rows.Next() {
		user := &models.User{}
		err := rows.Scan(
			&user.ID,
			&user.Phone,
			&user.Name,
			&user.Email,
			&user.ProfileImageURL,
			&user.Region,
			pq.Array(&user.Interests),
			&user.Timezone,
			&user.Language,
			&user.Role,
			&user.CreatedAt,
			&user.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}
		users = append(users, user)
	}

	return users, nil
}

// FindByEmail finds a user by email address
func (r *UserRepository) FindByEmail(email string) (*models.User, error) {
	query := `
		SELECT id, phone, name, email, profile_image_url, region, interests, timezone, language, role, created_at, updated_at
		FROM users
		WHERE email = $1
	`

	user := &models.User{}
	err := r.db.QueryRow(query, email).Scan(
		&user.ID,
		&user.Phone,
		&user.Name,
		&user.Email,
		&user.ProfileImageURL,
		&user.Region,
		pq.Array(&user.Interests),
		&user.Timezone,
		&user.Language,
		&user.Role,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, nil // Return nil, nil to indicate "not found" without error
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find user by email: %w", err)
	}

	return user, nil
}

// CreateOAuthUser creates a new user from OAuth provider data
func (r *UserRepository) CreateOAuthUser(email, name, pictureURL string) (*models.User, error) {
	// Generate a unique phone placeholder for OAuth users (they don't have phone numbers)
	// Format: oauth_<timestamp> to ensure uniqueness
	phonePlaceholder := fmt.Sprintf("oauth_%d", time.Now().UnixNano())

	user := &models.User{
		Phone:           phonePlaceholder,
		Name:            &name,
		Email:           &email,
		ProfileImageURL: &pictureURL,
		Timezone:        "UTC",
		Language:        "ko",
		Role:            models.UserRoleUser,
	}

	if err := r.Create(user); err != nil {
		return nil, fmt.Errorf("failed to create OAuth user: %w", err)
	}

	return user, nil
}
