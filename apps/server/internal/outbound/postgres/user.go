package postgres

import (
	"context"
	"fmt"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (r *PostgresRepo) CreateUser(ctx context.Context, newUser *model.NewUser) (*model.User, error) {
	if newUser == nil {
		return nil, model.ErrUnknown
	}

	var user *dto.User
	if err := pgx.BeginFunc(ctx, r.Pool, func(tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			"INSERT INTO users (name, email, password, role) VALUES ($1, $2, $3, $4) RETURNING *",
			newUser.Name, newUser.Email, newUser.Password, newUser.Role)
		if err != nil {
			return err
		}

		user, err = pgx.CollectExactlyOneRow(rows, pgx.RowToAddrOfStructByName[dto.User])
		if err != nil {
			return err
		}
		return nil
	}); err != nil {
		return nil, err
	}

	return user.ToUser(), nil
}

func (r *PostgresRepo) GetUserByID(ctx context.Context, userID uuid.UUID) (*model.User, error) {
	var user *dto.User
	if err := pgx.BeginFunc(ctx, r.Pool, func(tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			"SELECT * FROM users WHERE id = $1",
			userID)
		if err != nil {
			return err
		}

		user, err = pgx.CollectExactlyOneRow(rows, pgx.RowToAddrOfStructByName[dto.User])
		if err != nil {
			return err
		}
		return nil
	}); err != nil {
		return nil, err
	}

	return user.ToUser(), nil
}

func (r *PostgresRepo) GetUserByEmail(ctx context.Context, email string) (*model.User, error) {
	var user *dto.User
	if err := pgx.BeginFunc(ctx, r.Pool, func(tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			"SELECT * FROM users WHERE email = $1",
			email)
		if err != nil {
			return err
		}

		user, err = pgx.CollectExactlyOneRow(rows, pgx.RowToAddrOfStructByName[dto.User])
		if err != nil {
			return err
		}
		return nil
	}); err != nil {
		return nil, err
	}

	return user.ToUser(), nil
}

func (r *PostgresRepo) ListAllUsers(ctx context.Context) ([]*model.User, error) {
	var users []*dto.User
	if err := pgx.BeginFunc(ctx, r.Pool, func(tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			"SELECT * FROM users")
		if err != nil {
			return err
		}

		users, err = pgx.CollectRows(rows, pgx.RowToAddrOfStructByName[dto.User])
		if err != nil {
			return err
		}
		return nil
	}); err != nil {
		return nil, err
	}
	return dto.UsersToUsers(users), nil
}

func (r *PostgresRepo) UpdateUser(ctx context.Context, partialUser *model.PartialUser) (*model.User, error) {
	if partialUser == nil {
		return nil, model.ErrUnknown
	}

	setParts := []string{}
	args := []interface{}{}
	argID := 1

	if partialUser.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name=$%d", argID))
		args = append(args, *partialUser.Name)
		argID++
	}
	if partialUser.Email != nil {
		setParts = append(setParts, fmt.Sprintf("email=$%d", argID))
		args = append(args, *partialUser.Email)
		argID++
	}
	if partialUser.Password != nil {
		setParts = append(setParts, fmt.Sprintf("password=$%d", argID))
		args = append(args, *partialUser.Password)
		argID++
	}
	if partialUser.Role != nil {
		setParts = append(setParts, fmt.Sprintf("role=$%d", argID))
		args = append(args, *partialUser.Role)
		argID++
	}
	args = append(args, partialUser.ID)
	query := fmt.Sprintf("UPDATE users SET %s WHERE id=$%d RETURNING *", strings.Join(setParts, ", "), argID)

	var user *dto.User
	if err := pgx.BeginFunc(ctx, r.Pool, func(tx pgx.Tx) error {
		rows, err := tx.Query(context.Background(), query, args...)
		if err != nil {
			return err
		}

		user, err = pgx.CollectExactlyOneRow(rows, pgx.RowToAddrOfStructByName[dto.User])
		if err != nil {
			return err
		}

		return nil
	}); err != nil {
		return nil, err
	}
	return user.ToUser(), nil
}

func (r *PostgresRepo) DeleteUser(ctx context.Context, userID uuid.UUID) error {
	err := pgx.BeginFunc(ctx, r.Pool, func(tx pgx.Tx) error {
		_, err := tx.Exec(ctx,
			"DELETE FROM users WHERE id = $1",
			userID)
		if err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return err
	}
	return nil
}
