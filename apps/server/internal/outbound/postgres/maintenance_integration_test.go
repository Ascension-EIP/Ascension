// @date 2026-11-14
// @file maintenance_integration_test.go
// @brief Integration tests of the queries behind the cron jobs and the video list: stale analyses, expired videos and old quota usage.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/pgtest"
)

func createAnalysis(t *testing.T, db pgtest.DB, videoID uuid.UUID) model.Analysis {
	t.Helper()

	analysis, err := db.Repo.CreateAnalysis(context.Background(), model.Analysis{
		VideoID: videoID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate,
	})
	if err != nil {
		t.Fatalf("CreateAnalysis() error = %v", err)
	}

	return analysis
}

func TestAnalysisRepositoryListUpdateDelete(t *testing.T) {
	ctx := context.Background()
	db := pgtest.Open(t)
	repo := db.Repo
	userID := db.CreateUser(t)

	pending := []model.Analysis{
		createAnalysis(t, db, db.CreateVideo(t, userID, nil)),
		createAnalysis(t, db, db.CreateVideo(t, userID, nil)),
	}
	running := createAnalysis(t, db, db.CreateVideo(t, userID, nil))
	if _, err := repo.UpdateAnalysis(ctx, model.AnalysisPartial{ID: running.ID, Status: new(model.JobStatusRunning)}); err != nil {
		t.Fatalf("UpdateAnalysis(running) error = %v", err)
	}

	listed, err := repo.ListAnalysisByFilter(ctx, model.AnalysisFilter{Status: new(model.JobStatusPending)}, model.Pagination{})
	if err != nil {
		t.Fatalf("ListAnalysisByFilter(pending) error = %v", err)
	}
	if len(listed) != len(pending) {
		t.Fatalf("ListAnalysisByFilter(pending) = %d analyses, want %d", len(listed), len(pending))
	}
	for _, analysis := range listed {
		if analysis.Status != model.JobStatusPending {
			t.Errorf("listed analysis %v has status %q, want pending", analysis.ID, analysis.Status)
		}
	}

	page, err := repo.ListAnalysisByFilter(ctx, model.AnalysisFilter{}, model.Pagination{Limit: 2, Offset: 1})
	if err != nil {
		t.Fatalf("ListAnalysisByFilter(limit 2, offset 1) error = %v", err)
	}
	if len(page) != 2 {
		t.Errorf("ListAnalysisByFilter(limit 2, offset 1) = %d analyses, want 2 of 3", len(page))
	}

	failed, err := repo.UpdateAnalysis(ctx, model.AnalysisPartial{
		ID: pending[0].ID, Status: new(model.JobStatusFailed), Error: new(new("Job processing timed out")),
	})
	if err != nil {
		t.Fatalf("UpdateAnalysis(failed) error = %v", err)
	}
	if failed.Status != model.JobStatusFailed || failed.Error == nil || *failed.Error != "Job processing timed out" {
		t.Errorf("UpdateAnalysis(failed) = status %q, error %v", failed.Status, failed.Error)
	}

	if _, err := repo.UpdateAnalysis(ctx, model.AnalysisPartial{ID: pending[1].ID}); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("UpdateAnalysis(no field) error = %v, want ErrNotFound", err)
	}
	if _, err := repo.UpdateAnalysis(ctx, model.AnalysisPartial{ID: uuid.NewV7(), Progress: new(int16(10))}); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("UpdateAnalysis(unknown) error = %v, want ErrNotFound", err)
	}

	if err := repo.DeleteAnalysis(ctx, pending[1].ID); err != nil {
		t.Fatalf("DeleteAnalysis() error = %v", err)
	}
	if _, err := repo.GetAnalysisByFilter(ctx, model.AnalysisFilter{ID: &pending[1].ID}); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("GetAnalysisByFilter(deleted) error = %v, want ErrNotFound", err)
	}
	if err := repo.DeleteAnalysis(ctx, uuid.NewV7()); err != nil {
		t.Errorf("DeleteAnalysis(unknown) error = %v, want nil", err)
	}
}

func TestAnalysisStaleDetectionOnPostgres(t *testing.T) {
	ctx := context.Background()
	db := pgtest.Open(t)
	repo := db.Repo
	userID := db.CreateUser(t)

	stale := createAnalysis(t, db, db.CreateVideo(t, userID, nil))
	recent := createAnalysis(t, db, db.CreateVideo(t, userID, nil))
	staleRunning := createAnalysis(t, db, db.CreateVideo(t, userID, nil))
	old := time.Now().Add(-20 * time.Minute)
	if _, err := repo.UpdateAnalysis(ctx, model.AnalysisPartial{ID: stale.ID, CreatedAt: &old}); err != nil {
		t.Fatalf("backdate stale analysis: %v", err)
	}
	if _, err := repo.UpdateAnalysis(ctx, model.AnalysisPartial{ID: staleRunning.ID, Status: new(model.JobStatusRunning), CreatedAt: &old}); err != nil {
		t.Fatalf("backdate running analysis: %v", err)
	}

	analysisS := service.NewAnalysisService(config.StorageConfig{}, repo, repo, nil)
	if err := analysisS.AnalysisStaleDetection(ctx); err != nil {
		t.Fatalf("AnalysisStaleDetection() error = %v", err)
	}

	want := map[uuid.UUID]model.JobStatus{
		stale.ID:        model.JobStatusFailed,
		recent.ID:       model.JobStatusPending,
		staleRunning.ID: model.JobStatusRunning,
	}
	for id, status := range want {
		got, err := repo.GetAnalysisByFilter(ctx, model.AnalysisFilter{ID: &id})
		if err != nil {
			t.Fatalf("GetAnalysisByFilter(%v) error = %v", id, err)
		}
		if got.Status != status {
			t.Errorf("analysis %v status = %q, want %q", id, got.Status, status)
		}
	}

	timedOut, err := repo.GetAnalysisByFilter(ctx, model.AnalysisFilter{ID: &stale.ID})
	if err != nil {
		t.Fatal(err)
	}
	if timedOut.Error == nil || *timedOut.Error != "Job processing timed out" {
		t.Errorf("stale analysis error = %v, want the timeout message", timedOut.Error)
	}
}

func TestListVideosByFilter(t *testing.T) {
	ctx := context.Background()
	db := pgtest.Open(t)
	repo := db.Repo
	userID, otherID := db.CreateUser(t), db.CreateUser(t)
	for range 3 {
		db.CreateVideo(t, userID, nil)
	}
	db.CreateVideo(t, otherID, nil)

	mine, err := repo.ListVideosByFilter(ctx, model.VideoFilter{UserID: &userID}, model.Pagination{})
	if err != nil {
		t.Fatalf("ListVideosByFilter(user) error = %v", err)
	}
	if len(mine) != 3 {
		t.Fatalf("ListVideosByFilter(user) = %d videos, want 3", len(mine))
	}
	for _, video := range mine {
		if video.UserID != userID {
			t.Errorf("video %v of user %v listed, want only %v", video.ID, video.UserID, userID)
		}
	}

	page, err := repo.ListVideosByFilter(ctx, model.VideoFilter{UserID: &userID}, model.Pagination{Limit: 2, Offset: 2})
	if err != nil {
		t.Fatalf("ListVideosByFilter(limit 2, offset 2) error = %v", err)
	}
	if len(page) != 1 {
		t.Errorf("ListVideosByFilter(limit 2, offset 2) = %d videos, want the last 1", len(page))
	}

	pending, err := repo.ListVideosByFilter(ctx, model.VideoFilter{UserID: &userID, Status: new(model.VideoStatusPending)}, model.Pagination{})
	if err != nil {
		t.Fatalf("ListVideosByFilter(pending) error = %v", err)
	}
	if len(pending) != 0 {
		t.Errorf("ListVideosByFilter(pending) = %d videos, want 0", len(pending))
	}
}

// insertVideo inserts a video with the given status, upload deadline, retention flag and age.
func insertVideo(t *testing.T, db pgtest.DB, userID uuid.UUID, status model.VideoStatus, uploadExpiresAt *time.Time, retained bool, createdAt time.Time) uuid.UUID {
	t.Helper()

	var id uuid.UUID
	if err := db.Repo.Pool.QueryRow(context.Background(),
		"INSERT INTO videos (user_id, object_key, status, content_type, upload_url_expires_at, retained, created_at) VALUES ($1, $2, $3, 'video/mp4', $4, $5, $6) RETURNING id",
		userID, userID.String()+"/"+uuid.NewV7().String()+".mp4", status, uploadExpiresAt, retained, createdAt,
	).Scan(&id); err != nil {
		t.Fatalf("insert video: %v", err)
	}

	return id
}

func videoExists(t *testing.T, db pgtest.DB, id uuid.UUID) bool {
	t.Helper()

	var exists bool
	if err := db.Repo.Pool.QueryRow(context.Background(), "SELECT EXISTS (SELECT 1 FROM videos WHERE id = $1)", id).Scan(&exists); err != nil {
		t.Fatal(err)
	}

	return exists
}

func TestDeleteVideosUploadExpired(t *testing.T) {
	db := pgtest.Open(t)
	userID := db.CreateUser(t)
	now := time.Now()
	past, future := now.Add(-time.Hour), now.Add(time.Hour)

	expired := insertVideo(t, db, userID, model.VideoStatusPending, &past, false, now)
	stillOpen := insertVideo(t, db, userID, model.VideoStatusPending, &future, false, now)
	completed := insertVideo(t, db, userID, model.VideoStatusCompleted, &past, false, now)

	if err := db.Repo.DeleteVideosUploadExpired(context.Background()); err != nil {
		t.Fatalf("DeleteVideosUploadExpired() error = %v", err)
	}

	for id, want := range map[uuid.UUID]bool{expired: false, stillOpen: true, completed: true} {
		if got := videoExists(t, db, id); got != want {
			t.Errorf("video %v exists = %v, want %v", id, got, want)
		}
	}
}

func TestDeleteVideosExpired(t *testing.T) {
	db := pgtest.Open(t)
	userID := db.CreateUser(t)
	now := time.Now()
	old := now.Add(-2 * time.Hour)

	expired := insertVideo(t, db, userID, model.VideoStatusCompleted, nil, false, old)
	retained := insertVideo(t, db, userID, model.VideoStatusCompleted, nil, true, old)
	recent := insertVideo(t, db, userID, model.VideoStatusCompleted, nil, false, now)
	pending := insertVideo(t, db, userID, model.VideoStatusPending, nil, false, old)

	if err := db.Repo.DeleteVideosExpired(context.Background(), time.Hour); err != nil {
		t.Fatalf("DeleteVideosExpired() error = %v", err)
	}

	for id, want := range map[uuid.UUID]bool{expired: false, retained: true, recent: true, pending: true} {
		if got := videoExists(t, db, id); got != want {
			t.Errorf("video %v exists = %v, want %v", id, got, want)
		}
	}
}

func TestDeleteOldQuotaUsage(t *testing.T) {
	ctx := context.Background()
	db := pgtest.Open(t)
	userID := db.CreateUser(t)

	// Months relative to the current one: the query keeps the last 24 months and the current one.
	months := map[int]bool{-25: false, -24: true, -1: true, 0: true}
	for offset := range months {
		if _, err := db.Repo.Pool.Exec(ctx,
			"INSERT INTO quota_usages (user_id, period_start) VALUES ($1, (DATE_TRUNC('month', NOW()) + make_interval(months => $2))::DATE)",
			userID, offset,
		); err != nil {
			t.Fatalf("insert quota usage %d: %v", offset, err)
		}
	}

	if err := db.Repo.DeleteOldQuotaUsage(ctx); err != nil {
		t.Fatalf("DeleteOldQuotaUsage() error = %v", err)
	}

	for offset, want := range months {
		var exists bool
		if err := db.Repo.Pool.QueryRow(ctx,
			"SELECT EXISTS (SELECT 1 FROM quota_usages WHERE user_id = $1 AND period_start = (DATE_TRUNC('month', NOW()) + make_interval(months => $2))::DATE)",
			userID, offset,
		).Scan(&exists); err != nil {
			t.Fatal(err)
		}
		if exists != want {
			t.Errorf("quota usage of month %+d exists = %v, want %v", offset, exists, want)
		}
	}
}
