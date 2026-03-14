package response

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

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
