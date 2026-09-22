// @date 2026-09-20
// @file user.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
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

func userFilterQuery(filter model.UserFilter) (string, []any) {
	setParts := []string{}
	args := []any{}

	setArg(&setParts, &args, "id", filter.ID)
	setArg(&setParts, &args, "username", filter.Username)
	setArg(&setParts, &args, "first_name", filter.FirstName)
	setArg(&setParts, &args, "last_name", filter.LastName)
	setArg(&setParts, &args, "email", filter.Email)
	setArg(&setParts, &args, "password_hash", filter.Password)
	setArg(&setParts, &args, "role", filter.Role)
	setArg(&setParts, &args, "status", filter.Status)

	query := "SELECT * FROM users"
	if len(setParts) > 0 {
		query += " WHERE " + strings.Join(setParts, " AND ")
	}

	return query, args
}

func (r *PostgresRepository) GetUserByFilter(ctx context.Context, filter model.UserFilter) (model.User, error) {
	query, args := userFilterQuery(filter)
	query += " LIMIT 1"

	tx := r.getTx(ctx)

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
	query, args := userFilterQuery(filter)

	tx := r.getTx(ctx)

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
	setParts := []string{}
	args := []any{}

	setArg(&setParts, &args, "username", partial.Username)
	setArg(&setParts, &args, "first_name", partial.FirstName)
	setArg(&setParts, &args, "last_name", partial.LastName)
	setArg(&setParts, &args, "email", partial.Email)
	setArg(&setParts, &args, "role", partial.Role)
	setArg(&setParts, &args, "status", partial.Status)

	// password_hash needs hashing first (UserPassword is []byte, no Valuer),
	// so it keeps one guard; every other field is nil-safe through setArg.
	if partial.Password != nil {
		passwordHash, err := partial.Password.Hash()
		if err != nil {
			return model.User{}, dto.Error(err)
		}
		v := any(passwordHash)
		setArg(&setParts, &args, "password_hash", &v)
	}

	if len(setParts) == 0 {
		return model.User{}, model.ErrUserNotFound
	}

	args = append(args, partial.ID)

	tx := r.getTx(ctx)

	query := fmt.Sprintf(
		"UPDATE users SET %s WHERE id = $%d RETURNING *",
		strings.Join(setParts, ", "),
		len(args),
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
