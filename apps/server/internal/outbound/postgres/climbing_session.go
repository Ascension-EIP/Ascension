// @date 2026-11-12
// @file climbing_session.go
// @brief Climbing session repository: create, read, list, update and delete climbing_sessions rows.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"fmt"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/jackc/pgx/v5"
	"uuid"
)

// CreateClimbingSession inserts a climbing session and returns the stored row.
func (r *PostgresRepository) CreateClimbingSession(ctx context.Context, climbingSession model.ClimbingSession) (model.ClimbingSession, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"INSERT INTO climbing_sessions (user_id, gym_id, title, started_at, notes, visibility) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *",
		climbingSession.UserID,
		climbingSession.GymID,
		climbingSession.Title,
		climbingSession.StartedAt,
		climbingSession.Notes,
		climbingSession.Visibility,
	)
	if err != nil {
		return model.ClimbingSession{}, dto.Error(err)
	}

	dbSession, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.ClimbingSession])
	if err != nil {
		return model.ClimbingSession{}, dto.Error(err)
	}

	return dbSession.ToClimbingSession(), nil
}

// GetClimbingSessionByFilter returns the first climbing session matching the filter.
func (r *PostgresRepository) GetClimbingSessionByFilter(ctx context.Context, filter model.ClimbingSessionFilter) (model.ClimbingSession, error) {
	setParts := []string{}
	args := []any{}

	setArg(&setParts, &args, "id", filter.ID)
	setArg(&setParts, &args, "user_id", filter.UserID)

	query := "SELECT * FROM climbing_sessions"
	if len(setParts) > 0 {
		query += " WHERE " + strings.Join(setParts, " AND ")
	}
	query += " LIMIT 1"

	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.ClimbingSession{}, dto.Error(err)
	}

	dbSession, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.ClimbingSession])
	if err != nil {
		return model.ClimbingSession{}, dto.Error(err)
	}

	return dbSession.ToClimbingSession(), nil
}

// GetActiveClimbingSessionByUserID returns the user's most recently started session that has
// not ended, or model.ErrNotFound when every session has ended.
func (r *PostgresRepository) GetActiveClimbingSessionByUserID(ctx context.Context, userID uuid.UUID) (model.ClimbingSession, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"SELECT * FROM climbing_sessions WHERE user_id = $1 AND ended_at IS NULL ORDER BY started_at DESC, id DESC LIMIT 1",
		userID)
	if err != nil {
		return model.ClimbingSession{}, dto.Error(err)
	}

	dbSession, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.ClimbingSession])
	if err != nil {
		return model.ClimbingSession{}, dto.Error(err)
	}

	return dbSession.ToClimbingSession(), nil
}

// ListClimbingSessionsByUserID returns one page of the user's climbing sessions, most recent first,
// and the total number of sessions the user has.
func (r *PostgresRepository) ListClimbingSessionsByUserID(ctx context.Context, userID uuid.UUID, pagination model.Pagination) ([]model.ClimbingSession, int, error) {
	tx := r.getTx(ctx)

	var total int
	if err := tx.QueryRow(ctx,
		"SELECT COUNT(*) FROM climbing_sessions WHERE user_id = $1",
		userID,
	).Scan(&total); err != nil {
		return nil, 0, dto.Error(err)
	}

	rows, err := tx.Query(ctx,
		"SELECT * FROM climbing_sessions WHERE user_id = $1 ORDER BY started_at DESC, id DESC LIMIT $2 OFFSET $3",
		userID, pagination.Limit, pagination.Offset,
	)
	if err != nil {
		return nil, 0, dto.Error(err)
	}

	dbSessions, err := pgx.CollectRows(rows, pgx.RowToStructByName[dto.ClimbingSession])
	if err != nil {
		return nil, 0, dto.Error(err)
	}

	return dto.ClimbingSessionsToClimbingSessions(dbSessions), total, nil
}

// UpdateClimbingSession applies the partial to the session owned by partial.UserID.
// It returns model.ErrNotFound when the session does not exist or belongs to another user.
func (r *PostgresRepository) UpdateClimbingSession(ctx context.Context, partial model.ClimbingSessionPartial) (model.ClimbingSession, error) {
	setParts := []string{}
	args := []any{}

	setArg(&setParts, &args, "title", partial.Title)
	setArg(&setParts, &args, "notes", partial.Notes)
	setArg(&setParts, &args, "ended_at", partial.EndedAt)

	if len(setParts) == 0 {
		return model.ClimbingSession{}, fmt.Errorf("%w: nothing to update", model.ErrInvalidInput)
	}

	args = append(args, partial.ID, partial.UserID)

	query := fmt.Sprintf(
		"UPDATE climbing_sessions SET %s WHERE id = $%d AND user_id = $%d RETURNING *",
		strings.Join(setParts, ", "),
		len(args)-1,
		len(args),
	)

	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.ClimbingSession{}, dto.Error(err)
	}

	dbSession, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.ClimbingSession])
	if err != nil {
		return model.ClimbingSession{}, dto.Error(err)
	}

	return dbSession.ToClimbingSession(), nil
}

// DeleteClimbingSession deletes the session owned by userID. Its videos, and so their analyses,
// are kept and unlinked (ON DELETE SET NULL). It returns model.ErrNotFound when nothing was deleted.
func (r *PostgresRepository) DeleteClimbingSession(ctx context.Context, id uuid.UUID, userID uuid.UUID) error {
	tx := r.getTx(ctx)

	tag, err := tx.Exec(ctx,
		"DELETE FROM climbing_sessions WHERE id = $1 AND user_id = $2",
		id, userID)
	if err != nil {
		return dto.Error(err)
	}

	if tag.RowsAffected() == 0 {
		return model.ErrNotFound
	}

	return nil
}
