// @date 2026-09-17
// @file session.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/jackc/pgx/v5"
	"uuid"
)

func (r *PostgresRepository) CreateSession(ctx context.Context, session model.Session) (model.Session, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"INSERT INTO sessions (user_id, token, expires_at) VALUES ($1, $2, $3) RETURNING *",
		session.UserID, session.Token, session.ExpiresAt)
	if err != nil {
		return model.Session{}, err
	}

	dbSession, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Session])
	if err != nil {
		return model.Session{}, err
	}

	return dbSession.ToSession(), nil
}

func (r *PostgresRepository) GetUserByValidToken(ctx context.Context, token string) (model.User, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, `
			SELECT u.*
			FROM sessions s
			JOIN users u ON u.id = s.user_id
			WHERE s.token = $1 AND s.expires_at > NOW()
			LIMIT 1
		`, token)
	if err != nil {
		return model.User{}, err
	}

	dbUser, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.User])
	if err != nil {
		return model.User{}, err
	}

	return dbUser.ToUser(), nil
}

func (r *PostgresRepository) DeleteSessionByTokenAndUserID(ctx context.Context, token string, userID uuid.UUID) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"DELETE FROM sessions WHERE user_id = $1 AND token = $2",
		userID,
		token)
	if err != nil {
		return err
	}
	return nil
}

func (r *PostgresRepository) DeleteSessionsExpired(ctx context.Context) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"DELETE FROM sessions WHERE expires_at < $1",
		time.Now())
	if err != nil {
		return err
	}
	return nil
}
