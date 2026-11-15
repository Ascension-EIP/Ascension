// @date 2026-11-15
// @file advice_test.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"testing"
	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

func (q *recordingQueue) PublishPoseAdviceRequested(_ context.Context, body []byte) error {
	if q.err != nil {
		return q.err
	}
	q.bodies = append(q.bodies, body)
	return nil
}

func TestTriggerAdvice(t *testing.T) {
	repo := memrepo.New()
	queue := &recordingQueue{}

	video := model.Video{ID: uuid.NewV7(), UserID: uuid.NewV7(), Status: model.VideoStatusCompleted, ObjectKey: "test/video.mp4"}
	if err := repo.CreateVideo(context.Background(), video); err != nil {
		t.Fatalf("CreateVideo: %v", err)
	}

	s := NewAdviceService(config.StorageConfig{}, repo, repo, queue)

	advice, err := s.TriggerAdvice(context.Background(), video.UserID, video.ID)
	if err != nil {
		t.Fatalf("TriggerAdvice() error = %v", err)
	}
	if advice.ID != video.ID {
		t.Errorf("advice.ID = %v, want %v (video ID)", advice.ID, video.ID)
	}
	if advice.Status != model.JobStatusPending {
		t.Errorf("advice.Status = %v, want pending", advice.Status)
	}
	if len(queue.bodies) != 1 {
		t.Errorf("queue.bodies len = %d, want 1", len(queue.bodies))
	}
}

func TestTriggerAdviceVideoNotCompleted(t *testing.T) {
	repo := memrepo.New()
	queue := &recordingQueue{}

	video := model.Video{ID: uuid.NewV7(), UserID: uuid.NewV7(), Status: model.VideoStatusPending, ObjectKey: "test/video.mp4"}
	if err := repo.CreateVideo(context.Background(), video); err != nil {
		t.Fatalf("CreateVideo: %v", err)
	}

	s := NewAdviceService(config.StorageConfig{}, repo, repo, queue)

	_, err := s.TriggerAdvice(context.Background(), video.UserID, video.ID)
	if err != model.ErrVideoUploading {
		t.Errorf("TriggerAdvice() error = %v, want ErrVideoUploading", err)
	}
}

func TestRetryAdviceNotFailed(t *testing.T) {
	repo := memrepo.New()
	queue := &recordingQueue{}

	video := model.Video{ID: uuid.NewV7(), UserID: uuid.NewV7(), Status: model.VideoStatusCompleted, ObjectKey: "test/video.mp4"}
	if err := repo.CreateVideo(context.Background(), video); err != nil {
		t.Fatalf("CreateVideo: %v", err)
	}

	s := NewAdviceService(config.StorageConfig{}, repo, repo, queue)

	_, err := s.RetryAdvice(context.Background(), video.ID)
	if err != model.ErrNotFound {
		t.Errorf("RetryAdvice() error = %v, want ErrNotFound", err)
	}
}
