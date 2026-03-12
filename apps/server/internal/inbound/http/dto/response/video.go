package response

import (
	"time"

	"github.com/google/uuid"
)

type UploadURL struct {
	ID        uuid.UUID `json:"video_id"`
	URL       string    `json:"upload_url"`
	ExpiresAt time.Time `json:"expires_at"`
}
