// @date 2026-11-13
// @file friendship.go
// @brief Rows of the friendships table and of the friend, user search and feed queries.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

// Friendship is a friendships row.
type Friendship struct {
	ID          uuid.UUID              `db:"id"`
	RequesterID uuid.UUID              `db:"requester_id"`
	AddresseeID uuid.UUID              `db:"addressee_id"`
	Status      model.FriendshipStatus `db:"status"`
	RespondedAt *time.Time             `db:"responded_at"`
	CreatedAt   time.Time              `db:"created_at"`
	UpdatedAt   time.Time              `db:"updated_at"`
}

// ToFriendship converts the row to the domain model.
func (f Friendship) ToFriendship() model.Friendship {
	return model.Friendship{
		ID:          f.ID,
		RequesterID: f.RequesterID,
		AddresseeID: f.AddresseeID,
		Status:      f.Status,
		RespondedAt: f.RespondedAt,
		CreatedAt:   f.CreatedAt,
		UpdatedAt:   f.UpdatedAt,
	}
}

// FriendRequest is a pending request with the other side of the pair.
type FriendRequest struct {
	ID          uuid.UUID `db:"id"`
	RequesterID uuid.UUID `db:"requester_id"`
	CreatedAt   time.Time `db:"created_at"`
	UserID      uuid.UUID `db:"user_id"`
	Username    string    `db:"username"`
}

// ToFriendRequest converts the row to the domain model.
func (r FriendRequest) ToFriendRequest() model.FriendRequest {
	return model.FriendRequest{
		ID:        r.ID,
		User:      model.UserCard{ID: r.UserID, Username: r.Username},
		CreatedAt: r.CreatedAt,
	}
}

// Friend is an accepted friendship with the other side of the pair.
type Friend struct {
	FriendshipID uuid.UUID `db:"friendship_id"`
	Since        time.Time `db:"since"`
	UserID       uuid.UUID `db:"user_id"`
	Username     string    `db:"username"`
	FirstName    string    `db:"first_name"`
	LastName     string    `db:"last_name"`
}

// FriendsToFriends converts rows to domain models.
func FriendsToFriends(rows []Friend) []model.Friend {
	friends := make([]model.Friend, 0, len(rows))
	for _, row := range rows {
		friends = append(friends, model.Friend{
			FriendshipID: row.FriendshipID,
			User:         model.UserCard{ID: row.UserID, Username: row.Username},
			FirstName:    row.FirstName,
			LastName:     row.LastName,
			Since:        row.Since,
		})
	}

	return friends
}

// UserSearchResult is a user found by a search, with the friendship of the pair if any.
type UserSearchResult struct {
	UserID           uuid.UUID               `db:"user_id"`
	Username         string                  `db:"username"`
	FriendshipID     *uuid.UUID              `db:"friendship_id"`
	FriendshipStatus *model.FriendshipStatus `db:"friendship_status"`
	RequesterID      *uuid.UUID              `db:"requester_id"`
}

// UserSearchResultsToUserSearchResults converts rows to domain models seen by viewerID.
func UserSearchResultsToUserSearchResults(rows []UserSearchResult, viewerID uuid.UUID) []model.UserSearchResult {
	results := make([]model.UserSearchResult, 0, len(rows))
	for _, row := range rows {
		result := model.UserSearchResult{
			User:     model.UserCard{ID: row.UserID, Username: row.Username},
			Relation: model.UserRelationNone,
		}
		if row.FriendshipID != nil && row.FriendshipStatus != nil && row.RequesterID != nil {
			friendship := model.Friendship{ID: *row.FriendshipID, RequesterID: *row.RequesterID, Status: *row.FriendshipStatus}
			result.Relation = friendship.RelationTo(viewerID)
			result.FriendshipID = row.FriendshipID
		}
		results = append(results, result)
	}

	return results
}

// FeedItem is a climbing_sessions row with the username of its author.
type FeedItem struct {
	ClimbingSession
	AuthorUsername string `db:"author_username"`
}

// FeedItemsToFeedItems converts rows to domain models.
func FeedItemsToFeedItems(rows []FeedItem) []model.FeedItem {
	items := make([]model.FeedItem, 0, len(rows))
	for _, row := range rows {
		items = append(items, model.FeedItem{
			Session: row.ToClimbingSession(),
			Author:  model.UserCard{ID: row.UserID, Username: row.AuthorUsername},
		})
	}

	return items
}
