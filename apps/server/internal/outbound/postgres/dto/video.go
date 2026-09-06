// @date 2026-09-06
// @file video.go
// @brief Database transfer object for videos.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type Video struct {
	ID        uuid.UUID `db:"id"`
	UserID    uuid.UUID `db:"user_id"`
	Bucket    string    `db:"bucket"`
	ObjectKey string    `db:"object_key"`
	Status    string    `db:"status"`
	Duration  *int64    `db:"duration"`
	Size      *int64    `db:"size"`
	ExpiresAt time.Time `db:"expires_at"`
	CreatedAt time.Time `db:"created_at"`
	UpdatedAt time.Time `db:"updated_at"`
}

func (v *Video) ToVideoInfo() *model.VideoInfo {
	return &model.VideoInfo{
		ID:        v.ID,
		UserID:    v.UserID,
		Bucket:    v.Bucket,
		ObjectKey: v.ObjectKey,
		Status:    model.VideoStatus(v.Status),
		Duration:  v.Duration,
		Size:      v.Size,
		ExpiresAt: v.ExpiresAt,
	}
}
