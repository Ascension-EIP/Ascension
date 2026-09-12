// @date 2026-03-20
// @file video.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/jackc/pgx/v5"
)

func (r *PostgresRepository) CreateVideo(ctx context.Context, video model.Video) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"INSERT INTO videos (user_id, bucket, object_key, status, expires_at) VALUES ($1, $2, $3, $4, $5)",
		video.UserID, video.Bucket, video.ObjectKey, video.Status, video.ExpiresAt)
	if err != nil {
		return err
	}

	return nil
}

func (r *PostgresRepository) GetVideoByFilter(ctx context.Context, filter model.VideoFilter) (model.Video, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.Video{}, err
	}

	dbVideo, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Video])
	if err != nil {
		return model.Video{}, err
	}

	return dbVideo.ToVideo(), nil
}

func (r *PostgresRepository) UpdateVideo(ctx context.Context, partial model.VideoPartial) (model.Video, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.Video{}, err
	}

	video, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Video])
	if err != nil {
		return model.Video{}, err
	}

	return video.ToVideo(), nil
}
