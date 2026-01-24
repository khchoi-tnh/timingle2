package repositories

import (
	"crypto/rand"
	"database/sql"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/khchoi-tnh/timingle/internal/models"
)

// InviteRepository handles invite link data operations
type InviteRepository struct {
	db *sql.DB
}

// NewInviteRepository creates a new invite repository
func NewInviteRepository(db *sql.DB) *InviteRepository {
	return &InviteRepository{db: db}
}

// generateCode generates a random invite code
func generateCode() (string, error) {
	bytes := make([]byte, 6) // 6 bytes = 8 chars in base64
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	// Use URL-safe base64 encoding and trim padding
	code := base64.RawURLEncoding.EncodeToString(bytes)
	return code, nil
}

// Create creates a new invite link
func (r *InviteRepository) Create(eventID, createdBy int64, expiresAt *time.Time, maxUses int) (*models.InviteLink, error) {
	code, err := generateCode()
	if err != nil {
		return nil, fmt.Errorf("failed to generate invite code: %w", err)
	}

	query := `
		INSERT INTO event_invite_links (event_id, code, created_by, expires_at, max_uses)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at
	`

	link := &models.InviteLink{
		EventID:   eventID,
		Code:      code,
		CreatedBy: createdBy,
		ExpiresAt: expiresAt,
		MaxUses:   maxUses,
		UseCount:  0,
		IsActive:  true,
	}

	err = r.db.QueryRow(query, eventID, code, createdBy, expiresAt, maxUses).Scan(&link.ID, &link.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create invite link: %w", err)
	}

	return link, nil
}

// FindByCode finds an invite link by code
func (r *InviteRepository) FindByCode(code string) (*models.InviteLink, error) {
	query := `
		SELECT id, event_id, code, created_by, expires_at, max_uses, use_count, is_active, created_at
		FROM event_invite_links
		WHERE code = $1
	`

	link := &models.InviteLink{}
	err := r.db.QueryRow(query, code).Scan(
		&link.ID,
		&link.EventID,
		&link.Code,
		&link.CreatedBy,
		&link.ExpiresAt,
		&link.MaxUses,
		&link.UseCount,
		&link.IsActive,
		&link.CreatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find invite link: %w", err)
	}

	return link, nil
}

// IncrementUseCount increments the use count of an invite link
func (r *InviteRepository) IncrementUseCount(id int64) error {
	query := `UPDATE event_invite_links SET use_count = use_count + 1 WHERE id = $1`

	_, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to increment use count: %w", err)
	}

	return nil
}

// Deactivate deactivates an invite link
func (r *InviteRepository) Deactivate(id int64) error {
	query := `UPDATE event_invite_links SET is_active = false WHERE id = $1`

	_, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to deactivate invite link: %w", err)
	}

	return nil
}

// FindByEventID finds all invite links for an event
func (r *InviteRepository) FindByEventID(eventID int64) ([]*models.InviteLink, error) {
	query := `
		SELECT id, event_id, code, created_by, expires_at, max_uses, use_count, is_active, created_at
		FROM event_invite_links
		WHERE event_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.db.Query(query, eventID)
	if err != nil {
		return nil, fmt.Errorf("failed to find invite links: %w", err)
	}
	defer rows.Close()

	links := []*models.InviteLink{}
	for rows.Next() {
		link := &models.InviteLink{}
		err := rows.Scan(
			&link.ID,
			&link.EventID,
			&link.Code,
			&link.CreatedBy,
			&link.ExpiresAt,
			&link.MaxUses,
			&link.UseCount,
			&link.IsActive,
			&link.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan invite link: %w", err)
		}
		links = append(links, link)
	}

	return links, nil
}

// AddParticipantWithDetails adds a participant with invite details
func (r *InviteRepository) AddParticipantWithDetails(eventID, userID, invitedBy int64, method string) error {
	query := `
		INSERT INTO event_participants (event_id, user_id, status, invited_by, invited_at, invite_method)
		VALUES ($1, $2, $3, $4, NOW(), $5)
		ON CONFLICT (event_id, user_id) DO NOTHING
	`

	_, err := r.db.Exec(query, eventID, userID, models.ParticipantStatusPending, invitedBy, method)
	if err != nil {
		return fmt.Errorf("failed to add participant: %w", err)
	}

	return nil
}

// UpdateParticipantStatus updates participant status
func (r *InviteRepository) UpdateParticipantStatus(eventID, userID int64, status string) error {
	query := `
		UPDATE event_participants
		SET status = $1, responded_at = NOW()
		WHERE event_id = $2 AND user_id = $3
	`

	result, err := r.db.Exec(query, status, eventID, userID)
	if err != nil {
		return fmt.Errorf("failed to update participant status: %w", err)
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		return fmt.Errorf("participant not found")
	}

	return nil
}

// IsUserParticipant checks if user is already a participant
func (r *InviteRepository) IsUserParticipant(eventID, userID int64) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM event_participants WHERE event_id = $1 AND user_id = $2)`

	var exists bool
	err := r.db.QueryRow(query, eventID, userID).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("failed to check participant: %w", err)
	}

	return exists, nil
}
