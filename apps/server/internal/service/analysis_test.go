// @date 2026-11-13
// @file analysis_test.go
// @brief Unit tests of the analysis job sent to the AI worker.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

// recordingQueue keeps the bodies of the published jobs.
type recordingQueue struct {
	bodies [][]byte
	err    error
}

func (q *recordingQueue) PublishPoseDetectRequested(_ context.Context, body []byte) error {
	q.bodies = append(q.bodies, body)
	return q.err
}

func TestTriggerAnalysisPublishesThePoseDetectRequest(t *testing.T) {
	repo := memrepo.New()
	queue := &recordingQueue{}
	s := NewAnalysisService(repo, repo, queue)
	userID := uuid.NewV7()
	video := model.Video{ID: uuid.NewV7(), UserID: userID, ObjectKey: "user/video.mp4", Status: model.VideoStatusCompleted}
	repo.PutVideo(video)

	analysis, err := s.TriggerAnalysis(context.Background(), userID, model.AnalysisConfig{VideoID: video.ID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate})
	if err != nil {
		t.Fatalf("TriggerAnalysis() error = %v", err)
	}

	if len(queue.bodies) != 1 {
		t.Fatalf("published %d jobs, want 1", len(queue.bodies))
	}
	// Exactly the fields of schemas/pose_detect_request.schema.json.
	var body map[string]any
	if err := json.Unmarshal(queue.bodies[0], &body); err != nil {
		t.Fatalf("job body is not JSON: %v", err)
	}
	want := map[string]any{"job_id": analysis.ID.String(), "object_key": "user/video.mp4"}
	if len(body) != len(want) || body["job_id"] != want["job_id"] || body["object_key"] != want["object_key"] {
		t.Errorf("job body = %v, want %v", body, want)
	}
}

func TestTriggerAnalysisFailsWhenTheJobCannotBePublished(t *testing.T) {
	repo := memrepo.New()
	s := NewAnalysisService(repo, repo, &recordingQueue{err: errors.New("broker down")})
	userID := uuid.NewV7()
	video := model.Video{ID: uuid.NewV7(), UserID: userID, ObjectKey: "k.mp4", Status: model.VideoStatusCompleted}
	repo.PutVideo(video)

	if _, err := s.TriggerAnalysis(context.Background(), userID, model.AnalysisConfig{VideoID: video.ID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate}); err == nil {
		t.Error("TriggerAnalysis() error = nil, want the publish error")
	}
}

func TestJobStatusValidate(t *testing.T) {
	for _, status := range []model.JobStatus{"pending", "started", "running", "success", "failed"} {
		if err := status.Validate(); err != nil {
			t.Errorf("JobStatus(%q).Validate() = %v, want nil", status, err)
		}
	}
	for _, status := range []model.JobStatus{"processing", "generating_hints", "completed", ""} {
		if err := status.Validate(); err == nil {
			t.Errorf("JobStatus(%q).Validate() = nil, want an error", status)
		}
	}
}
