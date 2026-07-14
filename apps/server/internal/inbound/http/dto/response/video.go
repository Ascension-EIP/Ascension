package response

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type DownloadURL struct {
	URL       string    `json:"download_url"`
	ExpiresAt time.Time `json:"expires_at"`
}

func DownloadURLToResponse(downloadVideoURL *model.DownloadVideoURL) *DownloadURL {
	return &DownloadURL{
		URL:       downloadVideoURL.URL.String(),
		ExpiresAt: downloadVideoURL.ExpiresAt,
	}
}

type UploadURL struct {
	ID        uuid.UUID `json:"video_id"`
	URL       string    `json:"upload_url"`
	ExpiresAt time.Time `json:"expires_at"`
}

func UploadURLToResponse(uploadVideoURL *model.UploadVideoURL) *UploadURL {
	return &UploadURL{
		ID:        uploadVideoURL.VideoID,
		URL:       uploadVideoURL.URL.String(),
		ExpiresAt: uploadVideoURL.ExpiresAt,
	}
}
