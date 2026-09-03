// @date 2026-03-20
// @file video.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
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
		UserID    uuid.UUID
		Extension string
		Size      int
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
		ID        uuid.UUID
		UserID    uuid.UUID
		Bucket    string
		ObjectKey string
		Status    VideoStatus
		ExpiresAt time.Time
	}

	PartialVideoInfo struct {
		ID        uuid.UUID
		UserID    uuid.UUID
		Bucket    *string
		ObjectKey *string
		Status    *VideoStatus
		ExpiresAt *time.Time
	}
)
