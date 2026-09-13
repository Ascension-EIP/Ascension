// @date 2026-03-18
// @file video.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

type Video struct {
	ID        uuid.UUID         `db:"id"`
	UserID    uuid.UUID         `db:"user_id"`
	ObjectKey string            `db:"object_key"`
	Status    model.VideoStatus `db:"status"`
	ExpiresAt time.Time         `db:"expires_at"`
	CreatedAt time.Time         `db:"created_at"`
	UpdatedAt time.Time         `db:"updated_at"`
}

func (v Video) ToVideo() model.Video {
	return model.Video{
		ID:        v.ID,
		UserID:    v.UserID,
		ObjectKey: v.ObjectKey,
		Status:    v.Status,
		ExpiresAt: v.ExpiresAt,
		CreatedAt: v.CreatedAt,
		UpdatedAt: v.UpdatedAt,
	}
}

func VideosToVideos(dto []Video) []model.Video {
	videos := []model.Video{}
	for _, video := range dto {
		videos = append(videos, video.ToVideo())
	}

	return videos
}
