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

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
)

type AnalysisService struct {
	cfg       config.MinIOConfig
	analysisR model.AnalysisRepository
	videoR    model.VideoRepository
	queue     model.AnalysisQueue
}

func NewAnalysisService(cfg config.MinIOConfig, analysisR model.AnalysisRepository, videoR model.VideoRepository, queue model.AnalysisQueue) AnalysisService {
	return AnalysisService{cfg: cfg, analysisR: analysisR, videoR: videoR, queue: queue}
}

func (s *AnalysisService) TriggerAnalysis(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) (model.Analysis, error) {
	video, err := s.videoR.GetVideoByFilter(ctx, model.VideoFilter{ID: &videoID, UserID: &userID})
	if err != nil {
		return model.Analysis{}, err
	}

	if video.Status != model.VideoStatusCompleted {
		return model.Analysis{}, model.ErrVideoUploading
	}

	var analysis model.Analysis
	if err := s.analysisR.WithTransaction(ctx, func(ctx context.Context) error {
		analysis, err = s.analysisR.CreateAnalysis(ctx, model.Analysis{VideoID: videoID})
		if err != nil {
			return err
		}

		videoURL := fmt.Sprintf("s3://%s/%s", s.cfg.BucketName, video.ObjectKey)

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
		return model.Analysis{}, err
	}

	return analysis, nil
}

func (s *AnalysisService) GetAnalysis(ctx context.Context, videoID uuid.UUID) (model.Analysis, error) {
	analysis, err := s.analysisR.GetAnalysisByFilter(ctx, model.AnalysisFilter{ID: &videoID})
	if err != nil {
		return model.Analysis{}, err
	}

	return analysis, nil
}
