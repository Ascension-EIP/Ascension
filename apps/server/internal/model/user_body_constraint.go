// @date 2026-11-13
// @file user_body_constraint.go
// @brief Missing or injured body zones declared by a user (feature F01).
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"fmt"
	"time"

	"uuid"
)

// UserBodyConstraintNoteMaxLen is the longest note a constraint can carry.
const UserBodyConstraintNoteMaxLen = 1000

// BodyZone is a zone of the interactive skeleton, as in the body_zone database enum.
type BodyZone string

// BodyZones lists every zone of the body_zone database enum.
var BodyZones = []BodyZone{
	"head", "neck", "torso", "lower_back",
	"left_shoulder", "right_shoulder",
	"left_upper_arm", "right_upper_arm",
	"left_elbow", "right_elbow",
	"left_forearm", "right_forearm",
	"left_wrist", "right_wrist",
	"left_hand", "right_hand",
	"left_fingers", "right_fingers",
	"left_hip", "right_hip",
	"left_thigh", "right_thigh",
	"left_knee", "right_knee",
	"left_shin", "right_shin",
	"left_ankle", "right_ankle",
	"left_foot", "right_foot",
}

// Validate reports whether the zone is one of BodyZones.
func (z BodyZone) Validate() error {
	for _, zone := range BodyZones {
		if z == zone {
			return nil
		}
	}

	return fmt.Errorf("unknown body zone %q", string(z))
}

// BodyConstraintType is the kind of constraint, as in the body_constraint_type database enum.
type BodyConstraintType string

const (
	// BodyConstraintMissing is a missing limb or body part: it never ends.
	BodyConstraintMissing BodyConstraintType = "missing"
	// BodyConstraintInjured is an injury: it ends when it heals.
	BodyConstraintInjured BodyConstraintType = "injured"
)

// Validate reports whether the type is missing or injured.
func (t BodyConstraintType) Validate() error {
	switch t {
	case BodyConstraintMissing, BodyConstraintInjured:
		return nil
	default:
		return fmt.Errorf("unknown constraint type %q", string(t))
	}
}

// -- Input type -- //

// UserBodyConstraintConfig holds what the client sends to declare a constraint on a zone.
// A nil StartedAt means today.
type UserBodyConstraintConfig struct {
	Zone      BodyZone
	Type      BodyConstraintType
	Note      *string
	StartedAt *time.Time
}

// Validate checks the client values. now is the current time: a constraint cannot start
// later than the next day, which leaves room for the user's time zone.
func (c UserBodyConstraintConfig) Validate(now time.Time) error {
	if err := c.Zone.Validate(); err != nil {
		return fmt.Errorf("%w: zone: %w", ErrInvalidInput, err)
	}

	if err := c.Type.Validate(); err != nil {
		return fmt.Errorf("%w: type: %w", ErrInvalidInput, err)
	}

	if c.Note != nil {
		if err := validateStringLen(*c.Note, 0, UserBodyConstraintNoteMaxLen); err != nil {
			return fmt.Errorf("%w: note: %w", ErrInvalidInput, err)
		}
	}

	if c.StartedAt != nil && c.StartedAt.After(now.AddDate(0, 0, 1)) {
		return fmt.Errorf("%w: started_at: in the future", ErrInvalidInput)
	}

	return nil
}

// -- Working type -- //

// UserBodyConstraint mirrors a user_body_constraints row. It is active while EndedAt is nil;
// a user has at most one active constraint per zone.
type UserBodyConstraint struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Zone      BodyZone
	Type      BodyConstraintType
	Note      *string
	StartedAt time.Time
	EndedAt   *time.Time
	CreatedAt time.Time
	UpdatedAt time.Time
}
