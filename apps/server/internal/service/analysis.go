// @date 2026-09-06
// @file analysis.go
// @brief Application service orchestrating analysis workflows.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type analysisRepository interface {
	GetCompletedVideoInfoByUserID(context.Context, uuid.UUID, uuid.UUID) (*model.VideoInfo, error)
	CreateAnalysis(context.Context, *model.NewAnalysis) (*model.Analysis, error)
	GetAnalysis(context.Context, uuid.UUID) (*model.Analysis, error)
	WithTransaction(context.Context, func(context.Context) error) error
}

type analysisQueue interface {
	PublishJSONIntoQueueAI(ctx context.Context, body []byte) error
}

type AnalysisService struct {
	repo  analysisRepository
	queue analysisQueue
}

func NewAnalysisService(repo analysisRepository, queue analysisQueue) AnalysisService {
	return AnalysisService{repo: repo, queue: queue}
}

func (s *AnalysisService) TriggerAnalysis(ctx context.Context, videoID uuid.UUID, userID uuid.UUID, analysisType model.AnalysisType) (*model.Analysis, error) {
	if analysisType == "" {
		analysisType = model.AnalysisType2D
	}

	videoInfo, err := s.repo.GetCompletedVideoInfoByUserID(ctx, videoID, userID)
	if err != nil {
		return nil, err
	}

	var analysis *model.Analysis
	if err := s.repo.WithTransaction(ctx, func(ctx context.Context) error {
		analysis, err = s.repo.CreateAnalysis(ctx, &model.NewAnalysis{
			VideoID: videoID,
			Type:    analysisType,
		})
		if err != nil {
			return err
		}

		videoURL := fmt.Sprintf("s3://%s/%s", videoInfo.Bucket, videoInfo.ObjectKey)

		data, err := json.Marshal(struct {
			AnalysisID   uuid.UUID `json:"analysis_id"`
			VideoURL     string    `json:"video_url"`
			Type         string    `json:"type"`
			PipelineName string    `json:"pipeline_name,omitempty"`
		}{
			AnalysisID:   analysis.ID,
			VideoURL:     videoURL,
			Type:         string(analysis.Type),
			PipelineName: string(analysis.Type),
		})
		if err != nil {
			return err
		}

		if err := s.queue.PublishJSONIntoQueueAI(ctx, data); err != nil {
			return err
		}

		return nil
	}); err != nil {
		return nil, err
	}

	return analysis, nil
}

func (s *AnalysisService) GetAnalysis(ctx context.Context, id uuid.UUID) (*model.Analysis, error) {
	analysis, err := s.repo.GetAnalysis(ctx, id)
	if err != nil {
		return nil, err
	}
	return analysis, nil
}
