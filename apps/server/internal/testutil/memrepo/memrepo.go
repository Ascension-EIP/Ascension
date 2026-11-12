// @date 2026-11-13
// @file memrepo.go
// @brief In-memory repository for unit tests of the climbing session, video and analysis services.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
// Package memrepo is an in-memory stand-in for the PostgreSQL repository, used by unit
// tests only. It implements model.ClimbingSessionRepository, model.AnalysisRepository,
// model.VideoRepository, model.UserBodyConstraintRepository, model.FriendshipRepository and
// model.FeedRepository with the same ownership, visibility and not-found rules as the real
// queries.
package memrepo

import (
	"cmp"
	"context"
	"errors"
	"fmt"
	"slices"
	"sync"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

// ErrNotImplemented is returned by the methods the tests do not need.
var ErrNotImplemented = errors.New("memrepo: not implemented")

// Repo stores climbing sessions, videos and analyses in memory. The zero value is not
// usable: build it with New.
type Repo struct {
	mu              sync.Mutex
	sessions        map[uuid.UUID]model.ClimbingSession
	videos          map[uuid.UUID]model.Video
	analyses        map[uuid.UUID]model.Analysis
	bodyConstraints map[uuid.UUID]model.UserBodyConstraint
	users           map[uuid.UUID]model.User
	friendships     map[uuid.UUID]model.Friendship
	now             func() time.Time
}

// New returns an empty repository.
func New() *Repo {
	return &Repo{
		sessions:        map[uuid.UUID]model.ClimbingSession{},
		videos:          map[uuid.UUID]model.Video{},
		analyses:        map[uuid.UUID]model.Analysis{},
		bodyConstraints: map[uuid.UUID]model.UserBodyConstraint{},
		users:           map[uuid.UUID]model.User{},
		friendships:     map[uuid.UUID]model.Friendship{},
		now:             time.Now,
	}
}

// WithTransaction runs fn directly: the in-memory store has no rollback.
func (r *Repo) WithTransaction(ctx context.Context, fn func(context.Context) error) error {
	return fn(ctx)
}

// -- Climbing sessions -- //

func (r *Repo) CreateClimbingSession(_ context.Context, session model.ClimbingSession) (model.ClimbingSession, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if session.Visibility == "" {
		session.Visibility = model.VisibilityPrivate
	}
	session.ID = uuid.NewV7()
	session.CreatedAt = r.now()
	session.UpdatedAt = session.CreatedAt
	r.sessions[session.ID] = session

	return session, nil
}

func (r *Repo) GetClimbingSessionByFilter(_ context.Context, filter model.ClimbingSessionFilter) (model.ClimbingSession, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, session := range r.sessions {
		if filter.ID != nil && session.ID != *filter.ID {
			continue
		}
		if filter.UserID != nil && session.UserID != *filter.UserID {
			continue
		}
		return session, nil
	}

	return model.ClimbingSession{}, model.ErrNotFound
}

func (r *Repo) GetActiveClimbingSessionByUserID(_ context.Context, userID uuid.UUID) (model.ClimbingSession, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	var active *model.ClimbingSession
	for _, session := range r.sessions {
		if session.UserID != userID || session.EndedAt != nil {
			continue
		}
		if active == nil || session.StartedAt.After(active.StartedAt) {
			active = &session
		}
	}
	if active == nil {
		return model.ClimbingSession{}, model.ErrNotFound
	}

	return *active, nil
}

func (r *Repo) ListClimbingSessionsByUserID(_ context.Context, userID uuid.UUID, pagination model.Pagination) ([]model.ClimbingSession, int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	owned := []model.ClimbingSession{}
	for _, session := range r.sessions {
		if session.UserID == userID {
			owned = append(owned, session)
		}
	}
	slices.SortFunc(owned, func(a, b model.ClimbingSession) int {
		if c := b.StartedAt.Compare(a.StartedAt); c != 0 {
			return c
		}
		return cmp.Compare(b.ID.String(), a.ID.String())
	})

	total := len(owned)
	start := min(pagination.Offset, total)
	end := min(start+pagination.Limit, total)

	return owned[start:end], total, nil
}

func (r *Repo) UpdateClimbingSession(_ context.Context, partial model.ClimbingSessionPartial) (model.ClimbingSession, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if partial.IsEmpty() {
		return model.ClimbingSession{}, fmt.Errorf("%w: nothing to update", model.ErrInvalidInput)
	}

	session, ok := r.sessions[partial.ID]
	if !ok || session.UserID != partial.UserID {
		return model.ClimbingSession{}, model.ErrNotFound
	}

	if partial.Title != nil {
		session.Title = *partial.Title
	}
	if partial.Notes != nil {
		session.Notes = *partial.Notes
	}
	if partial.EndedAt != nil {
		session.EndedAt = *partial.EndedAt
	}
	session.UpdatedAt = r.now()
	r.sessions[session.ID] = session

	return session, nil
}

// DeleteClimbingSession deletes the session and unlinks its videos, like the
// ON DELETE SET NULL foreign key.
func (r *Repo) DeleteClimbingSession(_ context.Context, id uuid.UUID, userID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	session, ok := r.sessions[id]
	if !ok || session.UserID != userID {
		return model.ErrNotFound
	}
	delete(r.sessions, id)

	for videoID, video := range r.videos {
		if video.ClimbingSessionID != nil && *video.ClimbingSessionID == id {
			video.ClimbingSessionID = nil
			r.videos[videoID] = video
		}
	}
	return nil
}

// -- Analyses -- //

func (r *Repo) CreateAnalysis(_ context.Context, analysis model.Analysis) (model.Analysis, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, ok := r.videos[analysis.VideoID]; !ok {
		return model.Analysis{}, model.ErrInvalidInput
	}
	analysis.ID = uuid.NewV7()
	analysis.Status = model.JobStatusPending
	analysis.CreatedAt = r.now()
	analysis.UpdatedAt = analysis.CreatedAt
	r.analyses[analysis.ID] = analysis

	return analysis, nil
}

func (r *Repo) GetAnalysisByFilter(_ context.Context, filter model.AnalysisFilter) (model.Analysis, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, analysis := range r.analyses {
		if filter.ID != nil && analysis.ID != *filter.ID {
			continue
		}
		if filter.VideoID != nil && analysis.VideoID != *filter.VideoID {
			continue
		}
		return analysis, nil
	}

	return model.Analysis{}, model.ErrNotFound
}

func (r *Repo) ListAnalysisSummariesByClimbingSessionID(_ context.Context, climbingSessionID uuid.UUID) ([]model.AnalysisSummary, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	return r.summaries(func(_ model.Analysis, video model.Video) bool {
		return video.ClimbingSessionID != nil && *video.ClimbingSessionID == climbingSessionID
	}), nil
}

func (r *Repo) ListAnalysisSummariesByUserID(_ context.Context, userID uuid.UUID, pagination model.Pagination) ([]model.AnalysisSummary, int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	summaries := r.summaries(func(_ model.Analysis, video model.Video) bool {
		return video.UserID == userID
	})

	total := len(summaries)
	start := min(pagination.Offset, total)
	end := min(start+pagination.Limit, total)

	return summaries[start:end], total, nil
}

// summaries lists the analyses kept by keep, newest first, with the session of their video.
// The caller holds r.mu.
func (r *Repo) summaries(keep func(model.Analysis, model.Video) bool) []model.AnalysisSummary {
	summaries := []model.AnalysisSummary{}
	for _, analysis := range r.analyses {
		video := r.videos[analysis.VideoID]
		if !keep(analysis, video) {
			continue
		}
		summaries = append(summaries, model.AnalysisSummary{
			ID:                analysis.ID,
			VideoID:           analysis.VideoID,
			ClimbingSessionID: video.ClimbingSessionID,
			Type:              analysis.Type,
			Status:            analysis.Status,
			Visibility:        analysis.Visibility,
			Progress:          analysis.Progress,
			StartedAt:         analysis.StartedAt,
			CompletedAt:       analysis.CompletedAt,
			CreatedAt:         analysis.CreatedAt,
		})
	}
	slices.SortFunc(summaries, func(a, b model.AnalysisSummary) int {
		if c := b.CreatedAt.Compare(a.CreatedAt); c != 0 {
			return c
		}
		return cmp.Compare(b.ID.String(), a.ID.String())
	})

	return summaries
}

// -- Videos -- //

func (r *Repo) CreateVideo(_ context.Context, video model.Video) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if video.ClimbingSessionID != nil {
		if _, ok := r.sessions[*video.ClimbingSessionID]; !ok {
			return model.ErrInvalidInput
		}
	}
	video.CreatedAt = r.now()
	video.UpdatedAt = video.CreatedAt
	r.videos[video.ID] = video

	return nil
}

func (r *Repo) GetVideoByFilter(_ context.Context, filter model.VideoFilter) (model.Video, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, video := range r.videos {
		if filter.ID != nil && video.ID != *filter.ID {
			continue
		}
		if filter.UserID != nil && video.UserID != *filter.UserID {
			continue
		}
		return video, nil
	}

	return model.Video{}, model.ErrNotFound
}

func (r *Repo) ListVideosByFilter(context.Context, model.VideoFilter, model.Pagination) ([]model.Video, error) {
	return nil, ErrNotImplemented
}

// UpdateVideo only supports changing the climbing session of a video.
func (r *Repo) UpdateVideo(_ context.Context, partial model.VideoPartial) (model.Video, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	video, ok := r.videos[partial.ID]
	if !ok {
		return model.Video{}, model.ErrNotFound
	}
	if partial.ClimbingSessionID == nil {
		return model.Video{}, ErrNotImplemented
	}
	if sessionID := *partial.ClimbingSessionID; sessionID != nil {
		if _, ok := r.sessions[*sessionID]; !ok {
			return model.Video{}, model.ErrInvalidInput
		}
	}
	video.ClimbingSessionID = *partial.ClimbingSessionID
	video.UpdatedAt = r.now()
	r.videos[video.ID] = video

	return video, nil
}

func (r *Repo) DeleteVideosUploadExpired(context.Context) error {
	return ErrNotImplemented
}

func (r *Repo) DeleteVideosExpired(context.Context, time.Duration) error {
	return ErrNotImplemented
}

// -- Test helpers -- //

// Videos returns a copy of the stored videos.
func (r *Repo) Videos() []model.Video {
	r.mu.Lock()
	defer r.mu.Unlock()

	videos := make([]model.Video, 0, len(r.videos))
	for _, video := range r.videos {
		videos = append(videos, video)
	}

	return videos
}

// Video returns a stored video.
func (r *Repo) Video(id uuid.UUID) (model.Video, bool) {
	r.mu.Lock()
	defer r.mu.Unlock()

	video, ok := r.videos[id]
	return video, ok
}

// PutVideo stores a video as is, bypassing the checks of CreateVideo.
func (r *Repo) PutVideo(video model.Video) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.videos[video.ID] = video
}
