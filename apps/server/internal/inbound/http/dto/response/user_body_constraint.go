// @date 2026-11-13
// @file user_body_constraint.go
// @brief Body constraints as returned by the API.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package response

import (
	"time"
	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

// UserBodyConstraint is a body constraint as returned by the API. ended_at is null while
// the constraint is active.
type UserBodyConstraint struct {
	ID        uuid.UUID                `json:"id"`
	Zone      model.BodyZone           `json:"zone"`
	Type      model.BodyConstraintType `json:"type"`
	Note      *string                  `json:"note"`
	StartedAt time.Time                `json:"started_at"`
	EndedAt   *time.Time               `json:"ended_at"`
	CreatedAt time.Time                `json:"created_at"`
	UpdatedAt time.Time                `json:"updated_at"`
}

// UserBodyConstraintList is the body of GET /v1/profile/constraints.
type UserBodyConstraintList struct {
	Constraints []UserBodyConstraint `json:"constraints"`
}

// UserBodyConstraintToResponse converts a constraint.
func UserBodyConstraintToResponse(constraint model.UserBodyConstraint) UserBodyConstraint {
	return UserBodyConstraint{
		ID:        constraint.ID,
		Zone:      constraint.Zone,
		Type:      constraint.Type,
		Note:      constraint.Note,
		StartedAt: constraint.StartedAt,
		EndedAt:   constraint.EndedAt,
		CreatedAt: constraint.CreatedAt,
		UpdatedAt: constraint.UpdatedAt,
	}
}

// UserBodyConstraintsToResponse converts a list of constraints; an empty list stays [].
func UserBodyConstraintsToResponse(constraints []model.UserBodyConstraint) UserBodyConstraintList {
	list := UserBodyConstraintList{Constraints: make([]UserBodyConstraint, 0, len(constraints))}
	for _, constraint := range constraints {
		list.Constraints = append(list.Constraints, UserBodyConstraintToResponse(constraint))
	}

	return list
}
