// @date 2026-11-12
// @file climbing_session.go
// @brief Database row of the climbing_sessions table and its conversion to the domain model.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

// ClimbingSession is a climbing_sessions row.
type ClimbingSession struct {
	ID             uuid.UUID        `db:"id"`
	UserID         uuid.UUID        `db:"user_id"`
	GymID          *uuid.UUID       `db:"gym_id"`
	Title          *string          `db:"title"`
	StartedAt      time.Time        `db:"started_at"`
	EndedAt        *time.Time       `db:"ended_at"`
	OverallScore   *float64         `db:"overall_score"`
	TechniqueScore *float64         `db:"technique_score"`
	PowerScore     *float64         `db:"power_score"`
	EnduranceScore *float64         `db:"endurance_score"`
	ScoredAt       *time.Time       `db:"scored_at"`
	Notes          *string          `db:"notes"`
	Visibility     model.Visibility `db:"visibility"`
	CreatedAt      time.Time        `db:"created_at"`
	UpdatedAt      time.Time        `db:"updated_at"`
}

// ToClimbingSession converts the row to the domain model.
func (s ClimbingSession) ToClimbingSession() model.ClimbingSession {
	return model.ClimbingSession{
		ID:             s.ID,
		UserID:         s.UserID,
		GymID:          s.GymID,
		Title:          s.Title,
		StartedAt:      s.StartedAt,
		EndedAt:        s.EndedAt,
		OverallScore:   s.OverallScore,
		TechniqueScore: s.TechniqueScore,
		PowerScore:     s.PowerScore,
		EnduranceScore: s.EnduranceScore,
		ScoredAt:       s.ScoredAt,
		Notes:          s.Notes,
		Visibility:     s.Visibility,
		CreatedAt:      s.CreatedAt,
		UpdatedAt:      s.UpdatedAt,
	}
}

// ClimbingSessionsToClimbingSessions converts rows to domain models.
func ClimbingSessionsToClimbingSessions(rows []ClimbingSession) []model.ClimbingSession {
	sessions := make([]model.ClimbingSession, 0, len(rows))
	for _, row := range rows {
		sessions = append(sessions, row.ToClimbingSession())
	}

	return sessions
}
