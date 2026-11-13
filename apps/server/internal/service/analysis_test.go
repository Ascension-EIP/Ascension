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
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
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
	s := NewAnalysisService(config.StorageConfig{}, repo, repo, queue)
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
	s := NewAnalysisService(config.StorageConfig{}, repo, repo, &recordingQueue{err: errors.New("broker down")})
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

// failingAnalysisRepo is a memrepo whose analysis listing and update fail.
type failingAnalysisRepo struct {
	*memrepo.Repo
}

func (failingAnalysisRepo) ListAnalysisByFilter(context.Context, model.AnalysisFilter, model.Pagination) ([]model.Analysis, error) {
	return nil, errRepo
}

func (failingAnalysisRepo) ListAnalysisSummariesByUserID(context.Context, uuid.UUID, model.Pagination) ([]model.AnalysisSummary, int, error) {
	return nil, 0, errRepo
}

func (failingAnalysisRepo) CreateAnalysis(context.Context, model.Analysis) (model.Analysis, error) {
	return model.Analysis{}, errRepo
}

// failingAnalysisUpdateRepo is a memrepo whose analysis update fails.
type failingAnalysisUpdateRepo struct {
	*memrepo.Repo
}

func (failingAnalysisUpdateRepo) UpdateAnalysis(context.Context, model.AnalysisPartial) (model.Analysis, error) {
	return model.Analysis{}, errRepo
}

func TestTriggerAnalysisRejects(t *testing.T) {
	ctx := context.Background()
	userID := uuid.NewV7()
	completed := model.Video{ID: uuid.NewV7(), UserID: userID, ObjectKey: "k.mp4", Status: model.VideoStatusCompleted}
	pending := model.Video{ID: uuid.NewV7(), UserID: userID, ObjectKey: "p.mp4", Status: model.VideoStatusPending}

	tests := []struct {
		name    string
		userID  uuid.UUID
		config  model.AnalysisConfig
		wantErr error
	}{
		{"an unknown type", userID, model.AnalysisConfig{VideoID: completed.ID, Type: "4d", Visibility: model.VisibilityPrivate}, nil},
		{"an unknown visibility", userID, model.AnalysisConfig{VideoID: completed.ID, Type: model.AnalysisType2D, Visibility: "everyone"}, nil},
		{"an unknown video", userID, model.AnalysisConfig{VideoID: uuid.NewV7(), Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate}, model.ErrNotFound},
		{"the video of another user", uuid.NewV7(), model.AnalysisConfig{VideoID: completed.ID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate}, model.ErrNotFound},
		{"a video still uploading", userID, model.AnalysisConfig{VideoID: pending.ID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate}, model.ErrVideoUploading},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			repo := memrepo.New()
			repo.PutVideo(completed)
			repo.PutVideo(pending)
			queue := &recordingQueue{}
			s := NewAnalysisService(config.StorageConfig{}, repo, repo, queue)

			_, err := s.TriggerAnalysis(ctx, tt.userID, tt.config)
			if err == nil || (tt.wantErr != nil && !errors.Is(err, tt.wantErr)) {
				t.Fatalf("TriggerAnalysis() error = %v, want %v", err, tt.wantErr)
			}
			if len(queue.bodies) != 0 {
				t.Errorf("published %d jobs, want none", len(queue.bodies))
			}
		})
	}

	t.Run("forwards the creation error", func(t *testing.T) {
		repo := memrepo.New()
		repo.PutVideo(completed)
		queue := &recordingQueue{}
		s := NewAnalysisService(config.StorageConfig{}, failingAnalysisRepo{repo}, repo, queue)

		if _, err := s.TriggerAnalysis(ctx, userID, model.AnalysisConfig{VideoID: completed.ID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate}); !errors.Is(err, errRepo) {
			t.Errorf("TriggerAnalysis() error = %v, want %v", err, errRepo)
		}
		if len(queue.bodies) != 0 {
			t.Errorf("published %d jobs, want none", len(queue.bodies))
		}
	})
}

func TestTriggerAnalysisStoresAPendingAnalysis(t *testing.T) {
	repo := memrepo.New()
	s := NewAnalysisService(config.StorageConfig{}, repo, repo, &recordingQueue{})
	userID := uuid.NewV7()
	video := model.Video{ID: uuid.NewV7(), UserID: userID, ObjectKey: "k.mp4", Status: model.VideoStatusCompleted}
	repo.PutVideo(video)

	analysis, err := s.TriggerAnalysis(context.Background(), userID, model.AnalysisConfig{VideoID: video.ID, Type: model.AnalysisType3D, Visibility: model.VisibilityPublic})
	if err != nil {
		t.Fatalf("TriggerAnalysis() error = %v", err)
	}

	stored, err := s.GetAnalysisByID(context.Background(), analysis.ID)
	if err != nil {
		t.Fatalf("GetAnalysisByID() error = %v", err)
	}
	if stored.VideoID != video.ID || stored.Type != model.AnalysisType3D || stored.Visibility != model.VisibilityPublic || stored.Status != model.JobStatusPending {
		t.Errorf("stored = %+v, want a pending 3d public analysis of the video", stored)
	}
	if _, err := s.GetAnalysisByID(context.Background(), uuid.NewV7()); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("GetAnalysisByID(unknown) error = %v, want ErrNotFound", err)
	}
}

func TestListAnalysesPage(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewAnalysisService(config.StorageConfig{}, repo, repo, &recordingQueue{})
	userID := uuid.NewV7()
	for range 3 {
		video := model.Video{ID: uuid.NewV7(), UserID: userID, ObjectKey: "k.mp4", Status: model.VideoStatusCompleted}
		repo.PutVideo(video)
		if _, err := s.TriggerAnalysis(ctx, userID, model.AnalysisConfig{VideoID: video.ID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate}); err != nil {
			t.Fatalf("TriggerAnalysis() error = %v", err)
		}
	}

	pagination := model.Pagination{Limit: 2, Offset: 0}
	page, err := s.ListAnalyses(ctx, userID, pagination)
	if err != nil {
		t.Fatalf("ListAnalyses() error = %v", err)
	}
	if len(page.Analyses) != 2 || page.Total != 3 || page.Pagination != pagination {
		t.Errorf("page = (%d analyses, total %d, %+v), want (2, 3, %+v)", len(page.Analyses), page.Total, page.Pagination, pagination)
	}

	failing := NewAnalysisService(config.StorageConfig{}, failingAnalysisRepo{repo}, repo, &recordingQueue{})
	if _, err := failing.ListAnalyses(ctx, userID, pagination); !errors.Is(err, errRepo) {
		t.Errorf("ListAnalyses() error = %v, want %v", err, errRepo)
	}
}

func TestAnalysisStaleDetection(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewAnalysisService(config.StorageConfig{}, repo, repo, &recordingQueue{})
	video := model.Video{ID: uuid.NewV7(), UserID: uuid.NewV7(), Status: model.VideoStatusCompleted}
	repo.PutVideo(video)

	create := func(createdAt time.Time, status model.JobStatus) uuid.UUID {
		t.Helper()
		repo.SetNow(func() time.Time { return createdAt })
		analysis, err := repo.CreateAnalysis(ctx, model.Analysis{VideoID: video.ID, Type: model.AnalysisType2D})
		if err != nil {
			t.Fatalf("CreateAnalysis() error = %v", err)
		}
		if status != model.JobStatusPending {
			if _, err := repo.UpdateAnalysis(ctx, model.AnalysisPartial{ID: analysis.ID, Status: &status}); err != nil {
				t.Fatalf("UpdateAnalysis() error = %v", err)
			}
		}
		return analysis.ID
	}
	now := time.Now()
	stale := create(now.Add(-16*time.Minute), model.JobStatusPending)
	recent := create(now.Add(-time.Minute), model.JobStatusPending)
	oldRunning := create(now.Add(-time.Hour), model.JobStatusRunning)
	repo.SetNow(time.Now)

	if err := s.AnalysisStaleDetection(ctx); err != nil {
		t.Fatalf("AnalysisStaleDetection() error = %v", err)
	}

	want := map[uuid.UUID]model.JobStatus{stale: model.JobStatusFailed, recent: model.JobStatusPending, oldRunning: model.JobStatusRunning}
	for id, status := range want {
		analysis, err := s.GetAnalysisByID(ctx, id)
		if err != nil {
			t.Fatalf("GetAnalysisByID() error = %v", err)
		}
		if analysis.Status != status {
			t.Errorf("analysis %v status = %q, want %q", id, analysis.Status, status)
		}
	}
	failed, _ := s.GetAnalysisByID(ctx, stale)
	if failed.Error == nil || *failed.Error != "Job processing timed out" {
		t.Errorf("Error = %v, want the timeout message", failed.Error)
	}

	t.Run("forwards the listing error", func(t *testing.T) {
		failing := NewAnalysisService(config.StorageConfig{}, failingAnalysisRepo{repo}, repo, &recordingQueue{})
		if err := failing.AnalysisStaleDetection(ctx); !errors.Is(err, errRepo) {
			t.Errorf("AnalysisStaleDetection() error = %v, want %v", err, errRepo)
		}
	})

	t.Run("joins the update errors", func(t *testing.T) {
		create(now.Add(-20*time.Minute), model.JobStatusPending)
		create(now.Add(-30*time.Minute), model.JobStatusPending)
		repo.SetNow(time.Now)

		failing := NewAnalysisService(config.StorageConfig{}, failingAnalysisUpdateRepo{repo}, repo, &recordingQueue{})
		err := failing.AnalysisStaleDetection(ctx)
		if !errors.Is(err, errRepo) {
			t.Fatalf("AnalysisStaleDetection() error = %v, want %v", err, errRepo)
		}
		if joined, ok := err.(interface{ Unwrap() []error }); !ok || len(joined.Unwrap()) != 2 {
			t.Errorf("error = %v, want one error per stale analysis", err)
		}
	})
}

func TestRetryAdviceIsNotImplemented(t *testing.T) {
	s := NewAnalysisService(config.StorageConfig{}, memrepo.New(), memrepo.New(), &recordingQueue{})

	analysis, err := s.RetryAdvice(context.Background(), uuid.NewV7())
	if err != nil || analysis.ID != (uuid.UUID{}) {
		t.Errorf("RetryAdvice() = (%+v, %v), want the empty stub result", analysis, err)
	}
}
