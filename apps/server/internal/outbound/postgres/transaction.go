package postgres

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type DBTX interface {
	Begin(context.Context) (pgx.Tx, error)
	Exec(context.Context, string, ...any) (pgconn.CommandTag, error)
	Query(context.Context, string, ...any) (pgx.Rows, error)
	QueryRow(context.Context, string, ...any) pgx.Row
}

type contextKey string

const txKey contextKey = "tx"

func (r *PostgresRepository) WithTransaction(ctx context.Context, fn func(ctx context.Context) error) error {
	tx := r.getTx(ctx)
	return pgx.BeginFunc(ctx, tx, func(nestedTx pgx.Tx) error {
		nestedCtx := context.WithValue(ctx, txKey, nestedTx)
		return fn(nestedCtx)
	})

}

func (r *PostgresRepository) getTx(ctx context.Context) DBTX {
	if tx, ok := ctx.Value(txKey).(DBTX); ok {
		return tx
	}
	return r.Pool
}
