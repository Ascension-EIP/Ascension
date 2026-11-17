// @date 2026-11-13
// @file friendship.go
// @brief Friend requests, friends and the user search of the community features (F11).
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"errors"
	"fmt"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

// FriendshipService manages the friendships of the calling user. A blocked pair is
// reported as model.ErrUserNotFound, so a blocked user cannot tell they were blocked.
type FriendshipService struct {
	repo model.FriendshipRepository
}

// NewFriendshipService builds a FriendshipService.
func NewFriendshipService(repo model.FriendshipRepository) FriendshipService {
	return FriendshipService{repo: repo}
}

// SendFriendRequest sends a friend request from requesterID to addresseeID.
func (s *FriendshipService) SendFriendRequest(ctx context.Context, requesterID uuid.UUID, addresseeID uuid.UUID) (model.Friendship, error) {
	if requesterID == addresseeID {
		return model.Friendship{}, fmt.Errorf("%w: cannot send a friend request to yourself", model.ErrInvalidInput)
	}

	friendship, err := s.repo.CreateFriendRequest(ctx, requesterID, addresseeID)
	if errors.Is(err, model.ErrNotFound) {
		return model.Friendship{}, s.whyNotCreated(ctx, requesterID, addresseeID)
	}

	return friendship, err
}

// whyNotCreated tells why no request was inserted: the pair already has a friendship, or
// the addressee is not an active user.
func (s *FriendshipService) whyNotCreated(ctx context.Context, requesterID uuid.UUID, addresseeID uuid.UUID) error {
	existing, err := s.repo.GetFriendshipBetween(ctx, requesterID, addresseeID)
	if errors.Is(err, model.ErrNotFound) {
		return model.ErrUserNotFound
	}
	if err != nil {
		return err
	}

	switch existing.RelationTo(requesterID) {
	case model.UserRelationFriends:
		return fmt.Errorf("%w: already friends", model.ErrFriendshipExists)
	case model.UserRelationRequestSent:
		return fmt.Errorf("%w: friend request already sent", model.ErrFriendshipExists)
	case model.UserRelationRequestReceived:
		return fmt.Errorf("%w: friend request already received, accept it instead", model.ErrFriendshipExists)
	default:
		return model.ErrUserNotFound
	}
}

// ListFriendRequests returns the pending requests the user received and sent.
func (s *FriendshipService) ListFriendRequests(ctx context.Context, userID uuid.UUID) (model.FriendRequests, error) {
	return s.repo.ListFriendRequests(ctx, userID)
}

// AcceptFriendRequest accepts a pending request addressed to the user.
func (s *FriendshipService) AcceptFriendRequest(ctx context.Context, id uuid.UUID, userID uuid.UUID) (model.Friendship, error) {
	friendship, err := s.repo.AcceptFriendRequest(ctx, id, userID)
	if err != nil {
		return model.Friendship{}, friendRequestNotFound(err)
	}

	return friendship, nil
}

// DeclineFriendRequest declines a pending request addressed to the user: the request is
// deleted, so the requester can ask again later.
func (s *FriendshipService) DeclineFriendRequest(ctx context.Context, id uuid.UUID, userID uuid.UUID) error {
	return friendRequestNotFound(s.repo.DeleteFriendRequest(ctx, id, userID))
}

// ListFriends returns one page of the user's friends.
func (s *FriendshipService) ListFriends(ctx context.Context, userID uuid.UUID, pagination model.Pagination) (model.FriendPage, error) {
	friends, total, err := s.repo.ListFriends(ctx, userID, pagination)
	if err != nil {
		return model.FriendPage{}, err
	}

	return model.FriendPage{Friends: friends, Total: total, Pagination: pagination}, nil
}

// SearchUsers returns one page of the users whose username contains the query, with their
// relation to the viewer.
func (s *FriendshipService) SearchUsers(ctx context.Context, viewerID uuid.UUID, rawQuery string, pagination model.Pagination) (model.UserSearchPage, error) {
	query, err := model.NewUserSearchQuery(rawQuery)
	if err != nil {
		return model.UserSearchPage{}, err
	}

	users, total, err := s.repo.SearchUsers(ctx, viewerID, query, pagination)
	if err != nil {
		return model.UserSearchPage{}, err
	}

	return model.UserSearchPage{Users: users, Total: total, Pagination: pagination}, nil
}

// friendRequestNotFound turns the repository's generic model.ErrNotFound into
// model.ErrFriendRequestNotFound.
func friendRequestNotFound(err error) error {
	if errors.Is(err, model.ErrNotFound) {
		return model.ErrFriendRequestNotFound
	}

	return err
}
