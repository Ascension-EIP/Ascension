// @date 2026-03-18
// @file analyse.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import "github.com/google/uuid"

type CreateAnalyseRequest struct {
	VideoID uuid.UUID `json:"video_id"`
}
