// @date 2026-11-13
// @file user_body_constraint.go
// @brief Declaration and resolution of the users' missing or injured body zones.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"errors"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

// UserBodyConstraintService manages the body constraints of the calling user. A constraint
// owned by someone else is reported as model.ErrUserBodyConstraintNotFound.
type UserBodyConstraintService struct {
	repo model.UserBodyConstraintRepository
	now  func() time.Time
}

// NewUserBodyConstraintService builds a UserBodyConstraintService.
func NewUserBodyConstraintService(repo model.UserBodyConstraintRepository) UserBodyConstraintService {
	return UserBodyConstraintService{repo: repo, now: time.Now}
}

// ListActiveConstraints returns the user's active constraints, from head to feet.
func (s *UserBodyConstraintService) ListActiveConstraints(ctx context.Context, userID uuid.UUID) ([]model.UserBodyConstraint, error) {
	return s.repo.ListActiveUserBodyConstraints(ctx, userID)
}

// DeclareConstraint records a constraint on a zone. A zone has at most one active
// constraint: declaring it again replaces its type, note and start date. created is false
// on a replacement.
func (s *UserBodyConstraintService) DeclareConstraint(ctx context.Context, userID uuid.UUID, config model.UserBodyConstraintConfig) (model.UserBodyConstraint, bool, error) {
	if err := config.Validate(s.now()); err != nil {
		return model.UserBodyConstraint{}, false, err
	}

	constraint := model.UserBodyConstraint{
		UserID: userID,
		Zone:   config.Zone,
		Type:   config.Type,
		Note:   config.Note,
	}
	if config.StartedAt != nil {
		constraint.StartedAt = *config.StartedAt
	}

	return s.repo.UpsertActiveUserBodyConstraint(ctx, constraint)
}

// RemoveConstraint removes one of the user's active constraints. An injury is resolved:
// it ends today and stays in the history, which training programs use. A missing zone
// never ends, so removing it means it was declared by mistake: it is deleted.
func (s *UserBodyConstraintService) RemoveConstraint(ctx context.Context, id uuid.UUID, userID uuid.UUID) error {
	constraint, err := s.repo.GetActiveUserBodyConstraint(ctx, id, userID)
	if err != nil {
		return userBodyConstraintNotFound(err)
	}

	if constraint.Type == model.BodyConstraintInjured {
		_, err = s.repo.EndUserBodyConstraint(ctx, id, userID)
	} else {
		err = s.repo.DeleteUserBodyConstraint(ctx, id, userID)
	}

	return userBodyConstraintNotFound(err)
}

// userBodyConstraintNotFound turns the repository's generic model.ErrNotFound into
// model.ErrUserBodyConstraintNotFound.
func userBodyConstraintNotFound(err error) error {
	if errors.Is(err, model.ErrNotFound) {
		return model.ErrUserBodyConstraintNotFound
	}

	return err
}
