package model

import (
	"net/url"
	"time"

	"github.com/google/uuid"
)

type VideoState string

const (
	VideoStatePending   = "pending"
	VideoStateCompleted = "completed"
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
		State     VideoState
		ExpiresAt time.Time
	}
)
