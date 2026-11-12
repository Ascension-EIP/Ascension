// @date 2026-11-13
// @file feed.go
// @brief HTTP response DTOs of the feed endpoint.
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

// FeedSession is a climbing session shared with the caller. The notes stay private to
// their author.
type FeedSession struct {
	ID             uuid.UUID        `json:"id"`
	Author         UserCard         `json:"author"`
	GymID          *uuid.UUID       `json:"gym_id"`
	Title          *string          `json:"title"`
	StartedAt      time.Time        `json:"started_at"`
	EndedAt        *time.Time       `json:"ended_at"`
	OverallScore   *float64         `json:"overall_score"`
	TechniqueScore *float64         `json:"technique_score"`
	PowerScore     *float64         `json:"power_score"`
	EnduranceScore *float64         `json:"endurance_score"`
	ScoredAt       *time.Time       `json:"scored_at"`
	Visibility     model.Visibility `json:"visibility"`
	CreatedAt      time.Time        `json:"created_at"`
}

// FeedList is one page of the feed (GET /v1/feed).
type FeedList struct {
	Sessions []FeedSession `json:"sessions"`
	Total    int           `json:"total"`
	Limit    int           `json:"limit"`
	Offset   int           `json:"offset"`
}

// FeedPageToResponse converts a page of the feed.
func FeedPageToResponse(page model.FeedPage) FeedList {
	sessions := make([]FeedSession, 0, len(page.Items))
	for _, item := range page.Items {
		session := item.Session
		sessions = append(sessions, FeedSession{
			ID:             session.ID,
			Author:         userCardToResponse(item.Author),
			GymID:          session.GymID,
			Title:          session.Title,
			StartedAt:      session.StartedAt,
			EndedAt:        session.EndedAt,
			OverallScore:   session.OverallScore,
			TechniqueScore: session.TechniqueScore,
			PowerScore:     session.PowerScore,
			EnduranceScore: session.EnduranceScore,
			ScoredAt:       session.ScoredAt,
			Visibility:     session.Visibility,
			CreatedAt:      session.CreatedAt,
		})
	}

	return FeedList{Sessions: sessions, Total: page.Total, Limit: page.Pagination.Limit, Offset: page.Pagination.Offset}
}
