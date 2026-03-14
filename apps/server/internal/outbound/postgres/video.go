package postgres

import (
	"context"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

func (r *PostgresRepository) CreateVideoInfo(ctx context.Context, info *model.VideoInfo) error {
	if info == nil {
		return model.ErrUnknown
	}

	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"INSERT INTO videos (id, user_id, object_key, status, expires_at) VALUES ($1, $2, $3, $4, $5)",
		info.ID, info.UserID, info.ObjectKey, info.State, info.ExpiresAt)
	if err != nil {
		return err
	}

	return nil
}
