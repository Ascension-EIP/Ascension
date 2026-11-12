// @date 2026-11-12
// @file climbing_session.go
// @brief Climbing session domain types: one climbing outing grouping its videos and analyses.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"fmt"
	"strings"
	"time"

	"uuid"
)

const (
	ClimbingSessionTitleMaxLen = 255
	ClimbingSessionNotesMaxLen = 5000
)

// -- Input type -- //

// ClimbingSessionConfig holds what the client sends to start a climbing session.
// A nil StartedAt means "now".
type ClimbingSessionConfig struct {
	GymID      *uuid.UUID
	Title      *string
	Notes      *string
	StartedAt  *time.Time
	Visibility Visibility
}

// Validate checks the client values of a new climbing session.
func (c ClimbingSessionConfig) Validate() error {
	if err := validateClimbingSessionText(c.Title, c.Notes); err != nil {
		return err
	}

	if err := c.Visibility.Validate(); err != nil {
		return fmt.Errorf("%w: visibility: %w", ErrInvalidInput, err)
	}

	return nil
}

// -- Working type -- //

// ClimbingSession mirrors a climbing_sessions row.
type ClimbingSession struct {
	ID             uuid.UUID
	UserID         uuid.UUID
	GymID          *uuid.UUID
	Title          *string
	StartedAt      time.Time
	EndedAt        *time.Time
	OverallScore   *float64
	TechniqueScore *float64
	PowerScore     *float64
	EnduranceScore *float64
	ScoredAt       *time.Time
	Notes          *string
	Visibility     Visibility
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

// ClimbingSessionFilter selects climbing sessions; nil fields are ignored.
type ClimbingSessionFilter struct {
	ID     *uuid.UUID
	UserID *uuid.UUID
}

// ClimbingSessionPartial is a partial update of a climbing session owned by UserID.
// A nil field is left unchanged; a field pointing to nil is cleared.
type ClimbingSessionPartial struct {
	ID      uuid.UUID
	UserID  uuid.UUID
	Title   **string
	Notes   **string
	EndedAt **time.Time
}

// IsEmpty reports whether the partial changes nothing.
func (p ClimbingSessionPartial) IsEmpty() bool {
	return p.Title == nil && p.Notes == nil && p.EndedAt == nil
}

// Validate checks the partial against the session it updates.
func (p ClimbingSessionPartial) Validate(session ClimbingSession) error {
	var title, notes *string
	if p.Title != nil {
		title = *p.Title
	}
	if p.Notes != nil {
		notes = *p.Notes
	}
	if err := validateClimbingSessionText(title, notes); err != nil {
		return err
	}

	if p.EndedAt != nil && *p.EndedAt != nil && (*p.EndedAt).Before(session.StartedAt) {
		return fmt.Errorf("%w: ended_at: before started_at", ErrInvalidInput)
	}

	return nil
}

func validateClimbingSessionText(title *string, notes *string) error {
	if title != nil {
		if err := validateStringLen(strings.TrimSpace(*title), 1, ClimbingSessionTitleMaxLen); err != nil {
			return fmt.Errorf("%w: title: %w", ErrInvalidInput, err)
		}
	}

	if notes != nil {
		if err := validateStringLen(*notes, 0, ClimbingSessionNotesMaxLen); err != nil {
			return fmt.Errorf("%w: notes: %w", ErrInvalidInput, err)
		}
	}

	return nil
}

// -- Output type -- //

// ClimbingSessionDetails is a climbing session with the analyses linked to it.
type ClimbingSessionDetails struct {
	Session  ClimbingSession
	Analyses []AnalysisSummary
}

// ClimbingSessionPage is one page of a user's climbing sessions.
type ClimbingSessionPage struct {
	Sessions   []ClimbingSession
	Total      int
	Pagination Pagination
}
