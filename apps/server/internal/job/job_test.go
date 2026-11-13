// @date 2026-11-13
// @file job_test.go
// @brief Unit tests of the cron jobs: schedule, the service call they run and the logged failures.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package job

import (
	"bytes"
	"context"
	"errors"
	"log/slog"
	"strings"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
	"github.com/robfig/cron/v3"
)

var errRepo = errors.New("repository down")

// failingRepo is a memrepo whose cleanup and listing methods fail.
type failingRepo struct {
	*memrepo.Repo
}

func (failingRepo) DeleteSessionsExpired(context.Context) error { return errRepo }

func (failingRepo) DeleteVideosUploadExpired(context.Context) error { return errRepo }

func (failingRepo) DeleteVideosExpired(context.Context, time.Duration) error { return errRepo }

func (failingRepo) DeleteOldQuotaUsage(context.Context) error { return errRepo }

func (failingRepo) ListAnalysisByFilter(context.Context, model.AnalysisFilter, model.Pagination) ([]model.Analysis, error) {
	return nil, errRepo
}

// noQueue drops the analysis jobs.
type noQueue struct{}

func (noQueue) PublishPoseDetectRequested(context.Context, []byte) error { return nil }

// captureLogs sends the default slog output to a buffer for the test.
func captureLogs(t *testing.T) *bytes.Buffer {
	t.Helper()

	previous := slog.Default()
	t.Cleanup(func() { slog.SetDefault(previous) })

	var buf bytes.Buffer
	slog.SetDefault(slog.New(slog.NewTextHandler(&buf, nil)))
	return &buf
}

// onlyEntry returns the single job registered on c, checking its schedule against spec.
func onlyEntry(t *testing.T, c *cron.Cron, spec string) cron.Entry {
	t.Helper()

	entries := c.Entries()
	if len(entries) != 1 {
		t.Fatalf("registered %d jobs, want 1", len(entries))
	}

	want, err := cron.ParseStandard(spec)
	if err != nil {
		t.Fatalf("ParseStandard(%q) error = %v", spec, err)
	}
	from := time.Date(2026, 11, 13, 10, 30, 0, 0, time.UTC)
	for range 5 {
		next := want.Next(from)
		if got := entries[0].Schedule.Next(from); !got.Equal(next) {
			t.Fatalf("next run after %v = %v, want %v (%q)", from, got, next, spec)
		}
		from = next
	}

	return entries[0]
}

// jobCase registers one job on c with the repository.
type jobCase struct {
	name     string
	spec     string
	logged   string
	register func(c *cron.Cron, repo fullRepo) error
}

// fullRepo is every repository the job services need.
type fullRepo interface {
	model.SessionRepository
	model.VideoRepository
	model.ClimbingSessionRepository
	model.AnalysisRepository
	model.QuotaUsageRepository
}

var jobCases = []jobCase{
	{
		name:   "ClearExpiredSessions",
		spec:   "0 0 * * *",
		logged: "failed to clear expired sessions",
		register: func(c *cron.Cron, repo fullRepo) error {
			s := service.NewSessionService(config.SessionConfig{}, repo)
			return ClearExpiredSessions(c, context.Background(), &s)
		},
	},
	{
		name:   "ClearExpiredVideos",
		spec:   "0 0 * * *",
		logged: "failed to clear expired videos",
		register: func(c *cron.Cron, repo fullRepo) error {
			s := service.NewVideoService(config.VideoConfig{Retention: time.Hour}, config.StorageConfig{}, nil, repo, repo)
			return ClearExpiredVideos(c, context.Background(), &s)
		},
	},
	{
		name:   "ClearUploadExpiredVideos",
		spec:   "0 0 * * *",
		logged: "failed to clear expired video uploads",
		register: func(c *cron.Cron, repo fullRepo) error {
			s := service.NewVideoService(config.VideoConfig{}, config.StorageConfig{}, nil, repo, repo)
			return ClearUploadExpiredVideos(c, context.Background(), &s)
		},
	},
	{
		name:   "ClearOldQuotaUsage",
		spec:   "0 3 1 * *",
		logged: "failed to clear old quota usage",
		register: func(c *cron.Cron, repo fullRepo) error {
			s := service.NewQuotaUsageService(repo)
			return ClearOldQuotaUsage(c, context.Background(), &s)
		},
	},
	{
		name:   "AnalysisStaleDetection",
		spec:   "* * * * *",
		logged: "failed to detect stale analysis",
		register: func(c *cron.Cron, repo fullRepo) error {
			s := service.NewAnalysisService(config.StorageConfig{}, repo, repo, noQueue{})
			return AnalysisStaleDetection(c, context.Background(), &s)
		},
	},
}

func TestJobsAreScheduled(t *testing.T) {
	for _, tt := range jobCases {
		t.Run(tt.name, func(t *testing.T) {
			c := cron.New()
			repo := memrepo.New()
			if err := tt.register(c, repo); err != nil {
				t.Fatalf("%s() error = %v", tt.name, err)
			}
			onlyEntry(t, c, tt.spec)
		})
	}
}

func TestJobsRunWithoutLoggingOnSuccess(t *testing.T) {
	for _, tt := range jobCases {
		t.Run(tt.name, func(t *testing.T) {
			logs := captureLogs(t)
			c := cron.New()
			repo := memrepo.New()
			if err := tt.register(c, repo); err != nil {
				t.Fatalf("%s() error = %v", tt.name, err)
			}

			onlyEntry(t, c, tt.spec).Job.Run()

			if logs.Len() != 0 {
				t.Errorf("logs = %q, want none", logs.String())
			}
		})
	}
}

func TestJobsLogTheServiceError(t *testing.T) {
	for _, tt := range jobCases {
		t.Run(tt.name, func(t *testing.T) {
			logs := captureLogs(t)
			c := cron.New()
			repo := failingRepo{memrepo.New()}
			if err := tt.register(c, repo); err != nil {
				t.Fatalf("%s() error = %v", tt.name, err)
			}

			onlyEntry(t, c, tt.spec).Job.Run()

			out := logs.String()
			if !strings.Contains(out, "level=ERROR") || !strings.Contains(out, tt.logged) || !strings.Contains(out, errRepo.Error()) {
				t.Errorf("logs = %q, want an error with %q and %q", out, tt.logged, errRepo.Error())
			}
		})
	}
}

func TestJobsRejectAnInvalidSchedule(t *testing.T) {
	for _, tt := range jobCases {
		t.Run(tt.name, func(t *testing.T) {
			// A cron that expects a seconds field rejects the 5-field schedules.
			c := cron.New(cron.WithSeconds())
			repo := memrepo.New()
			if err := tt.register(c, repo); err == nil {
				t.Fatalf("%s() error = nil, want the schedule parse error", tt.name)
			}
			if len(c.Entries()) != 0 {
				t.Errorf("registered %d jobs, want none", len(c.Entries()))
			}
		})
	}
}

func TestJobsDoTheirWork(t *testing.T) {
	ctx := context.Background()

	t.Run("ClearExpiredSessions deletes the expired sessions", func(t *testing.T) {
		repo := memrepo.New()
		user, err := repo.CreateUser(ctx, model.User{Username: "climber", Password: model.UserPassword("password123")})
		if err != nil {
			t.Fatalf("CreateUser() error = %v", err)
		}
		repo.PutSession(model.Session{UserID: user.ID, TokenHash: "expired", ExpiresAt: time.Now().Add(-time.Hour)})
		c := cron.New()
		if err := jobCases[0].register(c, repo); err != nil {
			t.Fatalf("ClearExpiredSessions() error = %v", err)
		}

		onlyEntry(t, c, jobCases[0].spec).Job.Run()

		if len(repo.Sessions()) != 0 {
			t.Errorf("kept %d sessions, want none", len(repo.Sessions()))
		}
	})

	t.Run("ClearOldQuotaUsage cleans the quota usage", func(t *testing.T) {
		repo := memrepo.New()
		c := cron.New()
		if err := jobCases[3].register(c, repo); err != nil {
			t.Fatalf("ClearOldQuotaUsage() error = %v", err)
		}

		onlyEntry(t, c, jobCases[3].spec).Job.Run()

		if repo.QuotaCleanups() != 1 {
			t.Errorf("cleanups = %d, want 1", repo.QuotaCleanups())
		}
	})

	t.Run("ClearUploadExpiredVideos and ClearExpiredVideos delete the videos", func(t *testing.T) {
		repo := memrepo.New()
		abandoned := model.Video{ID: uuid.NewV7(), Status: model.VideoStatusPending, UploadURLExpiresAt: new(time.Now().Add(-time.Minute))}
		expired := model.Video{ID: uuid.NewV7(), Status: model.VideoStatusCompleted, CreatedAt: time.Now().Add(-2 * time.Hour)}
		repo.PutVideo(abandoned)
		repo.PutVideo(expired)
		c := cron.New()
		for _, tt := range jobCases[1:3] {
			if err := tt.register(c, repo); err != nil {
				t.Fatalf("%s() error = %v", tt.name, err)
			}
		}

		for _, entry := range c.Entries() {
			entry.Job.Run()
		}

		if len(repo.Videos()) != 0 {
			t.Errorf("kept %v, want no video", repo.Videos())
		}
	})
}
