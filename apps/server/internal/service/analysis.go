package service

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type analysisRepository interface {
	GetVideoInfoByUserID(context.Context, uuid.UUID, uuid.UUID) (*model.VideoInfo, error)
	CreateAnalysis(context.Context, *model.NewAnalysis) (*model.Analysis, error)
	GetAnalysis(context.Context, uuid.UUID, uuid.UUID) (*model.Analysis, error)
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

func (s *AnalysisService) TriggerAnalysis(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) (*model.Analysis, error) {
	videoInfo, err := s.repo.GetVideoInfoByUserID(ctx, videoID, userID)
	if err != nil {
		return nil, err
	}

	var analysis *model.Analysis
	if err := s.repo.WithTransaction(ctx, func(ctx context.Context) error {
		analysis, err := s.repo.CreateAnalysis(ctx, &model.NewAnalysis{VideoID: userID})
		if err != nil {
			return err
		}

		videoURL := fmt.Sprintf("s3://%s/%s", videoInfo.Bucket, videoInfo.ObjectKey)

		data, err := json.Marshal(struct {
			AnalysisID uuid.UUID
			VideoURL   string
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

func (s *AnalysisService) GetAnalysis(ctx context.Context, id uuid.UUID, userID uuid.UUID) (*model.Analysis, error) {
	analysis, err := s.repo.GetAnalysis(ctx, id, userID)
	if err != nil {
		return nil, err
	}
	return analysis, nil
}
