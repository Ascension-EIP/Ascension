// @date 2026-11-13
// @file user_body_constraint.go
// @brief Body of POST /v1/profile/constraints.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

// DeclareUserBodyConstraint is the body of POST /v1/profile/constraints. zone and type are
// required; started_at defaults to today and only its date is kept.
type DeclareUserBodyConstraint struct {
	Zone      *string    `json:"zone" binding:"required"`
	Type      *string    `json:"type" binding:"required"`
	Note      *string    `json:"note"`
	StartedAt *time.Time `json:"started_at"`
}

// IntoUserBodyConstraintConfig converts the body; the values are validated by the model.
func (req DeclareUserBodyConstraint) IntoUserBodyConstraintConfig() model.UserBodyConstraintConfig {
	config := model.UserBodyConstraintConfig{Note: req.Note, StartedAt: req.StartedAt}
	if req.Zone != nil {
		config.Zone = model.BodyZone(*req.Zone)
	}
	if req.Type != nil {
		config.Type = model.BodyConstraintType(*req.Type)
	}

	return config
}
