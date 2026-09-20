package request

import (
	"fmt"
	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type VideoUpload struct {
	ContentType       string     `json:"content_type" binding:"required"`
	Size              int        `json:"size" binding:"required"`
	ClimbingSessionID *uuid.UUID `json:"climbing_session_id"`
	Title             *string    `json:"title"`
	Visibility        string     `json:"visibility" binding:"required"`
	Retained          bool       `json:"retained"`
}

func (req VideoUpload) IntoVideoMetadataAndVideoConfig() (model.VideoMetadata, model.VideoConfig, error) {
	videoMetadata, err := model.NewVideoMetadata(req.ContentType, req.Size)
	if err != nil {
		return model.VideoMetadata{}, model.VideoConfig{}, fmt.Errorf("videometadata: %w", err)
	}
	videoConfig := model.VideoConfig{
		ClimbingSessionID: req.ClimbingSessionID,
		Title:             req.Title,
		Visibility:        model.Visibility(req.Visibility),
		Retained:          req.Retained,
	}

	return videoMetadata, videoConfig, nil
}
