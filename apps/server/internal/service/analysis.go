// @date 2026-11-13
// @file analysis.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/shared"
)

type AnalysisService struct {
	cfg       config.StorageConfig
	analysisR model.AnalysisRepository
	videoR    model.VideoRepository
	queue     model.AnalysisQueue
}

func NewAnalysisService(cfg config.StorageConfig, analysisR model.AnalysisRepository, videoR model.VideoRepository, queue model.AnalysisQueue) AnalysisService {
	return AnalysisService{cfg: cfg, analysisR: analysisR, videoR: videoR, queue: queue}
}

func (s *AnalysisService) TriggerAnalysis(ctx context.Context, userID uuid.UUID, analysisConfig model.AnalysisConfig) (model.Analysis, error) {
	if err := analysisConfig.Validate(); err != nil {
		return model.Analysis{}, fmt.Errorf("validate analysisConfig: %w", err)
	}

	video, err := s.videoR.GetVideoByFilter(ctx, model.VideoFilter{ID: &analysisConfig.VideoID, UserID: &userID})
	if err != nil {
		return model.Analysis{}, err
	}

	if video.Status != model.VideoStatusCompleted {
		return model.Analysis{}, model.ErrVideoUploading
	}

	var analysis model.Analysis
	if err := s.analysisR.WithTransaction(ctx, func(ctx context.Context) error {
		analysis, err = s.analysisR.CreateAnalysis(ctx, model.Analysis{VideoID: analysisConfig.VideoID, Type: analysisConfig.Type, Visibility: analysisConfig.Visibility})
		if err != nil {
			return err
		}

		data, err := json.Marshal(
			shared.PoseDetectRequest{
				JobID:     analysis.ID.String(),
				ObjectKey: video.ObjectKey,
			})
		if err != nil {
			return err
		}

		if err := s.queue.PublishPoseDetectRequested(ctx, data); err != nil {
			return err
		}

		return nil
	}); err != nil {
		return model.Analysis{}, err
	}

	return analysis, nil
}

func (s *AnalysisService) GetAnalysisByID(ctx context.Context, videoID uuid.UUID) (model.Analysis, error) {
	analysis, err := s.analysisR.GetAnalysisByFilter(ctx, model.AnalysisFilter{ID: &videoID})
	if err != nil {
		return model.Analysis{}, err
	}

	return analysis, nil
}

// ListAnalyses returns one page of the analyses of the user's videos, newest first, with
// the climbing session of each one (nil for an analysis outside any session).
func (s *AnalysisService) ListAnalyses(ctx context.Context, userID uuid.UUID, pagination model.Pagination) (model.AnalysisSummaryPage, error) {
	analyses, total, err := s.analysisR.ListAnalysisSummariesByUserID(ctx, userID, pagination)
	if err != nil {
		return model.AnalysisSummaryPage{}, err
	}

	return model.AnalysisSummaryPage{Analyses: analyses, Total: total, Pagination: pagination}, nil
}

func (s *AnalysisService) AnalysisStaleDetection(ctx context.Context) error {
	analyses, err := s.analysisR.ListAnalysisByFilter(ctx, model.AnalysisFilter{Status: new(model.JobStatusPending)}, model.Pagination{Limit: 0, Offset: 0})
	if err != nil {
		return err
	}

	errStack := []error{}
	s.analysisR.WithTransaction(ctx, func(ctx context.Context) error {
		for _, analysis := range analyses {
			if analysis.CreatedAt.Before(time.Now().Add(-time.Minute * 15)) {
				if _, err := s.analysisR.UpdateAnalysis(ctx, model.AnalysisPartial{ID: analysis.ID, Status: new(model.JobStatusFailed), Error: new(new("Job processing timed out"))}); err != nil {
					errStack = append(errStack, fmt.Errorf("%v: %w", analysis.ID, err))
				}
			}
		}

		return nil
	})

	if len(errStack) > 0 {
		return errors.Join(errStack...)
	}

	return nil
}

func (s *AnalysisService) RetryAdvice(ctx context.Context, id uuid.UUID) (model.Analysis, error) {
	// s.analysisR.GetAnalysisByFilter(ctx, model.AnalysisFilter{ID: new(id), Status: new(model.JobStatusFailed)})
	// TODO

	return model.Analysis{}, nil
}
