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
	"encoding/json"
	"errors"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/shared"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

func (q *recordingQueue) PublishPoseAdviceRequested(_ context.Context, req shared.Job) error {
	if q.err != nil {
		return q.err
	}
	body, _ := json.Marshal(req)
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

func TestTriggerAdviceFailsWhenQueueFails(t *testing.T) {
	repo := memrepo.New()
	queue := &recordingQueue{err: errors.New("queue error")}

	video := model.Video{ID: uuid.NewV7(), UserID: uuid.NewV7(), Status: model.VideoStatusCompleted, ObjectKey: "test/video.mp4"}
	if err := repo.CreateVideo(context.Background(), video); err != nil {
		t.Fatalf("CreateVideo: %v", err)
	}

	s := NewAdviceService(config.StorageConfig{}, repo, repo, queue)

	_, err := s.TriggerAdvice(context.Background(), video.UserID, video.ID)
	if err == nil {
		t.Fatal("TriggerAdvice() error = nil, want queue error")
	}

	advice, err := s.GetAdviceByVideoID(context.Background(), video.ID)
	if err != nil {
		t.Fatalf("GetAdviceByVideoID: %v", err)
	}
	if advice.Status != model.JobStatusFailed {
		t.Errorf("advice.Status = %v, want %v", advice.Status, model.JobStatusFailed)
	}
}

func TestTriggerAdviceVideoNotFound(t *testing.T) {
	repo := memrepo.New()
	s := NewAdviceService(config.StorageConfig{}, repo, repo, &recordingQueue{})
	_, err := s.TriggerAdvice(context.Background(), uuid.NewV7(), uuid.NewV7())
	if !errors.Is(err, model.ErrNotFound) {
		t.Errorf("TriggerAdvice() error = %v, want ErrNotFound", err)
	}
}

func TestGetAdviceByVideoIDNotFound(t *testing.T) {
	repo := memrepo.New()
	s := NewAdviceService(config.StorageConfig{}, repo, repo, &recordingQueue{})
	_, err := s.GetAdviceByVideoID(context.Background(), uuid.NewV7())
	if !errors.Is(err, model.ErrNotFound) {
		t.Errorf("GetAdviceByVideoID() error = %v, want ErrNotFound", err)
	}
}

func TestRetryAdviceSuccess(t *testing.T) {
	repo := memrepo.New()
	queue := &recordingQueue{}

	video := model.Video{ID: uuid.NewV7(), UserID: uuid.NewV7(), Status: model.VideoStatusCompleted, ObjectKey: "test/video.mp4"}
	if err := repo.CreateVideo(context.Background(), video); err != nil {
		t.Fatalf("CreateVideo: %v", err)
	}

	s := NewAdviceService(config.StorageConfig{}, repo, repo, queue)
	advice, err := s.TriggerAdvice(context.Background(), video.UserID, video.ID)
	if err != nil {
		t.Fatalf("TriggerAdvice: %v", err)
	}

	failedStatus := model.JobStatusFailed
	failedMsg := "failed"
	pFailedMsg := &failedMsg
	if _, err := repo.UpdateAdvice(context.Background(), model.AdvicePartial{
		ID:     advice.ID,
		Status: &failedStatus,
		Error:  &pFailedMsg,
	}); err != nil {
		t.Fatalf("UpdateAdvice: %v", err)
	}

	retried, err := s.RetryAdvice(context.Background(), video.ID)
	if err != nil {
		t.Fatalf("RetryAdvice() error = %v", err)
	}
	if retried.Status != model.JobStatusPending {
		t.Errorf("retried.Status = %v, want pending", retried.Status)
	}
	if len(queue.bodies) != 2 {
		t.Errorf("queue.bodies len = %d, want 2", len(queue.bodies))
	}
}

func TestRetryAdviceFailsWhenQueueFails(t *testing.T) {
	repo := memrepo.New()
	queue := &recordingQueue{}

	video := model.Video{ID: uuid.NewV7(), UserID: uuid.NewV7(), Status: model.VideoStatusCompleted, ObjectKey: "test/video.mp4"}
	if err := repo.CreateVideo(context.Background(), video); err != nil {
		t.Fatalf("CreateVideo: %v", err)
	}

	s := NewAdviceService(config.StorageConfig{}, repo, repo, queue)
	advice, err := s.TriggerAdvice(context.Background(), video.UserID, video.ID)
	if err != nil {
		t.Fatalf("TriggerAdvice: %v", err)
	}

	failedStatus := model.JobStatusFailed
	failedMsg := "failed"
	pFailedMsg := &failedMsg
	if _, err := repo.UpdateAdvice(context.Background(), model.AdvicePartial{
		ID:     advice.ID,
		Status: &failedStatus,
		Error:  &pFailedMsg,
	}); err != nil {
		t.Fatalf("UpdateAdvice: %v", err)
	}

	queue.err = errors.New("queue error")
	_, err = s.RetryAdvice(context.Background(), video.ID)
	if err == nil {
		t.Fatal("RetryAdvice() error = nil, want queue error")
	}

	got, _ := s.GetAdviceByVideoID(context.Background(), video.ID)
	if got.Status != model.JobStatusFailed {
		t.Errorf("got.Status = %v, want failed", got.Status)
	}
}

func TestAdviceStaleDetection(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewAdviceService(config.StorageConfig{}, repo, repo, &recordingQueue{})

	now := time.Now()
	staleVideo := model.Video{ID: uuid.NewV7(), Status: model.VideoStatusCompleted}
	repo.PutVideo(staleVideo)
	repo.SetNow(func() time.Time { return now.Add(-20 * time.Minute) })
	if _, err := repo.CreateAdvice(ctx, staleVideo.ID); err != nil {
		t.Fatalf("CreateAdvice: %v", err)
	}

	recentVideo := model.Video{ID: uuid.NewV7(), Status: model.VideoStatusCompleted}
	repo.PutVideo(recentVideo)
	repo.SetNow(func() time.Time { return now.Add(-5 * time.Minute) })
	if _, err := repo.CreateAdvice(ctx, recentVideo.ID); err != nil {
		t.Fatalf("CreateAdvice: %v", err)
	}
	repo.SetNow(time.Now)

	if err := s.AdviceStaleDetection(ctx); err != nil {
		t.Fatalf("AdviceStaleDetection() error = %v", err)
	}

	stale, err := s.GetAdviceByVideoID(ctx, staleVideo.ID)
	if err != nil {
		t.Fatalf("GetAdviceByVideoID: %v", err)
	}
	if stale.Status != model.JobStatusFailed {
		t.Errorf("stale.Status = %v, want failed", stale.Status)
	}

	recent, err := s.GetAdviceByVideoID(ctx, recentVideo.ID)
	if err != nil {
		t.Fatalf("GetAdviceByVideoID: %v", err)
	}
	if recent.Status != model.JobStatusPending {
		t.Errorf("recent.Status = %v, want pending", recent.Status)
	}
}
