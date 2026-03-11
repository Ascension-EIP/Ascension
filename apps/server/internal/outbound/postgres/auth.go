package postgres

import (
	"context"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (r *PostgresRepo) CreateSession(ctx context.Context, newSession *model.NewSession) (*model.Session, error) {
	if newSession == nil {
		return nil, model.ErrUnknown
	}

	var session *dto.Session
	if err := pgx.BeginFunc(ctx, r.Pool, func(tx pgx.Tx) error {
		rows, err := tx.Query(ctx,
			"INSERT INTO sessions (user_id, expires_at) VALUES ($1, $2) RETURNING *",
			newSession.UserID, newSession.ExpiresAt)
		if err != nil {
			return err
		}

		session, err = pgx.CollectExactlyOneRow(rows, pgx.RowToAddrOfStructByName[dto.Session])
		if err != nil {
			return err
		}
		return nil
	}); err != nil {
		return nil, err
	}

	return session.ToSession(), nil
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

func (r *PostgresRepo) DeleteSessionByUserID(ctx context.Context, userID uuid.UUID, sessionID uuid.UUID) error {
	err := pgx.BeginFunc(ctx, r.Pool, func(tx pgx.Tx) error {
		_, err := tx.Exec(ctx,
			"DELETE FROM sessions WHERE user_id = $1 AND id = $2",
			userID,
			sessionID)
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

// func (r *Repo) DeleteExpiredSessions(ctx context.Context) error {
// 	if err := r.db.WithContext(ctx).Where("expires_at < ?", time.Now()).Delete(&model.Session{}).Error; err != nil {
// 		return err
// 	}
// 	return nil
// }
