// @date 2026-03-16
// @file user.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
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

func (r *PostgresRepository) CreateUser(ctx context.Context, user model.User) (model.User, error) {
	tx := r.getTx(ctx)

	passwordHash, err := user.Password.Hash()
	if err != nil {
		return model.User{}, dto.Error(err)
	}

	rows, err := tx.Query(ctx,
		"INSERT INTO users (username, first_name, last_name, email, password_hash, role, status, email_verified_at, last_login_at, deactivated_at, stripe_customer_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *",
		user.Username,
		user.FirstName,
		user.LastName,
		user.Email,
		passwordHash,
		user.Role,
		user.Status,
		user.EmailVerifiedAt,
		user.LastLoginAt,
		user.DeactivatedAt,
		user.StripeCustomerID,
	)
	if err != nil {
		return model.User{}, dto.Error(err)
	}

	dbUser, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.User])
	if err != nil {
		return model.User{}, dto.Error(err)
	}

	return dbUser.ToUser(), nil
}

func (r *PostgresRepository) GetUserByFilter(ctx context.Context, filter model.UserFilter) (model.User, error) {
	tx := r.getTx(ctx)

	setParts := []string{}
	args := []any{}

	if filter.ID != nil {
		args = append(args, *filter.ID)
		setParts = append(setParts, fmt.Sprintf("id = $%d", len(args)))
	}
	if filter.Username != nil {
		args = append(args, *filter.Username)
		setParts = append(setParts, fmt.Sprintf("username = $%d", len(args)))
	}
	if filter.FirstName != nil {
		args = append(args, *filter.FirstName)
		setParts = append(setParts, fmt.Sprintf("first_name = $%d", len(args)))
	}
	if filter.LastName != nil {
		args = append(args, *filter.LastName)
		setParts = append(setParts, fmt.Sprintf("last_name = $%d", len(args)))
	}
	if filter.Email != nil {
		args = append(args, *filter.Email)
		setParts = append(setParts, fmt.Sprintf("email = $%d", len(args)))
	}
	if filter.Password != nil {
		args = append(args, *filter.Password)
		setParts = append(setParts, fmt.Sprintf("password_hash = $%d", len(args)))
	}
	if filter.Role != nil {
		args = append(args, *filter.Role)
		setParts = append(setParts, fmt.Sprintf("role = $%d", len(args)))
	}
	if filter.Status != nil {
		args = append(args, *filter.Status)
		setParts = append(setParts, fmt.Sprintf("status = $%d", len(args)))
	}

	query := "SELECT * FROM users"

	if len(setParts) > 0 {
		query += " WHERE " + strings.Join(setParts, " AND ")
	}

	query += " LIMIT 1"

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.User{}, dto.Error(err)
	}

	dbUser, err := pgx.CollectExactlyOneRow(
		rows,
		pgx.RowToStructByName[dto.User],
	)
	if err != nil {
		return model.User{}, dto.Error(err)
	}

	return dbUser.ToUser(), nil
}

func (r *PostgresRepository) ListUsersByFilter(ctx context.Context, filter model.UserFilter) ([]model.User, error) {
	tx := r.getTx(ctx)

	setParts := []string{}
	args := []any{}

	if filter.ID != nil {
		args = append(args, *filter.ID)
		setParts = append(setParts, fmt.Sprintf("id = $%d", len(args)))
	}
	if filter.Username != nil {
		args = append(args, *filter.Username)
		setParts = append(setParts, fmt.Sprintf("username = $%d", len(args)))
	}
	if filter.FirstName != nil {
		args = append(args, *filter.FirstName)
		setParts = append(setParts, fmt.Sprintf("first_name = $%d", len(args)))
	}
	if filter.LastName != nil {
		args = append(args, *filter.LastName)
		setParts = append(setParts, fmt.Sprintf("last_name = $%d", len(args)))
	}
	if filter.Email != nil {
		args = append(args, *filter.Email)
		setParts = append(setParts, fmt.Sprintf("email = $%d", len(args)))
	}
	if filter.Password != nil {
		args = append(args, *filter.Password)
		setParts = append(setParts, fmt.Sprintf("password_hash = $%d", len(args)))
	}
	if filter.Role != nil {
		args = append(args, *filter.Role)
		setParts = append(setParts, fmt.Sprintf("role = $%d", len(args)))
	}
	if filter.Status != nil {
		args = append(args, *filter.Status)
		setParts = append(setParts, fmt.Sprintf("status = $%d", len(args)))
	}

	query := "SELECT * FROM users"

	if len(setParts) > 0 {
		query += " WHERE " + strings.Join(setParts, " AND ")
	}

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return nil, dto.Error(err)
	}

	dbUsers, err := pgx.CollectRows(
		rows,
		pgx.RowToStructByName[dto.User],
	)
	if err != nil {
		return nil, dto.Error(err)
	}

	return dto.UsersToUsers(dbUsers), nil
}

func (r *PostgresRepository) UpdateUser(ctx context.Context, partial model.UserPartial) (model.User, error) {
	tx := r.getTx(ctx)

	setParts := []string{}
	args := []any{}
	argID := 1

	if partial.Username != nil {
		args = append(args, *partial.Username)
		setParts = append(setParts, fmt.Sprintf("username = $%d", argID))
		argID++
	}

	if partial.FirstName != nil {
		args = append(args, *partial.FirstName)
		setParts = append(setParts, fmt.Sprintf("first_name = $%d", argID))
		argID++
	}

	if partial.LastName != nil {
		args = append(args, *partial.LastName)
		setParts = append(setParts, fmt.Sprintf("last_name = $%d", argID))
		argID++
	}

	if partial.Email != nil {
		args = append(args, *partial.Email)
		setParts = append(setParts, fmt.Sprintf("email = $%d", argID))
		argID++
	}

	if partial.Password != nil {
		passwordHash, err := partial.Password.Hash()
		if err != nil {
			return model.User{}, dto.Error(err)
		}

		args = append(args, passwordHash)
		setParts = append(setParts, fmt.Sprintf("password_hash = $%d", argID))
		argID++
	}

	if partial.Role != nil {
		args = append(args, *partial.Role)
		setParts = append(setParts, fmt.Sprintf("role = $%d", argID))
		argID++
	}

	if partial.Status != nil {
		args = append(args, *partial.Status)
		setParts = append(setParts, fmt.Sprintf("status = $%d", argID))
		argID++
	}

	if len(setParts) == 0 {
		return model.User{}, model.ErrUserNotFound
	}

	args = append(args, partial.ID)

	query := fmt.Sprintf(
		"UPDATE users SET %s WHERE id = $%d RETURNING *",
		strings.Join(setParts, ", "),
		argID,
	)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.User{}, dto.Error(err)
	}

	dbUser, err := pgx.CollectExactlyOneRow(
		rows,
		pgx.RowToStructByName[dto.User],
	)
	if err != nil {
		return model.User{}, dto.Error(err)
	}

	return dbUser.ToUser(), nil
}

func (r *PostgresRepository) DeleteUser(ctx context.Context, userID uuid.UUID) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"DELETE FROM users WHERE id = $1",
		userID)
	if err != nil {
		return dto.Error(err)
	}

	return nil
}
