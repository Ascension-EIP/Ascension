// @date 2026-11-12
// @file climbing_session.go
// @brief HTTP request DTOs of the climbing session endpoints.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

// StartClimbingSession is the body of POST /v1/sessions. Every field is optional.
type StartClimbingSession struct {
	GymID      *uuid.UUID `json:"gym_id"`
	Title      *string    `json:"title"`
	Notes      *string    `json:"notes"`
	StartedAt  *time.Time `json:"started_at"`
	Visibility *string    `json:"visibility"`
}

// IntoClimbingSessionConfig converts the body; the visibility defaults to private.
func (req StartClimbingSession) IntoClimbingSessionConfig() model.ClimbingSessionConfig {
	visibility := model.VisibilityPrivate
	if req.Visibility != nil {
		visibility = model.Visibility(*req.Visibility)
	}

	return model.ClimbingSessionConfig{
		GymID:      req.GymID,
		Title:      req.Title,
		Notes:      req.Notes,
		StartedAt:  req.StartedAt,
		Visibility: visibility,
	}
}

// PageQuery is the pagination query string of the list endpoints (?limit=&offset=).
type PageQuery struct {
	Limit  *int `form:"limit"`
	Offset *int `form:"offset"`
}

// IntoPagination converts the query string, applying the default page size.
func (req PageQuery) IntoPagination() (model.Pagination, error) {
	return model.NewPagination(req.Limit, req.Offset)
}

// AddAnalysisToClimbingSession is the body of POST /v1/sessions/:id/analyses.
type AddAnalysisToClimbingSession struct {
	AnalysisID *uuid.UUID `json:"analysis_id" binding:"required"`
}

// UpdateClimbingSession is the body of PUT /v1/sessions/:id. An absent field is left
// unchanged and null clears it: "ended_at": null reopens an ended session.
type UpdateClimbingSession struct {
	Title   Optional[string]    `json:"title"`
	Notes   Optional[string]    `json:"notes"`
	EndedAt Optional[time.Time] `json:"ended_at"`
}

// IntoPartial converts the body into a partial update of the user's session.
func (req UpdateClimbingSession) IntoPartial(id uuid.UUID, userID uuid.UUID) model.ClimbingSessionPartial {
	return model.ClimbingSessionPartial{
		ID:      id,
		UserID:  userID,
		Title:   req.Title.Patch(),
		Notes:   req.Notes.Patch(),
		EndedAt: req.EndedAt.Patch(),
	}
}
