// @date 2026-11-12
// @file climbing_session.go
// @brief HTTP response DTOs of the climbing session endpoints.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package response

import (
	"time"
	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

// ClimbingSession is a climbing session as returned by the API.
type ClimbingSession struct {
	ID             uuid.UUID        `json:"id"`
	GymID          *uuid.UUID       `json:"gym_id"`
	Title          *string          `json:"title"`
	StartedAt      time.Time        `json:"started_at"`
	EndedAt        *time.Time       `json:"ended_at"`
	OverallScore   *float64         `json:"overall_score"`
	TechniqueScore *float64         `json:"technique_score"`
	PowerScore     *float64         `json:"power_score"`
	EnduranceScore *float64         `json:"endurance_score"`
	ScoredAt       *time.Time       `json:"scored_at"`
	Notes          *string          `json:"notes"`
	Visibility     model.Visibility `json:"visibility"`
	CreatedAt      time.Time        `json:"created_at"`
	UpdatedAt      time.Time        `json:"updated_at"`
}

// AnalysisSummary is an analysis in a list. The full analysis, with its result, is read
// from GET /v1/analysis/:id. ClimbingSessionID is null outside any session.
type AnalysisSummary struct {
	ID                uuid.UUID          `json:"id"`
	VideoID           uuid.UUID          `json:"video_id"`
	ClimbingSessionID *uuid.UUID         `json:"climbing_session_id"`
	Type              model.AnalysisType `json:"type"`
	Status            model.JobStatus    `json:"status"`
	Visibility        model.Visibility   `json:"visibility"`
	Progress          int16              `json:"progress"`
	StartedAt         *time.Time         `json:"started_at"`
	CompletedAt       *time.Time         `json:"completed_at"`
	CreatedAt         time.Time          `json:"created_at"`
}

// ClimbingSessionDetails is a climbing session with its analyses (GET /v1/sessions/:id).
type ClimbingSessionDetails struct {
	ClimbingSession
	Analyses []AnalysisSummary `json:"analyses"`
}

// ClimbingSessionList is one page of climbing sessions (GET /v1/sessions).
type ClimbingSessionList struct {
	Sessions []ClimbingSession `json:"sessions"`
	Total    int               `json:"total"`
	Limit    int               `json:"limit"`
	Offset   int               `json:"offset"`
}

// AnalysisSummaryList is one page of analyses (GET /v1/analysis).
type AnalysisSummaryList struct {
	Analyses []AnalysisSummary `json:"analyses"`
	Total    int               `json:"total"`
	Limit    int               `json:"limit"`
	Offset   int               `json:"offset"`
}

// ClimbingSessionToResponse converts a climbing session.
func ClimbingSessionToResponse(session model.ClimbingSession) ClimbingSession {
	return ClimbingSession{
		ID:             session.ID,
		GymID:          session.GymID,
		Title:          session.Title,
		StartedAt:      session.StartedAt,
		EndedAt:        session.EndedAt,
		OverallScore:   session.OverallScore,
		TechniqueScore: session.TechniqueScore,
		PowerScore:     session.PowerScore,
		EnduranceScore: session.EnduranceScore,
		ScoredAt:       session.ScoredAt,
		Notes:          session.Notes,
		Visibility:     session.Visibility,
		CreatedAt:      session.CreatedAt,
		UpdatedAt:      session.UpdatedAt,
	}
}

// ClimbingSessionDetailsToResponse converts a climbing session with its analyses.
func ClimbingSessionDetailsToResponse(details model.ClimbingSessionDetails) ClimbingSessionDetails {
	return ClimbingSessionDetails{
		ClimbingSession: ClimbingSessionToResponse(details.Session),
		Analyses:        analysisSummariesToResponse(details.Analyses),
	}
}

// AnalysisSummaryPageToResponse converts a page of analyses.
func AnalysisSummaryPageToResponse(page model.AnalysisSummaryPage) AnalysisSummaryList {
	return AnalysisSummaryList{
		Analyses: analysisSummariesToResponse(page.Analyses),
		Total:    page.Total,
		Limit:    page.Pagination.Limit,
		Offset:   page.Pagination.Offset,
	}
}

func analysisSummariesToResponse(summaries []model.AnalysisSummary) []AnalysisSummary {
	analyses := make([]AnalysisSummary, 0, len(summaries))
	for _, analysis := range summaries {
		analyses = append(analyses, AnalysisSummary{
			ID:                analysis.ID,
			VideoID:           analysis.VideoID,
			ClimbingSessionID: analysis.ClimbingSessionID,
			Type:              analysis.Type,
			Status:            analysis.Status,
			Visibility:        analysis.Visibility,
			Progress:          analysis.Progress,
			StartedAt:         analysis.StartedAt,
			CompletedAt:       analysis.CompletedAt,
			CreatedAt:         analysis.CreatedAt,
		})
	}

	return analyses
}

// ClimbingSessionPageToResponse converts a page of climbing sessions.
func ClimbingSessionPageToResponse(page model.ClimbingSessionPage) ClimbingSessionList {
	sessions := make([]ClimbingSession, 0, len(page.Sessions))
	for _, session := range page.Sessions {
		sessions = append(sessions, ClimbingSessionToResponse(session))
	}

	return ClimbingSessionList{
		Sessions: sessions,
		Total:    page.Total,
		Limit:    page.Pagination.Limit,
		Offset:   page.Pagination.Offset,
	}
}
