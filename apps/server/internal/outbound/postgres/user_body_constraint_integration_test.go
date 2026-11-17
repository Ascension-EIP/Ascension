// @date 2026-11-13
// @file user_body_constraint_integration_test.go
// @brief PostgreSQL integration tests of the body constraint repository.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/pgtest"
)

func TestUserBodyConstraintRepository(t *testing.T) {
	ctx := context.Background()
	db := pgtest.Open(t)
	repo := db.Repo
	userID, otherID := db.CreateUser(t), db.CreateUser(t)
	startedAt := time.Date(2026, 10, 1, 0, 0, 0, 0, time.UTC)

	injury, created, err := repo.UpsertActiveUserBodyConstraint(ctx, model.UserBodyConstraint{
		UserID: userID, Zone: "left_knee", Type: model.BodyConstraintInjured, Note: new("Sprain"), StartedAt: startedAt,
	})
	if err != nil || !created || injury.EndedAt != nil || !injury.StartedAt.Equal(startedAt) || injury.CreatedAt.IsZero() {
		t.Fatalf("first upsert = %+v, created %v, error %v", injury, created, err)
	}

	// Same zone: the active row is updated, its start date kept when none is given.
	replaced, created, err := repo.UpsertActiveUserBodyConstraint(ctx, model.UserBodyConstraint{
		UserID: userID, Zone: "left_knee", Type: model.BodyConstraintMissing,
	})
	if err != nil || created || replaced.ID != injury.ID || replaced.Type != model.BodyConstraintMissing || replaced.Note != nil || !replaced.StartedAt.Equal(startedAt) {
		t.Fatalf("second upsert = %+v, created %v, error %v", replaced, created, err)
	}

	// A zero start date on creation means today.
	neck, _, err := repo.UpsertActiveUserBodyConstraint(ctx, model.UserBodyConstraint{UserID: userID, Zone: "neck", Type: model.BodyConstraintInjured})
	if err != nil || neck.StartedAt.IsZero() {
		t.Fatalf("upsert without start = %+v, %v", neck, err)
	}

	// Head to feet, as the body_zone enum.
	active, err := repo.ListActiveUserBodyConstraints(ctx, userID)
	if err != nil || len(active) != 2 || active[0].Zone != "neck" || active[1].Zone != "left_knee" {
		t.Fatalf("ListActiveUserBodyConstraints() = %+v, %v", active, err)
	}
	if other, err := repo.ListActiveUserBodyConstraints(ctx, otherID); err != nil || len(other) != 0 {
		t.Fatalf("another user's list = %+v, %v", other, err)
	}

	if _, err := repo.GetActiveUserBodyConstraint(ctx, neck.ID, otherID); !errors.Is(err, model.ErrNotFound) {
		t.Fatalf("another user's constraint: error = %v, want ErrNotFound", err)
	}

	// Ending keeps the row; the zone is then free for a new active constraint.
	ended, err := repo.EndUserBodyConstraint(ctx, neck.ID, userID)
	if err != nil || ended.EndedAt == nil {
		t.Fatalf("EndUserBodyConstraint() = %+v, %v", ended, err)
	}
	if _, err := repo.EndUserBodyConstraint(ctx, neck.ID, userID); !errors.Is(err, model.ErrNotFound) {
		t.Fatalf("ending twice: error = %v, want ErrNotFound", err)
	}
	if _, err := repo.GetActiveUserBodyConstraint(ctx, neck.ID, userID); !errors.Is(err, model.ErrNotFound) {
		t.Fatalf("ended constraint: error = %v, want ErrNotFound", err)
	}
	again, created, err := repo.UpsertActiveUserBodyConstraint(ctx, model.UserBodyConstraint{UserID: userID, Zone: "neck", Type: model.BodyConstraintInjured})
	if err != nil || !created || again.ID == neck.ID {
		t.Fatalf("new injury on an ended zone = %+v, created %v, error %v", again, created, err)
	}

	// ended_at cannot precede started_at (chk_user_body_constraints_dates).
	tomorrow := time.Now().UTC().AddDate(0, 0, 1)
	future, _, err := repo.UpsertActiveUserBodyConstraint(ctx, model.UserBodyConstraint{UserID: userID, Zone: "torso", Type: model.BodyConstraintInjured, StartedAt: tomorrow})
	if err != nil {
		t.Fatalf("upsert starting tomorrow: %v", err)
	}
	if _, err := repo.EndUserBodyConstraint(ctx, future.ID, userID); !errors.Is(err, model.ErrInvalidInput) {
		t.Fatalf("ending before the start: error = %v, want ErrInvalidInput", err)
	}

	if err := repo.DeleteUserBodyConstraint(ctx, replaced.ID, otherID); !errors.Is(err, model.ErrNotFound) {
		t.Fatalf("deleting another user's constraint: error = %v, want ErrNotFound", err)
	}
	if err := repo.DeleteUserBodyConstraint(ctx, replaced.ID, userID); err != nil {
		t.Fatalf("DeleteUserBodyConstraint() error = %v", err)
	}
	if err := repo.DeleteUserBodyConstraint(ctx, replaced.ID, userID); !errors.Is(err, model.ErrNotFound) {
		t.Fatalf("deleting twice: error = %v, want ErrNotFound", err)
	}
}
