// @date 2026-03-20
// @file video.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"fmt"
	"net/url"
	"time"

	"uuid"
)

type VideoStatus string

const (
	VideoStatusPending   VideoStatus = "pending"
	VideoStatusCompleted VideoStatus = "completed"
)

type Visibility string

const (
	VisibilityPrivate Visibility = "private"
	VisibilityFriends Visibility = "friends"
	VisibilityPublic  Visibility = "public"
)

func (v Visibility) Validate() error {
	switch v {
	case VisibilityPrivate, VisibilityFriends, VisibilityPublic:
		return nil
	default:
		return fmt.Errorf("unknown")
	}
}

// -- Input type -- //

type VideoMetadata struct {
	ContentType string
	Extension   string
	Size        int
}

func NewVideoMetadata(contentType string, size int) (VideoMetadata, error) {
	var allowedContentTypes = map[string]string{
		"video/mp4":        "mp4",
		"video/webm":       "webm",
		"video/quicktime":  "mov",
		"video/x-matroska": "mkv",
		"video/x-msvideo":  "avi",
	}

	ext, ok := allowedContentTypes[contentType]
	if !ok {
		return VideoMetadata{}, fmt.Errorf("content type unsupported: %s", contentType)
	}

	if size > 1*1024*1024*1024 {
		return VideoMetadata{}, fmt.Errorf("size: too big (1GB max)")
	}

	return VideoMetadata{
		ContentType: contentType,
		Extension:   ext,
		Size:        size,
	}, nil
}

type VideoConfig struct {
	ClimbingSessionID *uuid.UUID
	Title             *string
	Visibility        Visibility
	Retained          bool
}

func (v VideoConfig) Validate() error {
	if err := v.Visibility.Validate(); err != nil {
		return fmt.Errorf("visibility: %w", err)
	}

	return nil
}

// -- Working type -- //

type Video struct {
	ID                 uuid.UUID
	UserID             uuid.UUID
	ClimbingSessionID  *uuid.UUID
	Title              *string
	ObjectKey          string
	Status             VideoStatus
	Visibility         Visibility
	Width              *int16
	Height             *int16
	FPS                *float64
	ContentType        string
	DurationMS         *time.Duration
	SizeBytes          *int
	Retained           bool
	UploadURLExpiresAt *time.Time
	CreatedAt          time.Time
	UpdatedAt          time.Time
}

type VideoFilter struct {
	ID          *uuid.UUID
	UserID      *uuid.UUID
	ObjectKey   *string
	Status      *VideoStatus
	Visibility  *Visibility
	ContentType *string
	Retained    *bool
}

type VideoPartial struct {
	ID                 uuid.UUID
	UserID             uuid.UUID
	ClimbingSessionID  **uuid.UUID
	Title              **string
	ObjectKey          *string
	Status             *VideoStatus
	Visibility         *Visibility
	Width              **int16
	Height             **int16
	FPS                **float64
	ContentType        *string
	DurationMs         **time.Duration
	SizeBytes          **int
	Retained           *bool
	UploadURLExpiresAt **time.Time
}

// -- Output type -- //

type VideoDownloadURL struct {
	URL       *url.URL
	ExpiresAt time.Time
}

type VideoUploadURL struct {
	VideoID   uuid.UUID
	URL       *url.URL
	ExpiresAt time.Time
}
