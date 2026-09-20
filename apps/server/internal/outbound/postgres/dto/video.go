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
	ID                 uuid.UUID         `db:"id"`
	UserID             uuid.UUID         `db:"user_id"`
	ClimbingSessionID  *uuid.UUID        `db:"climbing_session_id"`
	Title              *string           `db:"title"`
	ObjectKey          string            `db:"object_key"`
	Status             model.VideoStatus `db:"status"`
	Visibility         model.Visibility  `db:"visibility"`
	Width              *int16            `db:"width"`
	Height             *int16            `db:"height"`
	FPS                *float64          `db:"fps"`
	ContentType        string            `db:"content_type"`
	DurationMs         *time.Duration    `db:"duration_ms"`
	SizeBytes          *int              `db:"size_bytes"`
	Retained           bool              `db:"retained"`
	UploadURLExpiresAt *time.Time        `db:"upload_url_expires_at"`
	CreatedAt          time.Time         `db:"created_at"`
	UpdatedAt          time.Time         `db:"updated_at"`
}

func (v Video) ToVideo() model.Video {
	return model.Video{
		ID:                 v.ID,
		UserID:             v.UserID,
		ClimbingSessionID:  v.ClimbingSessionID,
		Title:              v.Title,
		ObjectKey:          v.ObjectKey,
		Status:             v.Status,
		Visibility:         v.Visibility,
		Width:              v.Width,
		Height:             v.Height,
		FPS:                v.FPS,
		ContentType:        v.ContentType,
		DurationMS:         v.DurationMs,
		SizeBytes:          v.SizeBytes,
		Retained:           v.Retained,
		UploadURLExpiresAt: v.UploadURLExpiresAt,
		CreatedAt:          v.CreatedAt,
		UpdatedAt:          v.UpdatedAt,
	}
}

func VideosToVideos(dto []Video) []model.Video {
	videos := []model.Video{}
	for _, video := range dto {
		videos = append(videos, video.ToVideo())
	}

	return videos
}
