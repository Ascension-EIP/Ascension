// @date 2026-11-12
// @file climbing_session_integration_test.go
// @brief PostgreSQL integration tests of the climbing session repository, the video link and its migration.
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
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/pgtest"
	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/source/file"
)

func TestClimbingSessionRepositoryCRUD(t *testing.T) {
	ctx := context.Background()
	db := pgtest.Open(t)
	repo := db.Repo
	userID, otherID := db.CreateUser(t), db.CreateUser(t)
	startedAt := time.Date(2026, 11, 12, 18, 0, 0, 0, time.UTC)

	created, err := repo.CreateClimbingSession(ctx, model.ClimbingSession{
		UserID: userID, Title: new("Arkose Nation"), Notes: new("Slab"), StartedAt: startedAt, Visibility: model.VisibilityFriends,
	})
	if err != nil {
		t.Fatalf("CreateClimbingSession() error = %v", err)
	}
	if created.ID == (uuid.UUID{}) || !created.StartedAt.Equal(startedAt) || created.Visibility != model.VisibilityFriends || created.EndedAt != nil || created.CreatedAt.IsZero() {
		t.Fatalf("created = %+v", created)
	}

	got, err := repo.GetClimbingSessionByFilter(ctx, model.ClimbingSessionFilter{ID: &created.ID, UserID: &userID})
	if err != nil || got.ID != created.ID || got.Title == nil || *got.Title != "Arkose Nation" {
		t.Fatalf("GetClimbingSessionByFilter() = %+v, %v", got, err)
	}
	if _, err := repo.GetClimbingSessionByFilter(ctx, model.ClimbingSessionFilter{ID: &created.ID, UserID: &otherID}); !errors.Is(err, model.ErrNotFound) {
		t.Fatalf("another user's session: error = %v, want ErrNotFound", err)
	}

	endedAt := startedAt.Add(2 * time.Hour)
	updated, err := repo.UpdateClimbingSession(ctx, model.ClimbingSessionPartial{
		ID: created.ID, UserID: userID, Title: new(new("Evening bloc")), Notes: new((*string)(nil)), EndedAt: new(&endedAt),
	})
	if err != nil {
		t.Fatalf("UpdateClimbingSession() error = %v", err)
	}
	if updated.Title == nil || *updated.Title != "Evening bloc" || updated.Notes != nil || updated.EndedAt == nil || !updated.EndedAt.Equal(endedAt) {
		t.Fatalf("updated = %+v", updated)
	}
	if !updated.UpdatedAt.After(created.UpdatedAt) {
		t.Errorf("UpdatedAt = %v, want it moved by the trigger (was %v)", updated.UpdatedAt, created.UpdatedAt)
	}

	if _, err := repo.UpdateClimbingSession(ctx, model.ClimbingSessionPartial{ID: created.ID, UserID: otherID, Title: new(new("Stolen"))}); !errors.Is(err, model.ErrNotFound) {
		t.Fatalf("update by another user: error = %v, want ErrNotFound", err)
	}
	if _, err := repo.UpdateClimbingSession(ctx, model.ClimbingSessionPartial{ID: created.ID, UserID: userID, EndedAt: new(new(startedAt.Add(-time.Hour)))}); !errors.Is(err, model.ErrInvalidInput) {
		t.Fatalf("end before start: error = %v, want ErrInvalidInput (chk_climbing_sessions_dates)", err)
	}

	if err := repo.DeleteClimbingSession(ctx, created.ID, otherID); !errors.Is(err, model.ErrNotFound) {
		t.Fatalf("delete by another user: error = %v, want ErrNotFound", err)
	}
	if err := repo.DeleteClimbingSession(ctx, created.ID, userID); err != nil {
		t.Fatalf("DeleteClimbingSession() error = %v", err)
	}
	if err := repo.DeleteClimbingSession(ctx, created.ID, userID); !errors.Is(err, model.ErrNotFound) {
		t.Fatalf("second delete: error = %v, want ErrNotFound", err)
	}
}

func TestClimbingSessionRepositoryUnknownGym(t *testing.T) {
	db := pgtest.Open(t)

	_, err := db.Repo.CreateClimbingSession(context.Background(), model.ClimbingSession{
		UserID: db.CreateUser(t), GymID: new(uuid.NewV7()), StartedAt: time.Now(), Visibility: model.VisibilityPrivate,
	})
	if !errors.Is(err, model.ErrInvalidInput) {
		t.Fatalf("unknown gym: error = %v, want ErrInvalidInput", err)
	}
}

func TestListClimbingSessionsByUserID(t *testing.T) {
	ctx := context.Background()
	db := pgtest.Open(t)
	repo := db.Repo
	userID, otherID := db.CreateUser(t), db.CreateUser(t)
	base := time.Date(2026, 11, 1, 18, 0, 0, 0, time.UTC)

	for i := range 5 {
		if _, err := repo.CreateClimbingSession(ctx, model.ClimbingSession{UserID: userID, StartedAt: base.AddDate(0, 0, i), Visibility: model.VisibilityPrivate}); err != nil {
			t.Fatalf("CreateClimbingSession() error = %v", err)
		}
	}
	if _, err := repo.CreateClimbingSession(ctx, model.ClimbingSession{UserID: otherID, StartedAt: base, Visibility: model.VisibilityPrivate}); err != nil {
		t.Fatalf("CreateClimbingSession() error = %v", err)
	}

	sessions, total, err := repo.ListClimbingSessionsByUserID(ctx, userID, model.Pagination{Limit: 2, Offset: 1})
	if err != nil {
		t.Fatalf("ListClimbingSessionsByUserID() error = %v", err)
	}
	if total != 5 || len(sessions) != 2 {
		t.Fatalf("total = %d, len = %d; want 5 and 2", total, len(sessions))
	}
	if !sessions[0].StartedAt.Equal(base.AddDate(0, 0, 3)) || !sessions[1].StartedAt.Equal(base.AddDate(0, 0, 2)) {
		t.Errorf("page = [%v, %v], want the 4th and 3rd days (most recent first)", sessions[0].StartedAt, sessions[1].StartedAt)
	}

	sessions, total, err = repo.ListClimbingSessionsByUserID(ctx, uuid.NewV7(), model.Pagination{Limit: 20})
	if err != nil || total != 0 || sessions == nil || len(sessions) != 0 {
		t.Fatalf("user without sessions = %v, %d, %v; want an empty list", sessions, total, err)
	}
}

func TestGetActiveClimbingSessionByUserID(t *testing.T) {
	ctx := context.Background()
	db := pgtest.Open(t)
	repo := db.Repo
	userID := db.CreateUser(t)
	base := time.Date(2026, 11, 10, 18, 0, 0, 0, time.UTC)

	if _, err := repo.GetActiveClimbingSessionByUserID(ctx, userID); !errors.Is(err, model.ErrNotFound) {
		t.Fatalf("no session: error = %v, want ErrNotFound", err)
	}

	create := func(startedAt time.Time, endedAt *time.Time) model.ClimbingSession {
		t.Helper()
		session, err := repo.CreateClimbingSession(ctx, model.ClimbingSession{UserID: userID, StartedAt: startedAt, Visibility: model.VisibilityPrivate})
		if err != nil {
			t.Fatalf("CreateClimbingSession() error = %v", err)
		}
		if endedAt != nil {
			if session, err = repo.UpdateClimbingSession(ctx, model.ClimbingSessionPartial{ID: session.ID, UserID: userID, EndedAt: &endedAt}); err != nil {
				t.Fatalf("UpdateClimbingSession() error = %v", err)
			}
		}
		return session
	}

	create(base, nil)
	open := create(base.AddDate(0, 0, 1), nil)
	create(base.AddDate(0, 0, 2), new(base.AddDate(0, 0, 2).Add(time.Hour)))

	active, err := repo.GetActiveClimbingSessionByUserID(ctx, userID)
	if err != nil {
		t.Fatalf("GetActiveClimbingSessionByUserID() error = %v", err)
	}
	if active.ID != open.ID {
		t.Errorf("active = %v (started %v), want the most recent open session %v", active.ID, active.StartedAt, open.ID)
	}
}

func TestClimbingSessionForeignKeys(t *testing.T) {
	ctx := context.Background()
	db := pgtest.Open(t)
	repo := db.Repo
	userID, otherID := db.CreateUser(t), db.CreateUser(t)

	session, err := repo.CreateClimbingSession(ctx, model.ClimbingSession{UserID: userID, StartedAt: time.Now(), Visibility: model.VisibilityPrivate})
	if err != nil {
		t.Fatalf("CreateClimbingSession() error = %v", err)
	}

	// videos.climbing_session_id now references climbing_sessions, not users.
	err = repo.CreateVideo(ctx, model.Video{
		ID: uuid.NewV7(), UserID: userID, ObjectKey: "fk-user-id.mp4", ClimbingSessionID: &userID,
		Status: model.VideoStatusPending, Visibility: model.VisibilityPrivate, ContentType: "video/mp4",
	})
	if err == nil {
		t.Fatal("CreateVideo() with a user ID as climbing session: error = nil, want a foreign key violation")
	}

	videoID := db.CreateVideo(t, userID, &session.ID)
	analysis, err := repo.CreateAnalysis(ctx, model.Analysis{VideoID: videoID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate})
	if err != nil {
		t.Fatalf("CreateAnalysis() error = %v", err)
	}

	// SELECT * on analyses must scan every column, hints included.
	if _, err := repo.GetAnalysisByFilter(ctx, model.AnalysisFilter{ID: &analysis.ID}); err != nil {
		t.Fatalf("GetAnalysisByFilter() error = %v", err)
	}

	standaloneVideo := db.CreateVideo(t, userID, nil)
	standalone, err := repo.CreateAnalysis(ctx, model.Analysis{VideoID: standaloneVideo, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate})
	if err != nil {
		t.Fatalf("CreateAnalysis() standalone error = %v", err)
	}
	if _, err := repo.CreateAnalysis(ctx, model.Analysis{VideoID: db.CreateVideo(t, otherID, nil), Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate}); err != nil {
		t.Fatalf("CreateAnalysis() for another user error = %v", err)
	}

	summaries, err := repo.ListAnalysisSummariesByClimbingSessionID(ctx, session.ID)
	if err != nil {
		t.Fatalf("ListAnalysisSummariesByClimbingSessionID() error = %v", err)
	}
	if len(summaries) != 1 || summaries[0].ID != analysis.ID || summaries[0].VideoID != videoID || summaries[0].Status != model.JobStatus("pending") ||
		summaries[0].ClimbingSessionID == nil || *summaries[0].ClimbingSessionID != session.ID {
		t.Fatalf("session summaries = %+v, want the pending analysis of the session video", summaries)
	}

	userSummaries, total, err := repo.ListAnalysisSummariesByUserID(ctx, userID, model.Pagination{Limit: 10})
	if err != nil {
		t.Fatalf("ListAnalysisSummariesByUserID() error = %v", err)
	}
	if total != 2 || len(userSummaries) != 2 || userSummaries[0].ID != standalone.ID || userSummaries[0].ClimbingSessionID != nil || userSummaries[1].ID != analysis.ID {
		t.Fatalf("user summaries = %+v (total %d), want the standalone analysis then the session one", userSummaries, total)
	}
	if page, total, err := repo.ListAnalysisSummariesByUserID(ctx, userID, model.Pagination{Limit: 1, Offset: 1}); err != nil || total != 2 || len(page) != 1 || page[0].ID != analysis.ID {
		t.Fatalf("second page = %+v (total %d), %v", page, total, err)
	}

	// Linking a standalone video to the session, as POST /v1/sessions/:id/analyses does.
	sessionID := &session.ID
	if _, err := repo.UpdateVideo(ctx, model.VideoPartial{ID: standaloneVideo, UserID: userID, ClimbingSessionID: &sessionID}); err != nil {
		t.Fatalf("UpdateVideo() error = %v", err)
	}
	if summaries, err = repo.ListAnalysisSummariesByClimbingSessionID(ctx, session.ID); err != nil || len(summaries) != 2 {
		t.Fatalf("session summaries after linking = %+v, %v; want 2", summaries, err)
	}

	if err := repo.DeleteClimbingSession(ctx, session.ID, userID); err != nil {
		t.Fatalf("DeleteClimbingSession() error = %v", err)
	}

	var linked int
	if err := repo.Pool.QueryRow(ctx, "SELECT COUNT(*) FROM videos WHERE user_id = $1 AND climbing_session_id IS NOT NULL", userID).Scan(&linked); err != nil {
		t.Fatalf("count linked videos: %v", err)
	}
	if linked != 0 {
		t.Errorf("%d videos still linked after delete, want 0 (ON DELETE SET NULL)", linked)
	}
	if _, total, err := repo.ListAnalysisSummariesByUserID(ctx, userID, model.Pagination{Limit: 10}); err != nil || total != 2 {
		t.Errorf("analyses after delete: total = %d, %v; want both kept", total, err)
	}
}

func TestFixVideosClimbingSessionForeignKeyMigration(t *testing.T) {
	ctx := context.Background()
	db := pgtest.Open(t)
	pool := db.Repo.Pool

	m, err := migrate.New("file://migrations", db.DSN)
	if err != nil {
		t.Fatalf("migrate.New() error = %v", err)
	}
	t.Cleanup(func() { m.Close() })

	// Back to the schema before the migration, where videos.climbing_session_id referenced users(id).
	if err := m.Steps(-1); err != nil {
		t.Fatalf("migrate down: %v", err)
	}
	assertForeignKeyTarget(t, db, "videos_climbing_session_id_fkey", "users")

	userID := db.CreateUser(t)
	// A video wrongly linked to a user ID, accepted by the old constraint.
	strayVideo := db.CreateVideo(t, userID, &userID)

	// A climbing session whose ID also exists in users, so the old constraint accepts the link.
	sessionOwner := db.CreateUser(t)
	if _, err := pool.Exec(ctx, "INSERT INTO climbing_sessions (id, user_id, started_at) VALUES ($1, $2, NOW())", sessionOwner, userID); err != nil {
		t.Fatalf("insert climbing session: %v", err)
	}
	linkedVideo := db.CreateVideo(t, userID, &sessionOwner)

	if err := m.Steps(1); err != nil {
		t.Fatalf("migrate up: %v", err)
	}
	assertForeignKeyTarget(t, db, "videos_climbing_session_id_fkey", "climbing_sessions")

	var stray, linked *uuid.UUID
	if err := pool.QueryRow(ctx, "SELECT climbing_session_id FROM videos WHERE id = $1", strayVideo).Scan(&stray); err != nil {
		t.Fatal(err)
	}
	if err := pool.QueryRow(ctx, "SELECT climbing_session_id FROM videos WHERE id = $1", linkedVideo).Scan(&linked); err != nil {
		t.Fatal(err)
	}
	if stray != nil {
		t.Errorf("stray video climbing_session_id = %v, want NULL", *stray)
	}
	if linked == nil || *linked != sessionOwner {
		t.Errorf("linked video climbing_session_id = %v, want %v", linked, sessionOwner)
	}
	if columnExists(t, db, "analyses", "climbing_session_id") {
		t.Error("analyses.climbing_session_id exists, want the link held by videos only")
	}
}

func assertForeignKeyTarget(t *testing.T, db pgtest.DB, constraint string, wantTable string) {
	t.Helper()

	var table string
	if err := db.Repo.Pool.QueryRow(context.Background(),
		"SELECT confrelid::regclass::text FROM pg_constraint WHERE conname = $1 AND contype = 'f'", constraint,
	).Scan(&table); err != nil {
		t.Fatalf("read foreign key %s: %v", constraint, err)
	}
	if table != wantTable {
		t.Fatalf("%s references %s, want %s", constraint, table, wantTable)
	}
}

func columnExists(t *testing.T, db pgtest.DB, table string, column string) bool {
	t.Helper()

	var exists bool
	if err := db.Repo.Pool.QueryRow(context.Background(),
		"SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = $1 AND column_name = $2)", table, column,
	).Scan(&exists); err != nil {
		t.Fatalf("read column %s.%s: %v", table, column, err)
	}

	return exists
}
