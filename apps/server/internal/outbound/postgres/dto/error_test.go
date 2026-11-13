// @date 2026-11-13
// @file error_test.go
// @brief Unit tests of the mapping of PostgreSQL errors to domain errors.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"errors"
	"fmt"
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

func TestError(t *testing.T) {
	other := errors.New("connection reset")

	tests := []struct {
		name string
		err  error
		want error
	}{
		{name: "nil", err: nil, want: nil},
		{name: "no rows", err: pgx.ErrNoRows, want: model.ErrNotFound},
		{name: "wrapped no rows", err: fmt.Errorf("collect: %w", pgx.ErrNoRows), want: model.ErrNotFound},
		{name: "unique violation", err: &pgconn.PgError{Code: "23505"}, want: model.ErrConflict},
		{name: "foreign key violation", err: &pgconn.PgError{Code: "23503"}, want: model.ErrInvalidInput},
		{name: "not null violation", err: &pgconn.PgError{Code: "23502"}, want: model.ErrInvalidInput},
		{name: "check violation", err: &pgconn.PgError{Code: "23514"}, want: model.ErrInvalidInput},
		{name: "wrapped unique violation", err: fmt.Errorf("insert: %w", &pgconn.PgError{Code: "23505"}), want: model.ErrConflict},
		{name: "other postgres error", err: &pgconn.PgError{Code: "42601"}, want: model.ErrInternalDB},
		{name: "other error", err: other, want: other},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := Error(tt.err)
			if tt.want == nil {
				if got != nil {
					t.Fatalf("Error(nil) = %v, want nil", got)
				}
				return
			}
			if !errors.Is(got, tt.want) {
				t.Errorf("Error(%v) = %v, want %v", tt.err, got, tt.want)
			}
		})
	}
}
