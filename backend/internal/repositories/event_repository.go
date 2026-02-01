package repositories

import (
	"database/sql"
	"fmt"

	"github.com/khchoi-tnh/timingle/internal/models"
)

// EventRepository handles event data operations
type EventRepository struct {
	db *sql.DB
}

// NewEventRepository creates a new event repository
func NewEventRepository(db *sql.DB) *EventRepository {
	return &EventRepository{db: db}
}

// Create creates a new event
func (r *EventRepository) Create(event *models.Event) error {
	query := `
		INSERT INTO events (title, description, start_time, end_time, location, creator_id, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at
	`

	err := r.db.QueryRow(
		query,
		event.Title,
		event.Description,
		event.StartTime,
		event.EndTime,
		event.Location,
		event.CreatorID,
		event.Status,
	).Scan(&event.ID, &event.CreatedAt, &event.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to create event: %w", err)
	}

	return nil
}

// FindByID finds an event by ID
func (r *EventRepository) FindByID(id int64) (*models.Event, error) {
	query := `
		SELECT id, title, description, start_time, end_time, location, creator_id, status, google_calendar_id, created_at, updated_at
		FROM events
		WHERE id = $1
	`

	event := &models.Event{}
	err := r.db.QueryRow(query, id).Scan(
		&event.ID,
		&event.Title,
		&event.Description,
		&event.StartTime,
		&event.EndTime,
		&event.Location,
		&event.CreatorID,
		&event.Status,
		&event.GoogleCalendarID,
		&event.CreatedAt,
		&event.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("event not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find event: %w", err)
	}

	return event, nil
}

// FindByCreatorID finds events by creator ID
func (r *EventRepository) FindByCreatorID(creatorID int64, status string) ([]*models.Event, error) {
	var query string
	var rows *sql.Rows
	var err error

	if status != "" {
		query = `
			SELECT id, title, description, start_time, end_time, location, creator_id, status, created_at, updated_at
			FROM events
			WHERE creator_id = $1 AND status = $2
			ORDER BY start_time DESC
		`
		rows, err = r.db.Query(query, creatorID, status)
	} else {
		query = `
			SELECT id, title, description, start_time, end_time, location, creator_id, status, created_at, updated_at
			FROM events
			WHERE creator_id = $1
			ORDER BY start_time DESC
		`
		rows, err = r.db.Query(query, creatorID)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to find events by creator: %w", err)
	}
	defer rows.Close()

	events := []*models.Event{}
	for rows.Next() {
		event := &models.Event{}
		err := rows.Scan(
			&event.ID,
			&event.Title,
			&event.Description,
			&event.StartTime,
			&event.EndTime,
			&event.Location,
			&event.CreatorID,
			&event.Status,
			&event.CreatedAt,
			&event.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan event: %w", err)
		}
		events = append(events, event)
	}

	return events, nil
}

// FindByParticipantID finds events where user is a participant
func (r *EventRepository) FindByParticipantID(userID int64, status string) ([]*models.Event, error) {
	var query string
	var rows *sql.Rows
	var err error

	if status != "" {
		query = `
			SELECT e.id, e.title, e.description, e.start_time, e.end_time, e.location, e.creator_id, e.status, e.created_at, e.updated_at
			FROM events e
			INNER JOIN event_participants ep ON e.id = ep.event_id
			WHERE ep.user_id = $1 AND e.status = $2
			ORDER BY e.start_time DESC
		`
		rows, err = r.db.Query(query, userID, status)
	} else {
		query = `
			SELECT e.id, e.title, e.description, e.start_time, e.end_time, e.location, e.creator_id, e.status, e.created_at, e.updated_at
			FROM events e
			INNER JOIN event_participants ep ON e.id = ep.event_id
			WHERE ep.user_id = $1
			ORDER BY e.start_time DESC
		`
		rows, err = r.db.Query(query, userID)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to find events by participant: %w", err)
	}
	defer rows.Close()

	events := []*models.Event{}
	for rows.Next() {
		event := &models.Event{}
		err := rows.Scan(
			&event.ID,
			&event.Title,
			&event.Description,
			&event.StartTime,
			&event.EndTime,
			&event.Location,
			&event.CreatorID,
			&event.Status,
			&event.CreatedAt,
			&event.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan event: %w", err)
		}
		events = append(events, event)
	}

	return events, nil
}

// Update updates an event
func (r *EventRepository) Update(event *models.Event) error {
	query := `
		UPDATE events
		SET title = $1, description = $2, start_time = $3, end_time = $4, location = $5, status = $6
		WHERE id = $7
		RETURNING updated_at
	`

	err := r.db.QueryRow(
		query,
		event.Title,
		event.Description,
		event.StartTime,
		event.EndTime,
		event.Location,
		event.Status,
		event.ID,
	).Scan(&event.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to update event: %w", err)
	}

	return nil
}

// Delete deletes an event
func (r *EventRepository) Delete(id int64) error {
	query := `DELETE FROM events WHERE id = $1`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete event: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("event not found")
	}

	return nil
}

// AddParticipant adds a participant to an event
func (r *EventRepository) AddParticipant(eventID, userID int64) error {
	query := `
		INSERT INTO event_participants (event_id, user_id, confirmed)
		VALUES ($1, $2, false)
	`

	_, err := r.db.Exec(query, eventID, userID)
	if err != nil {
		return fmt.Errorf("failed to add participant: %w", err)
	}

	return nil
}

// RemoveParticipant removes a participant from an event
func (r *EventRepository) RemoveParticipant(eventID, userID int64) error {
	query := `DELETE FROM event_participants WHERE event_id = $1 AND user_id = $2`

	result, err := r.db.Exec(query, eventID, userID)
	if err != nil {
		return fmt.Errorf("failed to remove participant: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("participant not found")
	}

	return nil
}

// ConfirmParticipant confirms a participant for an event
func (r *EventRepository) ConfirmParticipant(eventID, userID int64) error {
	query := `
		UPDATE event_participants
		SET confirmed = true, confirmed_at = NOW()
		WHERE event_id = $1 AND user_id = $2
	`

	result, err := r.db.Exec(query, eventID, userID)
	if err != nil {
		return fmt.Errorf("failed to confirm participant: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("participant not found")
	}

	return nil
}

// FindParticipants finds all participants for an event
func (r *EventRepository) FindParticipants(eventID int64) ([]int64, error) {
	query := `SELECT user_id FROM event_participants WHERE event_id = $1`

	rows, err := r.db.Query(query, eventID)
	if err != nil {
		return nil, fmt.Errorf("failed to find participants: %w", err)
	}
	defer rows.Close()

	userIDs := []int64{}
	for rows.Next() {
		var userID int64
		if err := rows.Scan(&userID); err != nil {
			return nil, fmt.Errorf("failed to scan participant: %w", err)
		}
		userIDs = append(userIDs, userID)
	}

	return userIDs, nil
}

// IsUserParticipant checks if a user is a participant of an event
func (r *EventRepository) IsUserParticipant(eventID, userID int64) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM event_participants WHERE event_id = $1 AND user_id = $2)`

	var exists bool
	err := r.db.QueryRow(query, eventID, userID).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("failed to check participant: %w", err)
	}

	return exists, nil
}

// UpdateGoogleCalendarID updates the Google Calendar ID for an event
func (r *EventRepository) UpdateGoogleCalendarID(eventID int64, calendarID string) error {
	query := `
		UPDATE events
		SET google_calendar_id = $1, updated_at = NOW()
		WHERE id = $2
	`

	result, err := r.db.Exec(query, calendarID, eventID)
	if err != nil {
		return fmt.Errorf("failed to update Google Calendar ID: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("event not found")
	}

	return nil
}

// FindByGoogleCalendarID finds an event by Google Calendar ID
func (r *EventRepository) FindByGoogleCalendarID(calendarID string) (*models.Event, error) {
	query := `
		SELECT id, title, description, start_time, end_time, location, creator_id, status, google_calendar_id, created_at, updated_at
		FROM events
		WHERE google_calendar_id = $1
	`

	event := &models.Event{}
	err := r.db.QueryRow(query, calendarID).Scan(
		&event.ID,
		&event.Title,
		&event.Description,
		&event.StartTime,
		&event.EndTime,
		&event.Location,
		&event.CreatorID,
		&event.Status,
		&event.GoogleCalendarID,
		&event.CreatedAt,
		&event.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, nil // Not found
	}
	if err != nil {
		return nil, fmt.Errorf("failed to find event by Google Calendar ID: %w", err)
	}

	return event, nil
}
