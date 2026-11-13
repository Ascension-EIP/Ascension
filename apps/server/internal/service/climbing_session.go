// @date 2026-11-12
// @file climbing_session.go
// @brief Climbing session service: start, list, read, update and delete a user's climbing sessions.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"errors"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

// ClimbingSessionService handles the climbing session lifecycle. Every method is scoped to
// the calling user: a session owned by someone else is reported as model.ErrClimbingSessionNotFound.
type ClimbingSessionService struct {
	sessionR  model.ClimbingSessionRepository
	analysisR model.AnalysisRepository
	videoR    model.VideoRepository
	now       func() time.Time
}

// NewClimbingSessionService builds a ClimbingSessionService.
func NewClimbingSessionService(sessionR model.ClimbingSessionRepository, analysisR model.AnalysisRepository, videoR model.VideoRepository) ClimbingSessionService {
	return ClimbingSessionService{sessionR: sessionR, analysisR: analysisR, videoR: videoR, now: time.Now}
}

// StartClimbingSession creates a climbing session for the user. It starts now unless
// the config gives a start time.
func (s *ClimbingSessionService) StartClimbingSession(ctx context.Context, userID uuid.UUID, config model.ClimbingSessionConfig) (model.ClimbingSession, error) {
	if err := config.Validate(); err != nil {
		return model.ClimbingSession{}, err
	}

	startedAt := s.now()
	if config.StartedAt != nil {
		startedAt = *config.StartedAt
	}

	return s.sessionR.CreateClimbingSession(ctx, model.ClimbingSession{
		UserID:     userID,
		GymID:      config.GymID,
		Title:      config.Title,
		StartedAt:  startedAt,
		Notes:      config.Notes,
		Visibility: config.Visibility,
	})
}

// ListClimbingSessions returns one page of the user's climbing sessions, most recent first.
func (s *ClimbingSessionService) ListClimbingSessions(ctx context.Context, userID uuid.UUID, pagination model.Pagination) (model.ClimbingSessionPage, error) {
	sessions, total, err := s.sessionR.ListClimbingSessionsByUserID(ctx, userID, pagination)
	if err != nil {
		return model.ClimbingSessionPage{}, err
	}

	return model.ClimbingSessionPage{Sessions: sessions, Total: total, Pagination: pagination}, nil
}

// GetClimbingSessionDetails returns one of the user's climbing sessions with its analyses.
func (s *ClimbingSessionService) GetClimbingSessionDetails(ctx context.Context, id uuid.UUID, userID uuid.UUID) (model.ClimbingSessionDetails, error) {
	session, err := s.sessionR.GetClimbingSessionByFilter(ctx, model.ClimbingSessionFilter{ID: &id, UserID: &userID})
	if err != nil {
		return model.ClimbingSessionDetails{}, climbingSessionNotFound(err)
	}

	return s.withAnalyses(ctx, session)
}

// GetActiveClimbingSession returns the user's most recently started session that has not
// ended, with its analyses. It returns model.ErrClimbingSessionNotFound when there is none.
func (s *ClimbingSessionService) GetActiveClimbingSession(ctx context.Context, userID uuid.UUID) (model.ClimbingSessionDetails, error) {
	session, err := s.sessionR.GetActiveClimbingSessionByUserID(ctx, userID)
	if err != nil {
		return model.ClimbingSessionDetails{}, climbingSessionNotFound(err)
	}

	return s.withAnalyses(ctx, session)
}

func (s *ClimbingSessionService) withAnalyses(ctx context.Context, session model.ClimbingSession) (model.ClimbingSessionDetails, error) {
	analyses, err := s.analysisR.ListAnalysisSummariesByClimbingSessionID(ctx, session.ID)
	if err != nil {
		return model.ClimbingSessionDetails{}, err
	}

	return model.ClimbingSessionDetails{Session: session, Analyses: analyses}, nil
}

// AddAnalysisToClimbingSession links one of the user's analyses to one of the user's sessions.
// The link is held by the video of the analysis: every analysis of that video moves to the
// session, and an analysis already in another session is moved.
func (s *ClimbingSessionService) AddAnalysisToClimbingSession(ctx context.Context, id uuid.UUID, analysisID uuid.UUID, userID uuid.UUID) error {
	return s.sessionR.WithTransaction(ctx, func(ctx context.Context) error {
		session, err := s.sessionR.GetClimbingSessionByFilter(ctx, model.ClimbingSessionFilter{ID: &id, UserID: &userID})
		if err != nil {
			return climbingSessionNotFound(err)
		}

		analysis, err := s.analysisR.GetAnalysisByFilter(ctx, model.AnalysisFilter{ID: &analysisID})
		if err != nil {
			return analysisNotFound(err)
		}

		video, err := s.videoR.GetVideoByFilter(ctx, model.VideoFilter{ID: &analysis.VideoID, UserID: &userID})
		if err != nil {
			// The analysis belongs to another user's video.
			return analysisNotFound(err)
		}

		if video.ClimbingSessionID != nil && *video.ClimbingSessionID == session.ID {
			return nil
		}

		sessionID := &session.ID
		_, err = s.videoR.UpdateVideo(ctx, model.VideoPartial{ID: video.ID, UserID: userID, ClimbingSessionID: &sessionID})
		return err
	})
}

// UpdateClimbingSession changes the title, the notes or the end time of one of the user's
// climbing sessions. An empty partial returns the session unchanged.
func (s *ClimbingSessionService) UpdateClimbingSession(ctx context.Context, partial model.ClimbingSessionPartial) (model.ClimbingSession, error) {
	session, err := s.sessionR.GetClimbingSessionByFilter(ctx, model.ClimbingSessionFilter{ID: &partial.ID, UserID: &partial.UserID})
	if err != nil {
		return model.ClimbingSession{}, climbingSessionNotFound(err)
	}

	if partial.IsEmpty() {
		return session, nil
	}

	if err := partial.Validate(session); err != nil {
		return model.ClimbingSession{}, err
	}

	updated, err := s.sessionR.UpdateClimbingSession(ctx, partial)
	if err != nil {
		return model.ClimbingSession{}, climbingSessionNotFound(err)
	}

	return updated, nil
}

// DeleteClimbingSession deletes one of the user's climbing sessions. Its videos, and so
// their analyses, are kept and no longer linked to a session.
func (s *ClimbingSessionService) DeleteClimbingSession(ctx context.Context, id uuid.UUID, userID uuid.UUID) error {
	return climbingSessionNotFound(s.sessionR.DeleteClimbingSession(ctx, id, userID))
}

// climbingSessionNotFound turns the repository's generic model.ErrNotFound into model.ErrClimbingSessionNotFound.
func climbingSessionNotFound(err error) error {
	if errors.Is(err, model.ErrNotFound) {
		return model.ErrClimbingSessionNotFound
	}

	return err
}

// analysisNotFound turns the repository's generic model.ErrNotFound into model.ErrAnalysisNotFound.
func analysisNotFound(err error) error {
	if errors.Is(err, model.ErrNotFound) {
		return model.ErrAnalysisNotFound
	}

	return err
}
