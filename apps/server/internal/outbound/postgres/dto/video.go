// @date 2026-09-18
// @file video.go
// @brief Database transfer object for videos.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type Video struct {
	ID                uuid.UUID  `db:"id"`
	UserID            uuid.UUID  `db:"user_id"`
	ClimbingSessionID *uuid.UUID `db:"climbing_session_id"`
	Title             *string    `db:"title"`
	ObjectKey         string     `db:"object_key"`
	ContentType       string     `db:"content_type"`
	Status            string     `db:"status"`
	SizeBytes         *int64     `db:"size_bytes"`
	DurationMs        *int32     `db:"duration_ms"`
	Width             *int16     `db:"width"`
	Height            *int16     `db:"height"`
	FPS               *float64   `db:"fps"`
	Retained          bool       `db:"retained"`
	ExpiresAt         time.Time  `db:"expires_at"`
	Visibility        string     `db:"visibility"`
	CreatedAt         time.Time  `db:"created_at"`
	UpdatedAt         time.Time  `db:"updated_at"`
}

func (v *Video) ToVideoInfo() *model.VideoInfo {
	return &model.VideoInfo{
		ID:                v.ID,
		UserID:            v.UserID,
		ClimbingSessionID: v.ClimbingSessionID,
		Title:             v.Title,
		ObjectKey:         v.ObjectKey,
		ContentType:       v.ContentType,
		Status:            model.VideoStatus(v.Status),
		SizeBytes:         v.SizeBytes,
		DurationMs:        v.DurationMs,
		Width:             v.Width,
		Height:            v.Height,
		FPS:               v.FPS,
		Retained:          v.Retained,
		ExpiresAt:         v.ExpiresAt,
		Visibility:        v.Visibility,
		CreatedAt:         v.CreatedAt,
		UpdatedAt:         v.UpdatedAt,
	}
}
