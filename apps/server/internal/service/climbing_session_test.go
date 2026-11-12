// @date 2026-11-12
// @file climbing_session_test.go
// @brief Unit tests of the climbing session service and of the session link held by videos.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"errors"
	"net/url"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

var testNow = time.Date(2026, 11, 12, 18, 0, 0, 0, time.UTC)

func newTestClimbingSessionService(repo *memrepo.Repo) ClimbingSessionService {
	s := NewClimbingSessionService(repo, repo, repo)
	s.now = func() time.Time { return testNow }
	return s
}

func TestStartClimbingSession(t *testing.T) {
	ctx := context.Background()
	s := newTestClimbingSessionService(memrepo.New())
	userID := uuid.NewV7()

	t.Run("starts now by default", func(t *testing.T) {
		session, err := s.StartClimbingSession(ctx, userID, model.ClimbingSessionConfig{Title: new("Bloc"), Visibility: model.VisibilityPrivate})
		if err != nil {
			t.Fatalf("StartClimbingSession() error = %v", err)
		}
		if !session.StartedAt.Equal(testNow) {
			t.Errorf("StartedAt = %v, want %v", session.StartedAt, testNow)
		}
		if session.UserID != userID {
			t.Errorf("UserID = %v, want %v", session.UserID, userID)
		}
		if session.EndedAt != nil {
			t.Errorf("EndedAt = %v, want nil", session.EndedAt)
		}
	})

	t.Run("keeps the given start time", func(t *testing.T) {
		startedAt := testNow.Add(-3 * time.Hour)
		session, err := s.StartClimbingSession(ctx, userID, model.ClimbingSessionConfig{StartedAt: &startedAt, Visibility: model.VisibilityFriends})
		if err != nil {
			t.Fatalf("StartClimbingSession() error = %v", err)
		}
		if !session.StartedAt.Equal(startedAt) {
			t.Errorf("StartedAt = %v, want %v", session.StartedAt, startedAt)
		}
	})

	t.Run("rejects an invalid config", func(t *testing.T) {
		_, err := s.StartClimbingSession(ctx, userID, model.ClimbingSessionConfig{Visibility: "everyone"})
		if !errors.Is(err, model.ErrInvalidInput) {
			t.Fatalf("StartClimbingSession() error = %v, want ErrInvalidInput", err)
		}
	})
}

func TestListClimbingSessions(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := newTestClimbingSessionService(repo)
	userID, otherID := uuid.NewV7(), uuid.NewV7()

	for i := range 5 {
		startedAt := testNow.Add(time.Duration(i) * time.Hour)
		mustStart(t, s, userID, model.ClimbingSessionConfig{StartedAt: &startedAt, Visibility: model.VisibilityPrivate})
	}
	mustStart(t, s, otherID, model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})

	page, err := s.ListClimbingSessions(ctx, userID, model.Pagination{Limit: 2, Offset: 1})
	if err != nil {
		t.Fatalf("ListClimbingSessions() error = %v", err)
	}
	if page.Total != 5 {
		t.Errorf("Total = %d, want 5 (sessions of other users excluded)", page.Total)
	}
	if len(page.Sessions) != 2 {
		t.Fatalf("len(Sessions) = %d, want 2", len(page.Sessions))
	}
	if want := testNow.Add(3 * time.Hour); !page.Sessions[0].StartedAt.Equal(want) {
		t.Errorf("first session started at %v, want %v (most recent first, offset 1)", page.Sessions[0].StartedAt, want)
	}
	if page.Pagination != (model.Pagination{Limit: 2, Offset: 1}) {
		t.Errorf("Pagination = %+v, want the requested one", page.Pagination)
	}

	empty, err := s.ListClimbingSessions(ctx, userID, model.Pagination{Limit: 10, Offset: 50})
	if err != nil {
		t.Fatalf("ListClimbingSessions() past the end error = %v", err)
	}
	if len(empty.Sessions) != 0 || empty.Total != 5 {
		t.Errorf("past the end: %d sessions, total %d; want 0 and 5", len(empty.Sessions), empty.Total)
	}
}

func TestGetClimbingSessionDetails(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := newTestClimbingSessionService(repo)
	userID, otherID := uuid.NewV7(), uuid.NewV7()

	session := mustStart(t, s, userID, model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})
	other := mustStart(t, s, userID, model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})

	linked := mustCreateAnalysis(t, repo, userID, &session.ID)
	mustCreateAnalysis(t, repo, userID, &other.ID)
	mustCreateAnalysis(t, repo, userID, nil)

	details, err := s.GetClimbingSessionDetails(ctx, session.ID, userID)
	if err != nil {
		t.Fatalf("GetClimbingSessionDetails() error = %v", err)
	}
	if details.Session.ID != session.ID {
		t.Errorf("Session.ID = %v, want %v", details.Session.ID, session.ID)
	}
	if len(details.Analyses) != 1 || details.Analyses[0].ID != linked.ID || *details.Analyses[0].ClimbingSessionID != session.ID {
		t.Errorf("Analyses = %+v, want only analysis %v", details.Analyses, linked.ID)
	}

	if _, err := s.GetClimbingSessionDetails(ctx, session.ID, otherID); !errors.Is(err, model.ErrClimbingSessionNotFound) {
		t.Errorf("another user's session: error = %v, want ErrClimbingSessionNotFound", err)
	}
	if _, err := s.GetClimbingSessionDetails(ctx, uuid.NewV7(), userID); !errors.Is(err, model.ErrClimbingSessionNotFound) {
		t.Errorf("unknown session: error = %v, want ErrClimbingSessionNotFound", err)
	}
}

func TestUpdateClimbingSession(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := newTestClimbingSessionService(repo)
	userID, otherID := uuid.NewV7(), uuid.NewV7()
	session := mustStart(t, s, userID, model.ClimbingSessionConfig{Title: new("Bloc"), Notes: new("Warm up"), Visibility: model.VisibilityPrivate})

	t.Run("ends and renames the session", func(t *testing.T) {
		endedAt := testNow.Add(2 * time.Hour)
		updated, err := s.UpdateClimbingSession(ctx, model.ClimbingSessionPartial{
			ID: session.ID, UserID: userID,
			Title:   new(new("Evening bloc")),
			EndedAt: new(&endedAt),
		})
		if err != nil {
			t.Fatalf("UpdateClimbingSession() error = %v", err)
		}
		if updated.Title == nil || *updated.Title != "Evening bloc" {
			t.Errorf("Title = %v, want Evening bloc", updated.Title)
		}
		if updated.EndedAt == nil || !updated.EndedAt.Equal(endedAt) {
			t.Errorf("EndedAt = %v, want %v", updated.EndedAt, endedAt)
		}
		if updated.Notes == nil || *updated.Notes != "Warm up" {
			t.Errorf("Notes = %v, want them unchanged", updated.Notes)
		}
	})

	t.Run("reopens and clears the notes", func(t *testing.T) {
		updated, err := s.UpdateClimbingSession(ctx, model.ClimbingSessionPartial{
			ID: session.ID, UserID: userID,
			Notes:   new((*string)(nil)),
			EndedAt: new((*time.Time)(nil)),
		})
		if err != nil {
			t.Fatalf("UpdateClimbingSession() error = %v", err)
		}
		if updated.EndedAt != nil || updated.Notes != nil {
			t.Errorf("EndedAt = %v, Notes = %v; want both nil", updated.EndedAt, updated.Notes)
		}
	})

	t.Run("empty update returns the session", func(t *testing.T) {
		got, err := s.UpdateClimbingSession(ctx, model.ClimbingSessionPartial{ID: session.ID, UserID: userID})
		if err != nil {
			t.Fatalf("UpdateClimbingSession() error = %v", err)
		}
		if got.ID != session.ID {
			t.Errorf("ID = %v, want %v", got.ID, session.ID)
		}
	})

	t.Run("rejects an end before the start", func(t *testing.T) {
		_, err := s.UpdateClimbingSession(ctx, model.ClimbingSessionPartial{
			ID: session.ID, UserID: userID,
			EndedAt: new(new(testNow.Add(-time.Hour))),
		})
		if !errors.Is(err, model.ErrInvalidInput) {
			t.Fatalf("UpdateClimbingSession() error = %v, want ErrInvalidInput", err)
		}
	})

	t.Run("another user's session is not found", func(t *testing.T) {
		_, err := s.UpdateClimbingSession(ctx, model.ClimbingSessionPartial{ID: session.ID, UserID: otherID, Title: new(new("Mine"))})
		if !errors.Is(err, model.ErrClimbingSessionNotFound) {
			t.Fatalf("UpdateClimbingSession() error = %v, want ErrClimbingSessionNotFound", err)
		}
	})
}

func TestDeleteClimbingSession(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := newTestClimbingSessionService(repo)
	userID, otherID := uuid.NewV7(), uuid.NewV7()
	session := mustStart(t, s, userID, model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})
	analysis := mustCreateAnalysis(t, repo, userID, &session.ID)

	if err := s.DeleteClimbingSession(ctx, session.ID, otherID); !errors.Is(err, model.ErrClimbingSessionNotFound) {
		t.Fatalf("delete by another user: error = %v, want ErrClimbingSessionNotFound", err)
	}

	if err := s.DeleteClimbingSession(ctx, session.ID, userID); err != nil {
		t.Fatalf("DeleteClimbingSession() error = %v", err)
	}

	if _, err := s.GetClimbingSessionDetails(ctx, session.ID, userID); !errors.Is(err, model.ErrClimbingSessionNotFound) {
		t.Errorf("deleted session: error = %v, want ErrClimbingSessionNotFound", err)
	}
	if video, ok := repo.Video(analysis.VideoID); !ok || video.ClimbingSessionID != nil {
		t.Errorf("video after delete = %+v (found %v), want it kept and unlinked", video, ok)
	}

	if err := s.DeleteClimbingSession(ctx, session.ID, userID); !errors.Is(err, model.ErrClimbingSessionNotFound) {
		t.Errorf("second delete: error = %v, want ErrClimbingSessionNotFound", err)
	}
}

func TestGetUploadURLChecksClimbingSessionOwner(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	sessionS := newTestClimbingSessionService(repo)
	videoS := NewVideoService(config.VideoConfig{}, config.MinIOConfig{UploadExp: time.Hour}, fakeStorage{}, repo, repo)
	userID, otherID := uuid.NewV7(), uuid.NewV7()
	session := mustStart(t, sessionS, userID, model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})
	metadata, err := model.NewVideoMetadata("video/mp4", 1024)
	if err != nil {
		t.Fatalf("NewVideoMetadata() error = %v", err)
	}

	if _, err := videoS.GetUploadURL(ctx, otherID, metadata, model.VideoConfig{ClimbingSessionID: &session.ID, Visibility: model.VisibilityPrivate}); !errors.Is(err, model.ErrInvalidInput) {
		t.Fatalf("another user's session: error = %v, want ErrInvalidInput", err)
	}
	if len(repo.Videos()) != 0 {
		t.Fatalf("a video was created for another user's session")
	}

	upload, err := videoS.GetUploadURL(ctx, userID, metadata, model.VideoConfig{ClimbingSessionID: &session.ID, Visibility: model.VisibilityPrivate})
	if err != nil {
		t.Fatalf("GetUploadURL() error = %v", err)
	}
	videos := repo.Videos()
	if len(videos) != 1 || videos[0].ID != upload.VideoID || videos[0].ClimbingSessionID == nil || *videos[0].ClimbingSessionID != session.ID {
		t.Errorf("videos = %+v, want one video linked to session %v", videos, session.ID)
	}
}

func TestTriggeredAnalysisJoinsTheSessionOfItsVideo(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	sessionS := newTestClimbingSessionService(repo)
	analysisS := NewAnalysisService(config.MinIOConfig{BucketName: "videos"}, repo, repo, fakeQueue{})
	userID := uuid.NewV7()
	session := mustStart(t, sessionS, userID, model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})

	video := model.Video{ID: uuid.NewV7(), UserID: userID, ClimbingSessionID: &session.ID, ObjectKey: "k.mp4", Status: model.VideoStatusCompleted}
	repo.PutVideo(video)

	analysis, err := analysisS.TriggerAnalysis(ctx, userID, model.AnalysisConfig{VideoID: video.ID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate})
	if err != nil {
		t.Fatalf("TriggerAnalysis() error = %v", err)
	}

	details, err := sessionS.GetClimbingSessionDetails(ctx, session.ID, userID)
	if err != nil {
		t.Fatalf("GetClimbingSessionDetails() error = %v", err)
	}
	if len(details.Analyses) != 1 || details.Analyses[0].ID != analysis.ID {
		t.Errorf("session analyses = %+v, want the new analysis", details.Analyses)
	}
}

func TestGetActiveClimbingSession(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := newTestClimbingSessionService(repo)
	userID := uuid.NewV7()

	if _, err := s.GetActiveClimbingSession(ctx, userID); !errors.Is(err, model.ErrClimbingSessionNotFound) {
		t.Fatalf("no session: error = %v, want ErrClimbingSessionNotFound", err)
	}

	older := testNow.Add(-48 * time.Hour)
	ended := mustStart(t, s, userID, model.ClimbingSessionConfig{StartedAt: &older, Visibility: model.VisibilityPrivate})
	if _, err := s.UpdateClimbingSession(ctx, model.ClimbingSessionPartial{ID: ended.ID, UserID: userID, EndedAt: new(new(older.Add(time.Hour)))}); err != nil {
		t.Fatalf("end the old session: %v", err)
	}
	if _, err := s.GetActiveClimbingSession(ctx, userID); !errors.Is(err, model.ErrClimbingSessionNotFound) {
		t.Fatalf("only ended sessions: error = %v, want ErrClimbingSessionNotFound", err)
	}

	yesterday := testNow.Add(-24 * time.Hour)
	mustStart(t, s, userID, model.ClimbingSessionConfig{StartedAt: &yesterday, Visibility: model.VisibilityPrivate})
	current := mustStart(t, s, userID, model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})
	analysis := mustCreateAnalysis(t, repo, userID, &current.ID)
	mustStart(t, s, uuid.NewV7(), model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})

	active, err := s.GetActiveClimbingSession(ctx, userID)
	if err != nil {
		t.Fatalf("GetActiveClimbingSession() error = %v", err)
	}
	if active.Session.ID != current.ID {
		t.Errorf("active session = %v, want the most recently started open one %v", active.Session.ID, current.ID)
	}
	if len(active.Analyses) != 1 || active.Analyses[0].ID != analysis.ID {
		t.Errorf("active analyses = %+v, want analysis %v", active.Analyses, analysis.ID)
	}
}

func TestAddAnalysisToClimbingSession(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := newTestClimbingSessionService(repo)
	userID, otherID := uuid.NewV7(), uuid.NewV7()
	session := mustStart(t, s, userID, model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})
	second := mustStart(t, s, userID, model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})
	othersSession := mustStart(t, s, otherID, model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})
	standalone := mustCreateAnalysis(t, repo, userID, nil)
	othersAnalysis := mustCreateAnalysis(t, repo, otherID, nil)

	if err := s.AddAnalysisToClimbingSession(ctx, session.ID, standalone.ID, userID); err != nil {
		t.Fatalf("AddAnalysisToClimbingSession() error = %v", err)
	}
	assertVideoSession(t, repo, standalone.VideoID, &session.ID)

	if err := s.AddAnalysisToClimbingSession(ctx, session.ID, standalone.ID, userID); err != nil {
		t.Fatalf("adding the same analysis again: error = %v, want nil", err)
	}

	if err := s.AddAnalysisToClimbingSession(ctx, second.ID, standalone.ID, userID); err != nil {
		t.Fatalf("moving the analysis to another session: error = %v", err)
	}
	assertVideoSession(t, repo, standalone.VideoID, &second.ID)

	tests := []struct {
		name       string
		sessionID  uuid.UUID
		analysisID uuid.UUID
		want       error
	}{
		{"another user's session", othersSession.ID, standalone.ID, model.ErrClimbingSessionNotFound},
		{"unknown session", uuid.NewV7(), standalone.ID, model.ErrClimbingSessionNotFound},
		{"another user's analysis", session.ID, othersAnalysis.ID, model.ErrAnalysisNotFound},
		{"unknown analysis", session.ID, uuid.NewV7(), model.ErrAnalysisNotFound},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := s.AddAnalysisToClimbingSession(ctx, tt.sessionID, tt.analysisID, userID); !errors.Is(err, tt.want) {
				t.Fatalf("error = %v, want %v", err, tt.want)
			}
		})
	}
	assertVideoSession(t, repo, standalone.VideoID, &second.ID)
	assertVideoSession(t, repo, othersAnalysis.VideoID, nil)
}

func TestListAnalyses(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	sessionS := newTestClimbingSessionService(repo)
	analysisS := NewAnalysisService(config.MinIOConfig{}, repo, repo, fakeQueue{})
	userID := uuid.NewV7()
	session := mustStart(t, sessionS, userID, model.ClimbingSessionConfig{Visibility: model.VisibilityPrivate})

	inSession := mustCreateAnalysis(t, repo, userID, &session.ID)
	standalone := mustCreateAnalysis(t, repo, userID, nil)
	mustCreateAnalysis(t, repo, uuid.NewV7(), nil)

	page, err := analysisS.ListAnalyses(ctx, userID, model.Pagination{Limit: 10})
	if err != nil {
		t.Fatalf("ListAnalyses() error = %v", err)
	}
	if page.Total != 2 || len(page.Analyses) != 2 {
		t.Fatalf("page = %+v, want the 2 analyses of the user", page)
	}
	sessions := map[uuid.UUID]*uuid.UUID{}
	for _, analysis := range page.Analyses {
		sessions[analysis.ID] = analysis.ClimbingSessionID
	}
	if got := sessions[inSession.ID]; got == nil || *got != session.ID {
		t.Errorf("analysis in session: ClimbingSessionID = %v, want %v", got, session.ID)
	}
	if got, ok := sessions[standalone.ID]; !ok || got != nil {
		t.Errorf("standalone analysis: ClimbingSessionID = %v (listed %v), want nil", got, ok)
	}

	page, err = analysisS.ListAnalyses(ctx, userID, model.Pagination{Limit: 1, Offset: 1})
	if err != nil || page.Total != 2 || len(page.Analyses) != 1 {
		t.Fatalf("second page = %+v, %v; want 1 of 2", page, err)
	}
}

func mustStart(t *testing.T, s ClimbingSessionService, userID uuid.UUID, config model.ClimbingSessionConfig) model.ClimbingSession {
	t.Helper()

	session, err := s.StartClimbingSession(context.Background(), userID, config)
	if err != nil {
		t.Fatalf("StartClimbingSession() error = %v", err)
	}

	return session
}

// mustCreateAnalysis stores a completed video of the user, optionally in a session, and an analysis of it.
func mustCreateAnalysis(t *testing.T, repo *memrepo.Repo, userID uuid.UUID, climbingSessionID *uuid.UUID) model.Analysis {
	t.Helper()

	video := model.Video{ID: uuid.NewV7(), UserID: userID, ClimbingSessionID: climbingSessionID, ObjectKey: uuid.NewV7().String() + ".mp4", Status: model.VideoStatusCompleted}
	repo.PutVideo(video)

	analysis, err := repo.CreateAnalysis(context.Background(), model.Analysis{VideoID: video.ID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate})
	if err != nil {
		t.Fatalf("CreateAnalysis() error = %v", err)
	}

	return analysis
}

func assertVideoSession(t *testing.T, repo *memrepo.Repo, videoID uuid.UUID, want *uuid.UUID) {
	t.Helper()

	video, ok := repo.Video(videoID)
	if !ok {
		t.Fatalf("video %v not found", videoID)
	}
	switch {
	case want == nil && video.ClimbingSessionID != nil:
		t.Errorf("video %v is in session %v, want none", videoID, *video.ClimbingSessionID)
	case want != nil && (video.ClimbingSessionID == nil || *video.ClimbingSessionID != *want):
		t.Errorf("video %v session = %v, want %v", videoID, video.ClimbingSessionID, *want)
	}
}

type fakeStorage struct{}

func (fakeStorage) PresignedUploadURL(_ context.Context, key string) (*url.URL, time.Time, error) {
	return &url.URL{Scheme: "https", Host: "storage.test", Path: "/" + key}, testNow.Add(time.Hour), nil
}

func (fakeStorage) PresignedDownloadURL(_ context.Context, key string) (*url.URL, time.Time, error) {
	return &url.URL{Scheme: "https", Host: "storage.test", Path: "/" + key}, testNow.Add(time.Hour), nil
}

func (fakeStorage) FileExist(context.Context, string) error { return nil }

func (fakeStorage) Delete(context.Context, string) error { return nil }

type fakeQueue struct{}

func (fakeQueue) PublishJSONIntoQueueAI(context.Context, []byte) error { return nil }
