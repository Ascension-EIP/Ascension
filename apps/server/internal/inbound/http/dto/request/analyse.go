// @date 2026-09-07
// @file analyse.go
// @brief Request DTO for analysis endpoints.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type CreateAnalyseRequest struct {
	VideoID uuid.UUID          `json:"video_id" binding:"required"`
	Type    model.AnalysisType `json:"type"`
}
