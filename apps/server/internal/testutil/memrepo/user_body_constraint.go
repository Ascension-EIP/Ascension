// @date 2026-11-13
// @file user_body_constraint.go
// @brief In-memory body constraints, with the rules of the PostgreSQL queries.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package memrepo

import (
	"context"
	"slices"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

// UpsertActiveUserBodyConstraint creates the active constraint of the user on its zone, or
// replaces the one already active, like the ON CONFLICT query.
func (r *Repo) UpsertActiveUserBodyConstraint(_ context.Context, constraint model.UserBodyConstraint) (model.UserBodyConstraint, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := r.now()
	for id, stored := range r.bodyConstraints {
		if stored.UserID != constraint.UserID || stored.Zone != constraint.Zone || stored.EndedAt != nil {
			continue
		}
		stored.Type = constraint.Type
		stored.Note = constraint.Note
		if !constraint.StartedAt.IsZero() {
			stored.StartedAt = truncateToDate(constraint.StartedAt)
		}
		stored.UpdatedAt = now
		r.bodyConstraints[id] = stored
		return stored, false, nil
	}

	constraint.ID = uuid.NewV7()
	if constraint.StartedAt.IsZero() {
		constraint.StartedAt = now
	}
	constraint.StartedAt = truncateToDate(constraint.StartedAt)
	constraint.EndedAt = nil
	constraint.CreatedAt = now
	constraint.UpdatedAt = now
	r.bodyConstraints[constraint.ID] = constraint

	return constraint, true, nil
}

// ListActiveUserBodyConstraints returns the user's active constraints in the order of
// model.BodyZones (head to feet), like the body_zone enum.
func (r *Repo) ListActiveUserBodyConstraints(_ context.Context, userID uuid.UUID) ([]model.UserBodyConstraint, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	constraints := []model.UserBodyConstraint{}
	for _, constraint := range r.bodyConstraints {
		if constraint.UserID == userID && constraint.EndedAt == nil {
			constraints = append(constraints, constraint)
		}
	}
	slices.SortFunc(constraints, func(a, b model.UserBodyConstraint) int {
		return slices.Index(model.BodyZones, a.Zone) - slices.Index(model.BodyZones, b.Zone)
	})

	return constraints, nil
}

// GetActiveUserBodyConstraint returns one of the user's active constraints, or model.ErrNotFound.
func (r *Repo) GetActiveUserBodyConstraint(_ context.Context, id uuid.UUID, userID uuid.UUID) (model.UserBodyConstraint, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	constraint, ok := r.bodyConstraints[id]
	if !ok || constraint.UserID != userID || constraint.EndedAt != nil {
		return model.UserBodyConstraint{}, model.ErrNotFound
	}

	return constraint, nil
}

// EndUserBodyConstraint sets ended_at to today on one of the user's active constraints.
func (r *Repo) EndUserBodyConstraint(_ context.Context, id uuid.UUID, userID uuid.UUID) (model.UserBodyConstraint, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	constraint, ok := r.bodyConstraints[id]
	if !ok || constraint.UserID != userID || constraint.EndedAt != nil {
		return model.UserBodyConstraint{}, model.ErrNotFound
	}
	now := r.now()
	endedAt := truncateToDate(now)
	if endedAt.Before(constraint.StartedAt) {
		return model.UserBodyConstraint{}, model.ErrInvalidInput
	}
	constraint.EndedAt = &endedAt
	constraint.UpdatedAt = now
	r.bodyConstraints[id] = constraint

	return constraint, nil
}

// DeleteUserBodyConstraint deletes one of the user's constraints, or returns model.ErrNotFound.
func (r *Repo) DeleteUserBodyConstraint(_ context.Context, id uuid.UUID, userID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	constraint, ok := r.bodyConstraints[id]
	if !ok || constraint.UserID != userID {
		return model.ErrNotFound
	}
	delete(r.bodyConstraints, id)

	return nil
}

// UserBodyConstraints returns every stored constraint, ended ones included.
func (r *Repo) UserBodyConstraints() []model.UserBodyConstraint {
	r.mu.Lock()
	defer r.mu.Unlock()

	constraints := make([]model.UserBodyConstraint, 0, len(r.bodyConstraints))
	for _, constraint := range r.bodyConstraints {
		constraints = append(constraints, constraint)
	}

	return constraints
}

// truncateToDate keeps the UTC date of t, like a DATE column.
func truncateToDate(t time.Time) time.Time {
	year, month, day := t.UTC().Date()
	return time.Date(year, month, day, 0, 0, 0, 0, time.UTC)
}
