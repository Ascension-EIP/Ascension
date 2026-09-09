// @date 2026-03-19
// @file analysis.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

type AnalysisService struct {
	analysisRepo model.AnalysisRepository
	videoRepo    model.VideoRepository
	queue        model.AnalysisQueue
}

func NewAnalysisService(analysisRepo model.AnalysisRepository, videoRepo model.VideoRepository, queue model.AnalysisQueue) AnalysisService {
	return AnalysisService{analysisRepo: analysisRepo, videoRepo: videoRepo, queue: queue}
}

func (s *AnalysisService) TriggerAnalysis(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) (*model.Analysis, error) {
	videoInfo, err := s.videoRepo.GetCompletedVideoInfoByUserID(ctx, videoID, userID)
	if err != nil {
		return nil, err
	}

	var analysis *model.Analysis
	if err := s.analysisRepo.WithTransaction(ctx, func(ctx context.Context) error {
		analysis, err = s.analysisRepo.CreateAnalysis(ctx, &model.NewAnalysis{VideoID: videoID})
		if err != nil {
			return err
		}

		videoURL := fmt.Sprintf("s3://%s/%s", videoInfo.Bucket, videoInfo.ObjectKey)

		data, err := json.Marshal(struct {
			AnalysisID uuid.UUID `json:"analysis_id"`
			VideoURL   string    `json:"video_url"`
		}{
			AnalysisID: analysis.ID,
			VideoURL:   videoURL,
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
	analysis, err := s.analysisRepo.GetAnalysis(ctx, id)
	if err != nil {
		return nil, err
	}
	return analysis, nil
}
