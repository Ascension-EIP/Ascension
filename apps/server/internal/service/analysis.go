// @date 2026-11-13
// @file analysis.go
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"encoding/json"
	"fmt"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

// PoseDetectRequest is the job sent to the AI worker (schemas/pose_detect_request.schema.json):
// JobID is the id of the analysis row, ObjectKey the video in the bucket.
type PoseDetectRequest struct {
	JobID     uuid.UUID `json:"job_id"`
	ObjectKey string    `json:"object_key"`
}

type AnalysisService struct {
	analysisR model.AnalysisRepository
	videoR    model.VideoRepository
	queue     model.AnalysisQueue
}

func NewAnalysisService(analysisR model.AnalysisRepository, videoR model.VideoRepository, queue model.AnalysisQueue) AnalysisService {
	return AnalysisService{analysisR: analysisR, videoR: videoR, queue: queue}
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

		data, err := json.Marshal(PoseDetectRequest{JobID: analysis.ID, ObjectKey: video.ObjectKey})
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
