// @date 2026-11-13
// @file user_body_constraint.go
// @brief Row of the user_body_constraints table.
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

// UserBodyConstraint is a user_body_constraints row.
type UserBodyConstraint struct {
	ID        uuid.UUID                `db:"id"`
	UserID    uuid.UUID                `db:"user_id"`
	Zone      model.BodyZone           `db:"zone"`
	Type      model.BodyConstraintType `db:"type"`
	Note      *string                  `db:"note"`
	StartedAt time.Time                `db:"started_at"`
	EndedAt   *time.Time               `db:"ended_at"`
	CreatedAt time.Time                `db:"created_at"`
	UpdatedAt time.Time                `db:"updated_at"`
}

// UpsertedUserBodyConstraint is the row returned by an upsert, with whether it was inserted.
type UpsertedUserBodyConstraint struct {
	UserBodyConstraint
	Created bool `db:"created"`
}

// ToUserBodyConstraint converts the row to the domain model.
func (c UserBodyConstraint) ToUserBodyConstraint() model.UserBodyConstraint {
	return model.UserBodyConstraint{
		ID:        c.ID,
		UserID:    c.UserID,
		Zone:      c.Zone,
		Type:      c.Type,
		Note:      c.Note,
		StartedAt: c.StartedAt,
		EndedAt:   c.EndedAt,
		CreatedAt: c.CreatedAt,
		UpdatedAt: c.UpdatedAt,
	}
}

// UserBodyConstraintsToUserBodyConstraints converts rows to domain models.
func UserBodyConstraintsToUserBodyConstraints(rows []UserBodyConstraint) []model.UserBodyConstraint {
	constraints := make([]model.UserBodyConstraint, 0, len(rows))
	for _, row := range rows {
		constraints = append(constraints, row.ToUserBodyConstraint())
	}

	return constraints
}
