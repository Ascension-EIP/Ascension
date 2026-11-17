// @date 2026-11-13
// @file feed.go
// @brief Social feed: the climbing sessions other users share with the viewer (F11).
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

// FeedService reads the feed of the calling user.
type FeedService struct {
	repo model.FeedRepository
}

// NewFeedService builds a FeedService.
func NewFeedService(repo model.FeedRepository) FeedService {
	return FeedService{repo: repo}
}

// GetFeed returns one page of the sessions shared with the viewer in the scope, most
// recent first: a private session never appears, a friends-only one only to friends.
func (s *FeedService) GetFeed(ctx context.Context, viewerID uuid.UUID, scope model.FeedScope, pagination model.Pagination) (model.FeedPage, error) {
	if err := scope.Validate(); err != nil {
		return model.FeedPage{}, err
	}

	items, total, err := s.repo.ListFeed(ctx, viewerID, scope, pagination)
	if err != nil {
		return model.FeedPage{}, err
	}

	return model.FeedPage{Items: items, Total: total, Pagination: pagination}, nil
}
