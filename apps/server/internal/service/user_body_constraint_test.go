// @date 2026-11-13
// @file user_body_constraint_test.go
// @brief Unit tests of the body constraint service.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

func mustDeclare(t *testing.T, s UserBodyConstraintService, userID uuid.UUID, config model.UserBodyConstraintConfig) (model.UserBodyConstraint, bool) {
	t.Helper()

	constraint, created, err := s.DeclareConstraint(context.Background(), userID, config)
	if err != nil {
		t.Fatalf("DeclareConstraint(%+v) error = %v", config, err)
	}

	return constraint, created
}

func TestDeclareConstraintCreatesThenReplaces(t *testing.T) {
	ctx := context.Background()
	s := NewUserBodyConstraintService(memrepo.New())
	userID := uuid.NewV7()
	startedAt := time.Date(2026, 10, 1, 0, 0, 0, 0, time.UTC)

	first, created := mustDeclare(t, s, userID, model.UserBodyConstraintConfig{Zone: "left_knee", Type: model.BodyConstraintInjured, StartedAt: &startedAt})
	if !created || first.Zone != "left_knee" || first.Type != model.BodyConstraintInjured || !first.StartedAt.Equal(startedAt) || first.EndedAt != nil {
		t.Fatalf("first declaration = %+v, created %v", first, created)
	}

	// Same zone again: the active constraint is replaced, its start date kept.
	note := "Sprain, healing"
	second, created := mustDeclare(t, s, userID, model.UserBodyConstraintConfig{Zone: "left_knee", Type: model.BodyConstraintInjured, Note: &note})
	if created || second.ID != first.ID || second.Note == nil || *second.Note != note || !second.StartedAt.Equal(startedAt) {
		t.Fatalf("second declaration = %+v, created %v, want the first one updated", second, created)
	}

	// Another zone is another constraint.
	if _, created := mustDeclare(t, s, userID, model.UserBodyConstraintConfig{Zone: "right_hand", Type: model.BodyConstraintMissing}); !created {
		t.Error("declaration on another zone: created = false, want true")
	}

	constraints, err := s.ListActiveConstraints(ctx, userID)
	if err != nil || len(constraints) != 2 {
		t.Fatalf("ListActiveConstraints() = %+v, %v, want 2 constraints", constraints, err)
	}
	// Head to feet: the hand comes before the knee.
	if constraints[0].Zone != "right_hand" || constraints[1].Zone != "left_knee" {
		t.Errorf("order = %s, %s, want right_hand, left_knee", constraints[0].Zone, constraints[1].Zone)
	}
}

func TestDeclareConstraintRejectsInvalidInput(t *testing.T) {
	repo := memrepo.New()
	s := NewUserBodyConstraintService(repo)

	for _, config := range []model.UserBodyConstraintConfig{
		{Zone: "elbow", Type: model.BodyConstraintInjured},
		{Zone: "left_elbow", Type: "missing_limb"},
	} {
		if _, _, err := s.DeclareConstraint(context.Background(), uuid.NewV7(), config); !errors.Is(err, model.ErrInvalidInput) {
			t.Errorf("DeclareConstraint(%+v) error = %v, want ErrInvalidInput", config, err)
		}
	}
	if stored := repo.UserBodyConstraints(); len(stored) != 0 {
		t.Errorf("stored = %+v, want nothing", stored)
	}
}

func TestRemoveConstraintResolvesAnInjury(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewUserBodyConstraintService(repo)
	userID := uuid.NewV7()
	injury, _ := mustDeclare(t, s, userID, model.UserBodyConstraintConfig{Zone: "left_wrist", Type: model.BodyConstraintInjured})

	if err := s.RemoveConstraint(ctx, injury.ID, userID); err != nil {
		t.Fatalf("RemoveConstraint() error = %v", err)
	}

	if active, _ := s.ListActiveConstraints(ctx, userID); len(active) != 0 {
		t.Errorf("active = %+v, want none", active)
	}
	// The healed injury stays in the history.
	stored := repo.UserBodyConstraints()
	if len(stored) != 1 || stored[0].ID != injury.ID || stored[0].EndedAt == nil {
		t.Fatalf("stored = %+v, want the injury ended", stored)
	}
	// A new injury on the same zone is a new constraint.
	again, created := mustDeclare(t, s, userID, model.UserBodyConstraintConfig{Zone: "left_wrist", Type: model.BodyConstraintInjured})
	if !created || again.ID == injury.ID {
		t.Errorf("new injury = %+v, created %v, want a new constraint", again, created)
	}
	// An ended constraint cannot be removed again.
	if err := s.RemoveConstraint(ctx, injury.ID, userID); !errors.Is(err, model.ErrUserBodyConstraintNotFound) {
		t.Errorf("RemoveConstraint(ended) error = %v, want ErrUserBodyConstraintNotFound", err)
	}
}

func TestRemoveConstraintDeletesAMissingZone(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewUserBodyConstraintService(repo)
	userID := uuid.NewV7()
	missing, _ := mustDeclare(t, s, userID, model.UserBodyConstraintConfig{Zone: "left_hand", Type: model.BodyConstraintMissing})

	if err := s.RemoveConstraint(ctx, missing.ID, userID); err != nil {
		t.Fatalf("RemoveConstraint() error = %v", err)
	}

	if stored := repo.UserBodyConstraints(); len(stored) != 0 {
		t.Errorf("stored = %+v, want the missing zone deleted", stored)
	}
}

func TestBodyConstraintsAreScopedToTheirUser(t *testing.T) {
	ctx := context.Background()
	s := NewUserBodyConstraintService(memrepo.New())
	userID, otherID := uuid.NewV7(), uuid.NewV7()
	constraint, _ := mustDeclare(t, s, userID, model.UserBodyConstraintConfig{Zone: "neck", Type: model.BodyConstraintInjured})

	if active, _ := s.ListActiveConstraints(ctx, otherID); len(active) != 0 {
		t.Errorf("another user's list = %+v, want empty", active)
	}
	if err := s.RemoveConstraint(ctx, constraint.ID, otherID); !errors.Is(err, model.ErrUserBodyConstraintNotFound) {
		t.Errorf("RemoveConstraint(another user's) error = %v, want ErrUserBodyConstraintNotFound", err)
	}
	if err := s.RemoveConstraint(ctx, uuid.NewV7(), userID); !errors.Is(err, model.ErrUserBodyConstraintNotFound) {
		t.Errorf("RemoveConstraint(unknown) error = %v, want ErrUserBodyConstraintNotFound", err)
	}
	// The same zone for another user is a separate constraint.
	if _, created := mustDeclare(t, s, otherID, model.UserBodyConstraintConfig{Zone: "neck", Type: model.BodyConstraintInjured}); !created {
		t.Error("another user's declaration on the same zone: created = false, want true")
	}
}
