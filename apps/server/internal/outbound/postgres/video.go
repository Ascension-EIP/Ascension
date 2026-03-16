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

func (r *PostgresRepository) CreateVideoInfo(ctx context.Context, info *model.VideoInfo) error {
	if info == nil {
		return model.ErrUnknown
	}

	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"INSERT INTO videos (id, user_id, object_key, status, expires_at) VALUES ($1, $2, $3, $4, $5)",
		info.ID, info.UserID, info.ObjectKey, info.Status, info.ExpiresAt)
	if err != nil {
		return err
	}

	return nil
}

func (r *PostgresRepository) GetVideoInfoByUserID(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) (*model.VideoInfo, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, "SELECT * FROM videos WHERE id = $1 AND user_id = $2 LIMIT 1", videoID, userID)
	if err != nil {
		return nil, err
	}

	video, err := pgx.CollectExactlyOneRow(rows, pgx.RowToAddrOfStructByName[dto.Video])
	if err != nil {
		return nil, err
	}

	return video.ToVideoInfo(), nil
}

func (r *PostgresRepository) UpdateVideoInfo(ctx context.Context, partialInfo *model.PartialVideoInfo) (*model.VideoInfo, error) {
	if partialInfo == nil {
		return nil, model.ErrUnknown
	}

	setParts := []string{}
	args := []any{}
	argID := 1

	if partialInfo.ObjectKey != nil {
		setParts = append(setParts, fmt.Sprintf("object_key=$%d", argID))
		args = append(args, *partialInfo.ObjectKey)
		argID++
	}
	if partialInfo.Status != nil {
		setParts = append(setParts, fmt.Sprintf("status=$%d", argID))
		args = append(args, *partialInfo.Status)
		argID++
	}
	if partialInfo.ExpiresAt != nil {
		setParts = append(setParts, fmt.Sprintf("expires_at=$%d", argID))
		args = append(args, *partialInfo.ExpiresAt)
		argID++
	}
	args = append(args, partialInfo.ID)
	args = append(args, partialInfo.UserID)
	query := fmt.Sprintf("UPDATE videos SET %s WHERE id=$%d AND user_id=$%d RETURNING *", strings.Join(setParts, ", "), argID, argID+1)

	tx := r.getTx(ctx)

	rows, err := tx.Query(context.Background(), query, args...)
	if err != nil {
		return nil, err
	}

	video, err := pgx.CollectExactlyOneRow(rows, pgx.RowToAddrOfStructByName[dto.Video])
	if err != nil {
		return nil, err
	}

	return video.ToVideoInfo(), nil
}
