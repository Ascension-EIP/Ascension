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

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/jackc/pgx/v5"
	"uuid"
)

func (r *PostgresRepository) CreateUser(ctx context.Context, user model.User) (model.User, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"INSERT INTO users (name, email, password, role) VALUES ($1, $2, $3, $4) RETURNING *",
		user.Name, user.Email, user.Password, user.Role)
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
	if filter.Name != nil {
		args = append(args, *filter.Name)
		setParts = append(setParts, fmt.Sprintf("name = $%d", len(args)))
	}
	if filter.Password != nil {
		args = append(args, *filter.Password)
		setParts = append(setParts, fmt.Sprintf("password = $%d", len(args)))
	}
	if filter.Email != nil {
		args = append(args, *filter.Email)
		setParts = append(setParts, fmt.Sprintf("email = $%d", len(args)))
	}
	if filter.Role != nil {
		args = append(args, *filter.Role)
		setParts = append(setParts, fmt.Sprintf("role = $%d", len(args)))
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
	if filter.Name != nil {
		args = append(args, *filter.Name)
		setParts = append(setParts, fmt.Sprintf("name = $%d", len(args)))
	}
	if filter.Password != nil {
		args = append(args, *filter.Password)
		setParts = append(setParts, fmt.Sprintf("password = $%d", len(args)))
	}
	if filter.Email != nil {
		args = append(args, *filter.Email)
		setParts = append(setParts, fmt.Sprintf("email = $%d", len(args)))
	}
	if filter.Role != nil {
		args = append(args, *filter.Role)
		setParts = append(setParts, fmt.Sprintf("role = $%d", len(args)))
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
	setParts := []string{}
	args := []any{}
	argID := 1

	if partial.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name = $%d", argID))
		args = append(args, *partial.Name)
		argID++
	}

	if partial.Email != nil {
		setParts = append(setParts, fmt.Sprintf("email = $%d", argID))
		args = append(args, *partial.Email)
		argID++
	}

	if partial.Password != nil {
		setParts = append(setParts, fmt.Sprintf("password = $%d", argID))
		args = append(args, *partial.Password)
		argID++
	}

	if partial.Role != nil {
		setParts = append(setParts, fmt.Sprintf("role = $%d", argID))
		args = append(args, *partial.Role)
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

	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.User{}, dto.Error(err)
	}

	user, err := pgx.CollectExactlyOneRow(
		rows,
		pgx.RowToStructByName[dto.User],
	)
	if err != nil {
		return model.User{}, dto.Error(err)
	}

	return user.ToUser(), nil
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
