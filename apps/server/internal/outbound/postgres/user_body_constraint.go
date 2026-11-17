// @date 2026-11-13
// @file user_body_constraint.go
// @brief PostgreSQL adapter of the users' body constraints.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/jackc/pgx/v5"
	"uuid"
)

// UpsertActiveUserBodyConstraint creates the active constraint of the user on its zone, or
// replaces the one already active, in a single statement: the partial unique index
// uq_user_body_constraints_active guarantees one active constraint per zone and user.
func (r *PostgresRepository) UpsertActiveUserBodyConstraint(ctx context.Context, constraint model.UserBodyConstraint) (model.UserBodyConstraint, bool, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		`INSERT INTO user_body_constraints (user_id, zone, type, note, started_at)
		VALUES ($1, $2, $3, $4, COALESCE($5::date, CURRENT_DATE))
		ON CONFLICT (user_id, zone) WHERE ended_at IS NULL
		DO UPDATE SET type = EXCLUDED.type, note = EXCLUDED.note,
			started_at = COALESCE($5::date, user_body_constraints.started_at)
		RETURNING *, (xmax = 0) AS created`,
		constraint.UserID,
		constraint.Zone,
		constraint.Type,
		constraint.Note,
		optionalDate(constraint.StartedAt),
	)
	if err != nil {
		return model.UserBodyConstraint{}, false, dto.Error(err)
	}

	row, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.UpsertedUserBodyConstraint])
	if err != nil {
		return model.UserBodyConstraint{}, false, dto.Error(err)
	}

	return row.ToUserBodyConstraint(), row.Created, nil
}

// ListActiveUserBodyConstraints returns the user's constraints that have not ended, in the
// order of the body_zone enum (head to feet).
func (r *PostgresRepository) ListActiveUserBodyConstraints(ctx context.Context, userID uuid.UUID) ([]model.UserBodyConstraint, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"SELECT * FROM user_body_constraints WHERE user_id = $1 AND ended_at IS NULL ORDER BY zone, id",
		userID)
	if err != nil {
		return nil, dto.Error(err)
	}

	dbConstraints, err := pgx.CollectRows(rows, pgx.RowToStructByName[dto.UserBodyConstraint])
	if err != nil {
		return nil, dto.Error(err)
	}

	return dto.UserBodyConstraintsToUserBodyConstraints(dbConstraints), nil
}

// GetActiveUserBodyConstraint returns one of the user's active constraints. It returns
// model.ErrNotFound when the constraint does not exist, has ended or belongs to another user.
func (r *PostgresRepository) GetActiveUserBodyConstraint(ctx context.Context, id uuid.UUID, userID uuid.UUID) (model.UserBodyConstraint, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"SELECT * FROM user_body_constraints WHERE id = $1 AND user_id = $2 AND ended_at IS NULL",
		id, userID)
	if err != nil {
		return model.UserBodyConstraint{}, dto.Error(err)
	}

	dbConstraint, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.UserBodyConstraint])
	if err != nil {
		return model.UserBodyConstraint{}, dto.Error(err)
	}

	return dbConstraint.ToUserBodyConstraint(), nil
}

// EndUserBodyConstraint sets ended_at to today on one of the user's active constraints. It
// returns model.ErrNotFound when there is no such active constraint.
func (r *PostgresRepository) EndUserBodyConstraint(ctx context.Context, id uuid.UUID, userID uuid.UUID) (model.UserBodyConstraint, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"UPDATE user_body_constraints SET ended_at = CURRENT_DATE WHERE id = $1 AND user_id = $2 AND ended_at IS NULL RETURNING *",
		id, userID)
	if err != nil {
		return model.UserBodyConstraint{}, dto.Error(err)
	}

	dbConstraint, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.UserBodyConstraint])
	if err != nil {
		return model.UserBodyConstraint{}, dto.Error(err)
	}

	return dbConstraint.ToUserBodyConstraint(), nil
}

// DeleteUserBodyConstraint deletes one of the user's constraints. It returns
// model.ErrNotFound when the constraint does not exist or belongs to another user.
func (r *PostgresRepository) DeleteUserBodyConstraint(ctx context.Context, id uuid.UUID, userID uuid.UUID) error {
	tx := r.getTx(ctx)

	tag, err := tx.Exec(ctx, "DELETE FROM user_body_constraints WHERE id = $1 AND user_id = $2", id, userID)
	if err != nil {
		return dto.Error(err)
	}
	if tag.RowsAffected() == 0 {
		return model.ErrNotFound
	}

	return nil
}

// optionalDate turns a zero time into NULL, so that the query keeps the database default
// or the stored value.
func optionalDate(t time.Time) *time.Time {
	if t.IsZero() {
		return nil
	}

	return &t
}
