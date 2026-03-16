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

	UploadVideoURL struct {
		VideoID   uuid.UUID
		URL       *url.URL
		ExpiresAt time.Time
	}

	VideoInfo struct {
		ID        uuid.UUID
		UserID    uuid.UUID
		ObjectKey string
		Status    VideoStatus
		ExpiresAt time.Time
	}

	PartialVideoInfo struct {
		ID        uuid.UUID
		UserID    uuid.UUID
		ObjectKey *string
		Status    *VideoStatus
		ExpiresAt *time.Time
	}
)
