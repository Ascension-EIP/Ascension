package response

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type AnalysisResponse struct {
	ID     uuid.UUID            `json:"id"`
	Status model.AnalysisStatus `json:"status"`
}

func AnalysisToResponse(analysis *model.Analysis) *AnalysisResponse {
	return &AnalysisResponse{
		ID:     analysis.ID,
		Status: analysis.Status,
	}
}

type AnalysisInfoResponse struct {
	ID     uuid.UUID            `json:"id"`
	Status model.AnalysisStatus `json:"status"`
}

func AnalysisInfoToResponse(analysis *model.Analysis) *AnalysisInfoResponse {
	return &AnalysisInfoResponse{
		ID:     analysis.ID,
		Status: analysis.Status,
	}
}
