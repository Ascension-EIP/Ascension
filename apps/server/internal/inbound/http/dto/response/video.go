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
