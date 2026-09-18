// @date 2026-09-18
// @file video.go
// @brief Domain models for videos.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"net/url"
	"time"

	"github.com/google/uuid"
)

type VideoStatus string

const (
	VideoStatusPending   VideoStatus = "pending"
	VideoStatusCompleted VideoStatus = "completed"
)

type (
	FileInfo struct {
		UserID      uuid.UUID
		ContentType string
		Extension   string
		Size        int64
	}

	DownloadVideoURL struct {
		URL       *url.URL
		ExpiresAt time.Time
	}

	UploadVideoURL struct {
		VideoID   uuid.UUID
		URL       *url.URL
		ExpiresAt time.Time
	}

	VideoInfo struct {
		ID                uuid.UUID
		UserID            uuid.UUID
		ClimbingSessionID *uuid.UUID
		Title             *string
		ObjectKey         string
		ContentType       string
		Status            VideoStatus
		SizeBytes         *int64
		DurationMs        *int32
		Width             *int16
		Height            *int16
		FPS               *float64
		Retained          bool
		ExpiresAt         time.Time
		Visibility        string
		CreatedAt         time.Time
		UpdatedAt         time.Time
	}

	PartialVideoInfo struct {
		ID         uuid.UUID
		UserID     uuid.UUID
		ObjectKey  *string
		Status     *VideoStatus
		SizeBytes  *int64
		DurationMs *int32
		ExpiresAt  *time.Time
	}
)
