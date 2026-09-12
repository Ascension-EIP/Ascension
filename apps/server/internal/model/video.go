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

	"uuid"
)

type VideoStatus string

const (
	VideoStatusPending   VideoStatus = "pending"
	VideoStatusCompleted VideoStatus = "completed"
)

type FileInfo struct {
	UserID    uuid.UUID
	Extension string
	Size      int
}

type VideoDownloadURL struct {
	URL       *url.URL
	ExpiresAt time.Time
}

type VideoUploadURL struct {
	VideoID   uuid.UUID
	URL       *url.URL
	ExpiresAt time.Time
}

type Video struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Bucket    string
	ObjectKey string
	Status    VideoStatus
	ExpiresAt time.Time
}

type VideoFilter struct {
	ID        *uuid.UUID
	UserID    *uuid.UUID
	Bucket    *string
	ObjectKey *string
	Status    *VideoStatus
	ExpiresAt *time.Time
}

type VideoPartial struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Bucket    *string
	ObjectKey *string
	Status    *VideoStatus
	ExpiresAt *time.Time
}
