// @date 2026-09-18
// @file auth.go
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
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (r *PostgresRepository) CreateSession(ctx context.Context, newSession *model.NewSession) (*model.Session, error) {
	if newSession == nil {
		return nil, model.ErrUnknown
	}
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"INSERT INTO sessions (user_id, token_hash, expires_at) VALUES ($1, $2, $3) RETURNING *",
		newSession.UserID, newSession.TokenHash, newSession.ExpiresAt)
	if err != nil {
		return nil, err
	}

	session, err := pgx.CollectExactlyOneRow(rows, pgx.RowToAddrOfStructByName[dto.Session])
	if err != nil {
		return nil, err
	}

	return session.ToSession(), nil
}

func (r *PostgresRepository) GetUserByValidSessionTokenHash(ctx context.Context, tokenHash string) (*model.User, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, `
			WITH used AS (
				UPDATE sessions
				   SET last_used_at = NOW()
				 WHERE token_hash = $1
				   AND revoked_at IS NULL
				   AND expires_at > NOW()
				RETURNING user_id
			)
			SELECT u.*
			FROM used s
			JOIN users u ON u.id = s.user_id
			LIMIT 1
		`, tokenHash)
	if err != nil {
		return nil, err
	}

	user, err := pgx.CollectExactlyOneRow(rows, pgx.RowToAddrOfStructByName[dto.User])
	if err != nil {
		return nil, err
	}

	return user.ToUser(), nil
}

// func (r *Repo) GetSession(ctx context.Context, id string) (*entity.Session, error) {
// 	var session model.Session
// 	if err := r.db.WithContext(ctx).
// 		Where("id = ?", id).
// 		First(&session).
// 		Error; err != nil {
// 		switch {
// 		case errors.Is(err, gorm.ErrRecordNotFound):
// 			return nil, ErrNotFound
// 		default:
// 			return nil, err
// 		}
// 	}
// 	return model.SessionToEntity(&session), nil
// }
//
// func (r *Repo) GetUnexpiredSession(ctx context.Context, id string) (*entity.Session, error) {
// 	var session model.Session
// 	if err := r.db.WithContext(ctx).
// 		Where("id = ? AND expires_at > ?", id, time.Now()).
// 		First(&session).
// 		Error; err != nil {
// 		switch {
// 		case errors.Is(err, gorm.ErrRecordNotFound):
// 			return nil, ErrNotFound
// 		default:
// 			return nil, err
// 		}
// 	}
// 	return model.SessionToEntity(&session), nil
// }
//
// func (r *Repo) UpdateSession(ctx context.Context, session *entity.Session) error {
// 	if session == nil {
// 		return ErrModelNil
// 	}
// 	m := model.SessionFromEntity(session)
// 	if err := r.db.WithContext(ctx).
// 		Where("id = ?", session.ID).
// 		Updates(m).
// 		Error; err != nil {
// 		switch {
// 		case errors.Is(err, gorm.ErrRecordNotFound):
// 			return ErrNotFound
// 		case errors.Is(err, gorm.ErrForeignKeyViolated):
// 			return ErrDuplicatedKey
// 		default:
// 			return err
// 		}
// 	}
// 	return nil
// }
//
// func (r *Repo) DeleteSession(ctx context.Context, id string) error {
// 	if err := r.db.WithContext(ctx).
// 		Where("id = ?", id).
// 		Delete(&model.Session{}).
// 		Error; err != nil {
// 		switch {
// 		case errors.Is(err, gorm.ErrRecordNotFound):
// 			return ErrNotFound
// 		default:
// 			return err
// 		}
// 	}
// 	return nil
// }

func (r *PostgresRepository) DeleteSessionByUserID(ctx context.Context, userID uuid.UUID, tokenHash string) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"DELETE FROM sessions WHERE user_id = $1 AND token_hash = $2",
		userID,
		tokenHash)
	if err != nil {
		return err
	}
	return nil
}

func (r *PostgresRepository) DeleteExpiredSessions(ctx context.Context) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"DELETE FROM sessions WHERE expires_at < ?",
		time.Now())
	if err != nil {
		return err
	}
	return nil
}
