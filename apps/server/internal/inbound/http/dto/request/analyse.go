// @date 2026-03-18
// @file analyse.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type CreateAnalyseRequest struct {
	VideoID    uuid.UUID `json:"video_id" binding:"required"`
	Type       string    `json:"type" binding:"required"`
	Visibility string    `json:"visibility" binding:"required"`
}

func (req CreateAnalyseRequest) IntoAnalysisConfig() model.AnalysisConfig {
	return model.AnalysisConfig{
		VideoID:    req.VideoID,
		Type:       model.AnalysisType(req.Type),
		Visibility: model.Visibility(req.Visibility),
	}
}
