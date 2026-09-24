// @date 2026-09-12
// @file video.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package response

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

type DownloadURL struct {
	URL       string    `json:"download_url"`
	ExpiresAt time.Time `json:"expires_at"`
}

func DownloadURLToResponse(url model.VideoDownloadURL) DownloadURL {
	return DownloadURL{
		URL:       url.URL.String(),
		ExpiresAt: url.ExpiresAt,
	}
}

type UploadURL struct {
	ID        uuid.UUID `json:"video_id"`
	URL       string    `json:"upload_url"`
	ExpiresAt time.Time `json:"expires_at"`
}

func UploadURLToResponse(url model.VideoUploadURL) UploadURL {
	return UploadURL{
		ID:        url.VideoID,
		URL:       url.URL.String(),
		ExpiresAt: url.ExpiresAt,
	}
}

type Video struct {
	ID                 uuid.UUID
	UserID             uuid.UUID
	ClimbingSessionID  *uuid.UUID
	Title              *string
	ObjectKey          string
	Status             string
	Visibility         string
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

func VideoToResponse(video model.Video) Video {
	return Video{
		ID:                 video.ID,
		UserID:             video.UserID,
		ClimbingSessionID:  video.ClimbingSessionID,
		Title:              video.Title,
		ObjectKey:          video.ObjectKey,
		Status:             string(video.Status),
		Visibility:         string(video.Visibility),
		Width:              video.Width,
		Height:             video.Height,
		FPS:                video.FPS,
		ContentType:        video.ContentType,
		DurationMS:         video.DurationMS,
		SizeBytes:          video.SizeBytes,
		Retained:           video.Retained,
		UploadURLExpiresAt: video.UploadURLExpiresAt,
		CreatedAt:          video.CreatedAt,
		UpdatedAt:          video.UpdatedAt,
	}
}

func VideosToResponse(videos []model.Video) []Video {
	r := make([]Video, 0, len(videos))
	for _, video := range videos {
		r = append(r, VideoToResponse(video))
	}

	return r
}
