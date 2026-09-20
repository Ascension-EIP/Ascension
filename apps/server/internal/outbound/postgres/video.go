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
		"INSERT INTO videos (id, user_id, object_key, climbing_session_id, title, visibility, width, height, fps, content_type, duration_ms, size_bytes, retained, status, upload_url_expires_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)",
		video.ID, video.UserID, video.ObjectKey, video.ClimbingSessionID, video.Title, video.Visibility, video.Width, video.Height, video.FPS, video.ContentType, video.DurationMs, video.SizeBytes, video.Retained, video.Status, video.UploadURLExpiresAt)
	if err != nil {
		return err
	}

	return nil
}

func videoFilterQuery(filter model.VideoFilter) (string, []any) {
	setParts := []string{}
	args := []any{}

	setArg(&setParts, &args, "id", filter.ID)
	setArg(&setParts, &args, "user_id", filter.UserID)
	setArg(&setParts, &args, "object_key", filter.ObjectKey)
	setArg(&setParts, &args, "status", filter.Status)
	setArg(&setParts, &args, "visibility", filter.Visibility)
	setArg(&setParts, &args, "content_type", filter.ContentType)
	setArg(&setParts, &args, "retained", filter.Retained)

	query := "SELECT * FROM videos"
	if len(setParts) > 0 {
		query += " WHERE " + strings.Join(setParts, " AND ")
	}

	return query, args
}

func (r *PostgresRepository) GetVideoByFilter(ctx context.Context, filter model.VideoFilter) (model.Video, error) {
	query, args := videoFilterQuery(filter)
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
	query, args := videoFilterQuery(filter)

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
	tx := r.getTx(ctx)

	setParts := []string{}
	args := []any{}

	setArg(&setParts, &args, "object_key", partial.ObjectKey)
	setArg(&setParts, &args, "status", partial.Status)
	setArg(&setParts, &args, "visibility", partial.Visibility)
	setArg(&setParts, &args, "content_type", partial.ContentType)
	setArg(&setParts, &args, "retained", partial.Retained)
	setArg(&setParts, &args, "upload_url_expires_at", partial.UploadURLExpiresAt)
	setArg(&setParts, &args, "climbing_session_id", partial.ClimbingSessionID)
	setArg(&setParts, &args, "title", partial.Title)
	setArg(&setParts, &args, "width", partial.Width)
	setArg(&setParts, &args, "height", partial.Height)
	setArg(&setParts, &args, "fps", partial.FPS)
	setArg(&setParts, &args, "duration_ms", partial.DurationMs)
	setArg(&setParts, &args, "size_bytes", partial.SizeBytes)

	if len(setParts) == 0 {
		return model.Video{}, model.ErrNotFound
	}

	args = append(args, partial.ID)

	query := fmt.Sprintf(
		"UPDATE videos SET %s WHERE id = $%d RETURNING *",
		strings.Join(setParts, ", "),
		len(args),
	)

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

func (r *PostgresRepository) DeleteVideosUploadExpired(ctx context.Context) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"DELETE FROM videos WHERE upload_url_expires_at < $1 AND status != $2",
		time.Now(), model.VideoStatusCompleted)
	if err != nil {
		return dto.Error(err)
	}

	return nil
}
