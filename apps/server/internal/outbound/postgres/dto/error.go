// @date 2026-09-11
// @file error.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"errors"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

func Error(err error) error {
	if err == nil {
		return nil
	}

	if errors.Is(err, pgx.ErrNoRows) {
		return model.ErrNotFound
	}

	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		switch pgErr.Code {
		case "23505": // unique_violation
			return model.ErrConflict

		case "23503": // foreign_key_violation
			return model.ErrInvalidInput

		case "23502": // not_null_violation
			return model.ErrInvalidInput

		default:
			return model.ErrInternalDB
		}
	}

	return err
}
