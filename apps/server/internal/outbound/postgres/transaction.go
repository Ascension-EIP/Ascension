// @date 2026-03-14
// @file transaction.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type DBTX interface {
	Exec(context.Context, string, ...any) (pgconn.CommandTag, error)
	Query(context.Context, string, ...any) (pgx.Rows, error)
	QueryRow(context.Context, string, ...any) pgx.Row
}

type contextKey string

const txKey contextKey = "tx"

func (r *PostgresRepository) WithTransaction(ctx context.Context, fn func(ctx context.Context) error) error {
	if _, ok := ctx.Value(txKey).(DBTX); ok {
		return fn(ctx)
	}

	tx, err := r.Pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	newCtx := context.WithValue(ctx, txKey, tx)

	if err := fn(newCtx); err != nil {
		return fmt.Errorf("during transaction: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit transaction: %w", err)
	}

	return nil
}

func (r *PostgresRepository) getTx(ctx context.Context) DBTX {
	if tx, ok := ctx.Value(txKey).(DBTX); ok {
		return tx
	}
	return r.Pool
}
