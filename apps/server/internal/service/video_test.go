// @date 2026-11-13
// @file video_test.go
// @brief Unit tests of the video service: presigned URLs, upload completion, listing and cleanup.
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

// memStorage presigns fake URLs, knows the objects in exists and fails with err when set.
type memStorage struct {
	exists     map[string]bool
	err        error
	presigned  []string
	expiresAt  time.Time
	deletedKey []string
}

func newMemStorage() *memStorage {
	return &memStorage{exists: map[string]bool{}, expiresAt: time.Date(2026, 11, 13, 12, 0, 0, 0, time.UTC)}
}

func (s *memStorage) presign(kind string, key string) (*url.URL, time.Time, error) {
	if s.err != nil {
		return nil, time.Time{}, s.err
	}
	s.presigned = append(s.presigned, kind+":"+key)
	return &url.URL{Scheme: "https", Host: "storage.test", Path: "/" + kind + "/" + key}, s.expiresAt, nil
}

func (s *memStorage) PresignedUploadURL(_ context.Context, key string) (*url.URL, time.Time, error) {
	return s.presign("upload", key)
}

func (s *memStorage) PresignedDownloadURL(_ context.Context, key string) (*url.URL, time.Time, error) {
	return s.presign("download", key)
}

func (s *memStorage) FileExist(_ context.Context, key string) (bool, error) {
	if s.err != nil {
		return false, s.err
	}
	return s.exists[key], nil
}

func (s *memStorage) Delete(_ context.Context, key string) error {
	s.deletedKey = append(s.deletedKey, key)
	return s.err
}

// failingVideoRepo is a memrepo whose video methods fail.
type failingVideoRepo struct {
	*memrepo.Repo
}

func (failingVideoRepo) CreateVideo(context.Context, model.Video) error { return errRepo }

func (failingVideoRepo) ListVideosByFilter(context.Context, model.VideoFilter, model.Pagination) ([]model.Video, error) {
	return nil, errRepo
}

func (failingVideoRepo) GetVideoByFilter(context.Context, model.VideoFilter) (model.Video, error) {
	return model.Video{}, errRepo
}

func (failingVideoRepo) DeleteVideosUploadExpired(context.Context) error { return errRepo }

func (failingVideoRepo) DeleteVideosExpired(context.Context, time.Duration) error { return errRepo }

// failingSessionLookupRepo is a memrepo whose climbing session lookup fails.
type failingSessionLookupRepo struct {
	*memrepo.Repo
}

func (failingSessionLookupRepo) GetClimbingSessionByFilter(context.Context, model.ClimbingSessionFilter) (model.ClimbingSession, error) {
	return model.ClimbingSession{}, errRepo
}

// failingVideoUpdateRepo is a memrepo whose video update fails.
type failingVideoUpdateRepo struct {
	*memrepo.Repo
}

func (failingVideoUpdateRepo) UpdateVideo(context.Context, model.VideoPartial) (model.Video, error) {
	return model.Video{}, errRepo
}

var testVideoConfig = config.VideoConfig{Retention: 30 * 24 * time.Hour}
var testStorageConfig = config.StorageConfig{UploadExp: 15 * time.Minute}

func newTestVideoService(repo *memrepo.Repo, storage model.VideoStorage) VideoService {
	return NewVideoService(testVideoConfig, testStorageConfig, storage, repo, repo)
}

func mp4Metadata(t *testing.T) model.VideoMetadata {
	t.Helper()
	metadata, err := model.NewVideoMetadata("video/mp4", 1024)
	if err != nil {
		t.Fatalf("NewVideoMetadata() error = %v", err)
	}
	return metadata
}

func TestGetUploadURL(t *testing.T) {
	ctx := context.Background()
	userID := uuid.NewV7()

	t.Run("creates a pending video and presigns its object key", func(t *testing.T) {
		repo := memrepo.New()
		storage := newMemStorage()
		s := newTestVideoService(repo, storage)

		before := time.Now()
		upload, err := s.GetUploadURL(ctx, userID, mp4Metadata(t), model.VideoConfig{Title: new("Dalle"), Visibility: model.VisibilityFriends, Retained: true})
		if err != nil {
			t.Fatalf("GetUploadURL() error = %v", err)
		}

		video, ok := repo.Video(upload.VideoID)
		if !ok {
			t.Fatal("the video is not stored")
		}
		wantKey := userID.String() + "/" + upload.VideoID.String() + ".mp4"
		if video.ObjectKey != wantKey {
			t.Errorf("ObjectKey = %q, want %q", video.ObjectKey, wantKey)
		}
		if video.Status != model.VideoStatusPending || video.UserID != userID || video.Visibility != model.VisibilityFriends ||
			!video.Retained || video.ContentType != "video/mp4" || video.SizeBytes == nil || *video.SizeBytes != 1024 ||
			video.Title == nil || *video.Title != "Dalle" {
			t.Errorf("video = %+v, want a pending video with the metadata and config", video)
		}
		if video.UploadURLExpiresAt == nil || video.UploadURLExpiresAt.Before(before.Add(testStorageConfig.UploadExp)) {
			t.Errorf("UploadURLExpiresAt = %v, want now + %v", video.UploadURLExpiresAt, testStorageConfig.UploadExp)
		}
		if len(storage.presigned) != 1 || storage.presigned[0] != "upload:"+wantKey {
			t.Errorf("presigned = %v, want the upload of %q", storage.presigned, wantKey)
		}
		if upload.URL == nil || upload.URL.Path != "/upload/"+wantKey || !upload.ExpiresAt.Equal(storage.expiresAt) {
			t.Errorf("upload = %+v, want the URL and expiry of the storage", upload)
		}
	})

	t.Run("links the video to an owned climbing session", func(t *testing.T) {
		repo := memrepo.New()
		s := newTestVideoService(repo, newMemStorage())
		session, _ := repo.CreateClimbingSession(ctx, model.ClimbingSession{UserID: userID, StartedAt: time.Now()})

		upload, err := s.GetUploadURL(ctx, userID, mp4Metadata(t), model.VideoConfig{ClimbingSessionID: &session.ID, Visibility: model.VisibilityPrivate})
		if err != nil {
			t.Fatalf("GetUploadURL() error = %v", err)
		}
		video, _ := repo.Video(upload.VideoID)
		if video.ClimbingSessionID == nil || *video.ClimbingSessionID != session.ID {
			t.Errorf("ClimbingSessionID = %v, want %v", video.ClimbingSessionID, session.ID)
		}
	})

	t.Run("rejects the session of another user", func(t *testing.T) {
		repo := memrepo.New()
		s := newTestVideoService(repo, newMemStorage())
		session, _ := repo.CreateClimbingSession(ctx, model.ClimbingSession{UserID: uuid.NewV7(), StartedAt: time.Now()})

		_, err := s.GetUploadURL(ctx, userID, mp4Metadata(t), model.VideoConfig{ClimbingSessionID: &session.ID, Visibility: model.VisibilityPrivate})
		if !errors.Is(err, model.ErrInvalidInput) {
			t.Errorf("GetUploadURL() error = %v, want ErrInvalidInput", err)
		}
		if len(repo.Videos()) != 0 {
			t.Error("a video was stored")
		}
	})

	t.Run("forwards a session lookup error", func(t *testing.T) {
		repo := memrepo.New()
		s := NewVideoService(testVideoConfig, testStorageConfig, newMemStorage(), repo, failingSessionLookupRepo{repo})
		sessionID := uuid.NewV7()

		if _, err := s.GetUploadURL(ctx, userID, mp4Metadata(t), model.VideoConfig{ClimbingSessionID: &sessionID, Visibility: model.VisibilityPrivate}); !errors.Is(err, errRepo) {
			t.Errorf("GetUploadURL() error = %v, want %v", err, errRepo)
		}
	})

	t.Run("rejects an unknown visibility", func(t *testing.T) {
		repo := memrepo.New()
		s := newTestVideoService(repo, newMemStorage())

		if _, err := s.GetUploadURL(ctx, userID, mp4Metadata(t), model.VideoConfig{Visibility: "everyone"}); err == nil {
			t.Error("GetUploadURL() error = nil, want a validation error")
		}
		if len(repo.Videos()) != 0 {
			t.Error("a video was stored")
		}
	})

	t.Run("forwards the storage error", func(t *testing.T) {
		storage := newMemStorage()
		storage.err = errors.New("storage down")
		s := newTestVideoService(memrepo.New(), storage)

		if _, err := s.GetUploadURL(ctx, userID, mp4Metadata(t), model.VideoConfig{Visibility: model.VisibilityPrivate}); !errors.Is(err, storage.err) {
			t.Errorf("GetUploadURL() error = %v, want %v", err, storage.err)
		}
	})

	t.Run("forwards the repository error", func(t *testing.T) {
		repo := memrepo.New()
		storage := newMemStorage()
		s := NewVideoService(testVideoConfig, testStorageConfig, storage, failingVideoRepo{repo}, repo)

		if _, err := s.GetUploadURL(ctx, userID, mp4Metadata(t), model.VideoConfig{Visibility: model.VisibilityPrivate}); !errors.Is(err, errRepo) {
			t.Errorf("GetUploadURL() error = %v, want %v", err, errRepo)
		}
		if len(storage.presigned) != 0 {
			t.Error("an upload URL was presigned for a video that was not stored")
		}
	})
}

func TestGetDownloadURL(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	storage := newMemStorage()
	s := newTestVideoService(repo, storage)
	userID := uuid.NewV7()
	completed := model.Video{ID: uuid.NewV7(), UserID: userID, ObjectKey: "user/done.mp4", Status: model.VideoStatusCompleted}
	pending := model.Video{ID: uuid.NewV7(), UserID: userID, ObjectKey: "user/pending.mp4", Status: model.VideoStatusPending}
	repo.PutVideo(completed)
	repo.PutVideo(pending)

	download, err := s.GetDownloadURL(ctx, completed.ID, userID)
	if err != nil {
		t.Fatalf("GetDownloadURL() error = %v", err)
	}
	if download.URL == nil || download.URL.Path != "/download/user/done.mp4" || !download.ExpiresAt.Equal(storage.expiresAt) {
		t.Errorf("download = %+v, want the presigned URL of the object", download)
	}

	if _, err := s.GetDownloadURL(ctx, pending.ID, userID); !errors.Is(err, model.ErrVideoUploading) {
		t.Errorf("GetDownloadURL(pending) error = %v, want ErrVideoUploading", err)
	}
	if _, err := s.GetDownloadURL(ctx, completed.ID, uuid.NewV7()); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("GetDownloadURL(other user) error = %v, want ErrNotFound", err)
	}

	storage.err = errors.New("storage down")
	if _, err := s.GetDownloadURL(ctx, completed.ID, userID); !errors.Is(err, storage.err) {
		t.Errorf("GetDownloadURL() error = %v, want %v", err, storage.err)
	}
}

func TestUploadComplete(t *testing.T) {
	ctx := context.Background()
	userID := uuid.NewV7()
	newPending := func(repo *memrepo.Repo) model.Video {
		video := model.Video{ID: uuid.NewV7(), UserID: userID, ObjectKey: "user/video.mp4", Status: model.VideoStatusPending, UploadURLExpiresAt: new(time.Now().Add(time.Minute))}
		repo.PutVideo(video)
		return video
	}

	t.Run("completes an uploaded video", func(t *testing.T) {
		repo := memrepo.New()
		storage := newMemStorage()
		s := newTestVideoService(repo, storage)
		video := newPending(repo)
		storage.exists[video.ObjectKey] = true

		if err := s.UploadComplete(ctx, video.ID, userID); err != nil {
			t.Fatalf("UploadComplete() error = %v", err)
		}
		stored, _ := repo.Video(video.ID)
		if stored.Status != model.VideoStatusCompleted || stored.UploadURLExpiresAt != nil {
			t.Errorf("(status, upload expiry) = (%q, %v), want (completed, nil)", stored.Status, stored.UploadURLExpiresAt)
		}
	})

	t.Run("rejects a video that was not uploaded", func(t *testing.T) {
		repo := memrepo.New()
		s := newTestVideoService(repo, newMemStorage())
		video := newPending(repo)

		if err := s.UploadComplete(ctx, video.ID, userID); !errors.Is(err, model.ErrVideoNotFound) {
			t.Errorf("UploadComplete() error = %v, want ErrVideoNotFound", err)
		}
		if stored, _ := repo.Video(video.ID); stored.Status != model.VideoStatusPending {
			t.Errorf("Status = %q, want pending", stored.Status)
		}
	})

	t.Run("rejects the video of another user", func(t *testing.T) {
		repo := memrepo.New()
		storage := newMemStorage()
		s := newTestVideoService(repo, storage)
		video := newPending(repo)
		storage.exists[video.ObjectKey] = true

		if err := s.UploadComplete(ctx, video.ID, uuid.NewV7()); !errors.Is(err, model.ErrNotFound) {
			t.Errorf("UploadComplete(other user) error = %v, want ErrNotFound", err)
		}
	})

	t.Run("forwards the storage error", func(t *testing.T) {
		repo := memrepo.New()
		storage := newMemStorage()
		storage.err = errors.New("storage down")
		s := newTestVideoService(repo, storage)
		video := newPending(repo)

		if err := s.UploadComplete(ctx, video.ID, userID); !errors.Is(err, storage.err) {
			t.Errorf("UploadComplete() error = %v, want %v", err, storage.err)
		}
	})

	t.Run("forwards the update error", func(t *testing.T) {
		repo := memrepo.New()
		storage := newMemStorage()
		s := NewVideoService(testVideoConfig, testStorageConfig, storage, failingVideoUpdateRepo{repo}, repo)
		video := newPending(repo)
		storage.exists[video.ObjectKey] = true

		if err := s.UploadComplete(ctx, video.ID, userID); !errors.Is(err, errRepo) {
			t.Errorf("UploadComplete() error = %v, want %v", err, errRepo)
		}
	})
}

func TestGetAndListVideos(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := newTestVideoService(repo, newMemStorage())
	userID := uuid.NewV7()
	start := time.Date(2026, 11, 13, 10, 0, 0, 0, time.UTC)
	ids := []uuid.UUID{}
	for i := range 3 {
		video := model.Video{ID: uuid.NewV7(), UserID: userID, Status: model.VideoStatusCompleted, CreatedAt: start.Add(time.Duration(i) * time.Hour)}
		repo.PutVideo(video)
		ids = append(ids, video.ID)
	}
	repo.PutVideo(model.Video{ID: uuid.NewV7(), UserID: uuid.NewV7(), CreatedAt: start})

	video, err := s.GetVideoByUserID(ctx, ids[0], userID)
	if err != nil || video.ID != ids[0] {
		t.Errorf("GetVideoByUserID() = (%v, %v), want (%v, nil)", video.ID, err, ids[0])
	}
	if _, err := s.GetVideoByUserID(ctx, ids[0], uuid.NewV7()); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("GetVideoByUserID(other user) error = %v, want ErrNotFound", err)
	}

	videos, err := s.ListVideosByUserID(ctx, userID, model.Pagination{Limit: 2, Offset: 1})
	if err != nil {
		t.Fatalf("ListVideosByUserID() error = %v", err)
	}
	if len(videos) != 2 || videos[0].ID != ids[1] || videos[1].ID != ids[2] {
		t.Errorf("ListVideosByUserID() = %v, want the 2nd and 3rd videos of the user, oldest first", videos)
	}

	failing := NewVideoService(testVideoConfig, testStorageConfig, newMemStorage(), failingVideoRepo{repo}, repo)
	if _, err := failing.GetVideoByUserID(ctx, ids[0], userID); !errors.Is(err, errRepo) {
		t.Errorf("GetVideoByUserID() error = %v, want %v", err, errRepo)
	}
	if _, err := failing.ListVideosByUserID(ctx, userID, model.Pagination{Limit: 10}); !errors.Is(err, errRepo) {
		t.Errorf("ListVideosByUserID() error = %v, want %v", err, errRepo)
	}
}

func TestClearVideos(t *testing.T) {
	ctx := context.Background()
	now := time.Now()
	repo := memrepo.New()
	s := newTestVideoService(repo, newMemStorage())
	put := func(status model.VideoStatus, retained bool, createdAt time.Time, uploadExpiresAt *time.Time) uuid.UUID {
		video := model.Video{ID: uuid.NewV7(), UserID: uuid.NewV7(), Status: status, Retained: retained, CreatedAt: createdAt, UploadURLExpiresAt: uploadExpiresAt}
		repo.PutVideo(video)
		return video.ID
	}

	expiredUpload := put(model.VideoStatusPending, false, now, new(now.Add(-time.Minute)))
	runningUpload := put(model.VideoStatusPending, false, now, new(now.Add(time.Minute)))
	oldVideo := put(model.VideoStatusCompleted, false, now.Add(-31*24*time.Hour), nil)
	oldRetained := put(model.VideoStatusCompleted, true, now.Add(-31*24*time.Hour), nil)
	recentVideo := put(model.VideoStatusCompleted, false, now.Add(-24*time.Hour), nil)

	if err := s.ClearUploadExpiredVideos(ctx); err != nil {
		t.Fatalf("ClearUploadExpiredVideos() error = %v", err)
	}
	if err := s.ClearExpiredVideos(ctx); err != nil {
		t.Fatalf("ClearExpiredVideos() error = %v", err)
	}

	for id, wantKept := range map[uuid.UUID]bool{expiredUpload: false, runningUpload: true, oldVideo: false, oldRetained: true, recentVideo: true} {
		if _, kept := repo.Video(id); kept != wantKept {
			t.Errorf("video %v kept = %v, want %v", id, kept, wantKept)
		}
	}

	failing := NewVideoService(testVideoConfig, testStorageConfig, newMemStorage(), failingVideoRepo{repo}, repo)
	if err := failing.ClearUploadExpiredVideos(ctx); !errors.Is(err, errRepo) {
		t.Errorf("ClearUploadExpiredVideos() error = %v, want %v", err, errRepo)
	}
	if err := failing.ClearExpiredVideos(ctx); !errors.Is(err, errRepo) {
		t.Errorf("ClearExpiredVideos() error = %v, want %v", err, errRepo)
	}
}

// retentionRecorder records the retention period given to DeleteVideosExpired.
type retentionRecorder struct {
	*memrepo.Repo
	retention time.Duration
}

func (r *retentionRecorder) DeleteVideosExpired(_ context.Context, retention time.Duration) error {
	r.retention = retention
	return nil
}

func TestClearExpiredVideosUsesTheConfiguredRetention(t *testing.T) {
	repo := &retentionRecorder{Repo: memrepo.New()}
	s := NewVideoService(config.VideoConfig{Retention: 42 * time.Hour}, testStorageConfig, newMemStorage(), repo, repo)

	if err := s.ClearExpiredVideos(context.Background()); err != nil {
		t.Fatalf("ClearExpiredVideos() error = %v", err)
	}
	if repo.retention != 42*time.Hour {
		t.Errorf("retention = %v, want 42h", repo.retention)
	}
}
