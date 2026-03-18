package request

import "github.com/google/uuid"

type CreateAnalyseRequest struct {
	VideoID uuid.UUID `json:"video_id"`
}
