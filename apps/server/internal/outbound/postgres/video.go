// @date 2026-09-17
// @file video.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/jackc/pgx/v5"
)

func (r *PostgresRepository) CreateVideo(ctx context.Context, video model.Video) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"INSERT INTO videos (id, user_id, object_key, status, expires_at) VALUES ($1, $2, $3, $4, $5)",
		video.ID, video.UserID, video.ObjectKey, video.Status, video.ExpiresAt)
	if err != nil {
		return err
	}

	return nil
}

func (r *PostgresRepository) GetVideoByFilter(ctx context.Context, filter model.VideoFilter) (model.Video, error) {
	setParts := []string{}
	args := []any{}

	if filter.ID != nil {
		args = append(args, *filter.ID)
		setParts = append(setParts, fmt.Sprintf("id = $%d", len(args)))
	}
	if filter.UserID != nil {
		args = append(args, *filter.UserID)
		setParts = append(setParts, fmt.Sprintf("user_id = $%d", len(args)))
	}
	if filter.ObjectKey != nil {
		args = append(args, *filter.ObjectKey)
		setParts = append(setParts, fmt.Sprintf("object_key = $%d", len(args)))
	}
	if filter.Status != nil {
		args = append(args, *filter.Status)
		setParts = append(setParts, fmt.Sprintf("status = $%d", len(args)))
	}

	query := "SELECT * FROM videos"

	if len(setParts) > 0 {
		query += " WHERE " + strings.Join(setParts, " AND ")
	}

	query += " LIMIT 1"

	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.Video{}, dto.Error(err)
	}

	dbVideo, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Video])
	if err != nil {
		return model.Video{}, dto.Error(err)
	}

	return dbVideo.ToVideo(), nil
}

func (r *PostgresRepository) ListVideosByFilter(ctx context.Context, filter model.VideoFilter) ([]model.Video, error) {
	setParts := []string{}
	args := []any{}

	if filter.ID != nil {
		args = append(args, *filter.ID)
		setParts = append(setParts, fmt.Sprintf("id = $%d", len(args)))
	}
	if filter.UserID != nil {
		args = append(args, *filter.UserID)
		setParts = append(setParts, fmt.Sprintf("user_id = $%d", len(args)))
	}
	if filter.ObjectKey != nil {
		args = append(args, *filter.ObjectKey)
		setParts = append(setParts, fmt.Sprintf("object_key = $%d", len(args)))
	}
	if filter.Status != nil {
		args = append(args, *filter.Status)
		setParts = append(setParts, fmt.Sprintf("status = $%d", len(args)))
	}

	query := "SELECT * FROM videos"

	if len(setParts) > 0 {
		query += " WHERE " + strings.Join(setParts, " AND ")
	}

	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return nil, dto.Error(err)
	}

	dbVideos, err := pgx.CollectRows(rows, pgx.RowToStructByName[dto.Video])
	if err != nil {
		return nil, dto.Error(err)
	}

	return dto.VideosToVideos(dbVideos), nil
}

func (r *PostgresRepository) UpdateVideo(ctx context.Context, partial model.VideoPartial) (model.Video, error) {
	setParts := []string{}
	args := []any{}

	if partial.ObjectKey != nil {
		args = append(args, *partial.ObjectKey)
		setParts = append(setParts, fmt.Sprintf("object_key = $%d", len(args)))
	}
	if partial.Status != nil {
		args = append(args, *partial.Status)
		setParts = append(setParts, fmt.Sprintf("status = $%d", len(args)))
	}
	if partial.ExpiresAt != nil {
		args = append(args, *partial.ExpiresAt)
		setParts = append(setParts, fmt.Sprintf("expires_at = $%d", len(args)))
	}

	if len(setParts) == 0 {
		return model.Video{}, model.ErrNotFound
	}

	args = append(args, partial.ID)

	query := fmt.Sprintf(
		"UPDATE videos SET %s WHERE id = $%d RETURNING *",
		strings.Join(setParts, ", "),
		len(args),
	)

	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.Video{}, dto.Error(err)
	}

	video, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Video])
	if err != nil {
		return model.Video{}, dto.Error(err)
	}

	return video.ToVideo(), nil
}

func (r *PostgresRepository) DeleteVideosExpired(ctx context.Context) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"DELETE FROM videos WHERE expires_at < $1 AND status != $2",
		time.Now(), model.VideoStatusCompleted)
	if err != nil {
		return dto.Error(err)
	}

	return nil
}
