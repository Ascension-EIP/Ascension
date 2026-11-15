// @date 2026-11-15
// @file advice.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"fmt"
	"strings"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/jackc/pgx/v5"
)

func (r *PostgresRepository) CreateAdvice(ctx context.Context, videoID uuid.UUID) (model.Advice, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"INSERT INTO advices (id) VALUES ($1) RETURNING *",
		videoID)
	if err != nil {
		return model.Advice{}, dto.Error(err)
	}

	dbAdvice, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Advice])
	if err != nil {
		return model.Advice{}, dto.Error(err)
	}

	return dbAdvice.ToAdvice(), nil
}

func adviceFilterQuery(filter model.AdviceFilter) (string, []any) {
	setParts := []string{}
	args := []any{}

	setArg(&setParts, &args, "id", filter.ID)
	setArg(&setParts, &args, "status", filter.Status)

	query := "SELECT * FROM advices"
	if len(setParts) > 0 {
		query += " WHERE " + strings.Join(setParts, " AND ")
	}
	query += " ORDER BY created_at"

	return query, args
}

func (r *PostgresRepository) GetAdviceByFilter(ctx context.Context, filter model.AdviceFilter) (model.Advice, error) {
	query, args := adviceFilterQuery(filter)
	query += " LIMIT 1"

	tx := r.getTx(ctx)
	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.Advice{}, dto.Error(err)
	}

	dbAdvice, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Advice])
	if err != nil {
		return model.Advice{}, dto.Error(err)
	}

	return dbAdvice.ToAdvice(), nil
}

func (r *PostgresRepository) ListAdviceByFilter(ctx context.Context, filter model.AdviceFilter, pagination model.Pagination) ([]model.Advice, error) {
	query, args := adviceFilterQuery(filter)
	if pagination.Limit != 0 {
		query += fmt.Sprintf(" LIMIT %d", pagination.Limit)
	}
	if pagination.Offset != 0 {
		query += fmt.Sprintf(" OFFSET %d", pagination.Offset)
	}

	tx := r.getTx(ctx)
	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return []model.Advice{}, dto.Error(err)
	}

	dbAdvices, err := pgx.CollectRows(rows, pgx.RowToStructByName[dto.Advice])
	if err != nil {
		return []model.Advice{}, dto.Error(err)
	}

	return dto.AdvicesToAdvices(dbAdvices), nil
}

func (r *PostgresRepository) UpdateAdvice(ctx context.Context, partial model.AdvicePartial) (model.Advice, error) {
	tx := r.getTx(ctx)

	setParts := []string{}
	args := []any{}

	setArg(&setParts, &args, "status", partial.Status)
	setArg(&setParts, &args, "progress", partial.Progress)
	setArg(&setParts, &args, "result", partial.Result)
	setArg(&setParts, &args, "error", partial.Error)
	setArg(&setParts, &args, "processing_time_ms", partial.ProcessingTimeMS)
	setArg(&setParts, &args, "started_at", partial.StartedAt)
	setArg(&setParts, &args, "completed_at", partial.CompletedAt)
	setArg(&setParts, &args, "created_at", partial.CreatedAt)
	setArg(&setParts, &args, "updated_at", partial.UpdatedAt)

	if len(setParts) == 0 {
		return model.Advice{}, model.ErrNotFound
	}

	args = append(args, partial.ID)

	query := fmt.Sprintf(
		"UPDATE advices SET %s WHERE id = $%d RETURNING *",
		strings.Join(setParts, ", "),
		len(args),
	)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.Advice{}, dto.Error(err)
	}

	dbAdvice, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Advice])
	if err != nil {
		return model.Advice{}, dto.Error(err)
	}

	return dbAdvice.ToAdvice(), nil
}

func (r *PostgresRepository) DeleteAdvice(ctx context.Context, id uuid.UUID) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"DELETE FROM advices WHERE id = $1",
		id)
	if err != nil {
		return dto.Error(err)
	}

	return nil
}
