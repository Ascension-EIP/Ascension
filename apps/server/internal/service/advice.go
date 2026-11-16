// @date 2026-11-15
// @file advice.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/shared"
)

type AdviceService struct {
	cfg     config.StorageConfig
	adviceR model.AdviceRepository
	videoR  model.VideoRepository
	queue   model.AdviceQueue
}

func NewAdviceService(cfg config.StorageConfig, adviceR model.AdviceRepository, videoR model.VideoRepository, queue model.AdviceQueue) AdviceService {
	return AdviceService{cfg: cfg, adviceR: adviceR, videoR: videoR, queue: queue}
}

func (s *AdviceService) TriggerAdvice(ctx context.Context, userID uuid.UUID, videoID uuid.UUID) (model.Advice, error) {
	video, err := s.videoR.GetVideoByFilter(ctx, model.VideoFilter{ID: &videoID, UserID: &userID})
	if err != nil {
		return model.Advice{}, err
	}

	if video.Status != model.VideoStatusCompleted {
		return model.Advice{}, model.ErrVideoUploading
	}

	advice, err := s.adviceR.CreateAdvice(ctx, videoID)
	if err != nil {
		return model.Advice{}, err
	}

	if err := s.queue.PublishPoseAdviceRequested(ctx, shared.Job{
		JobID: advice.ID.String(),
	}); err != nil {
		_, _ = s.adviceR.UpdateAdvice(ctx, model.AdvicePartial{ID: advice.ID, Status: new(model.JobStatusFailed), Error: new(new("failed to publish job: " + err.Error()))})
		return model.Advice{}, err
	}

	return advice, nil
}

func (s *AdviceService) GetAdviceByVideoID(ctx context.Context, videoID uuid.UUID) (model.Advice, error) {
	return s.adviceR.GetAdviceByFilter(ctx, model.AdviceFilter{ID: &videoID})
}

func (s *AdviceService) RetryAdvice(ctx context.Context, videoID uuid.UUID) (model.Advice, error) {
	advice, err := s.adviceR.GetAdviceByFilter(ctx, model.AdviceFilter{ID: &videoID, Status: new(model.JobStatusFailed)})
	if err != nil {
		return model.Advice{}, err
	}

	advice, err = s.adviceR.UpdateAdvice(ctx, model.AdvicePartial{
		ID:       advice.ID,
		Status:   new(model.JobStatusPending),
		Progress: new(int16(0)),
		Error:    new(*string),
		Result:   new(*shared.Hints),
	})
	if err != nil {
		return model.Advice{}, err
	}

	if err := s.queue.PublishPoseAdviceRequested(ctx, shared.Job{
		JobID: advice.ID.String(),
	}); err != nil {
		_, _ = s.adviceR.UpdateAdvice(ctx, model.AdvicePartial{ID: advice.ID, Status: new(model.JobStatusFailed), Error: new(new("failed to publish job: " + err.Error()))})
		return model.Advice{}, err
	}

	return advice, nil
}

func (s *AdviceService) AdviceStaleDetection(ctx context.Context) error {
	advices, err := s.adviceR.ListAdviceByFilter(ctx, model.AdviceFilter{Status: new(model.JobStatusPending)}, model.Pagination{})
	if err != nil {
		return err
	}

	errStack := []error{}
	s.adviceR.WithTransaction(ctx, func(ctx context.Context) error {
		for _, advice := range advices {
			if advice.CreatedAt.Before(time.Now().Add(-time.Minute * 15)) {
				if _, err := s.adviceR.UpdateAdvice(ctx, model.AdvicePartial{
					ID:     advice.ID,
					Status: new(model.JobStatusFailed),
					Error:  new(new("Job processing timed out")),
				}); err != nil {
					errStack = append(errStack, fmt.Errorf("%v: %w", advice.ID, err))
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
