// @date 2026-11-13
// @file friendship.go
// @brief HTTP response DTOs of the friendship and user search endpoints.
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

// UserCard is what any user can see of another one.
type UserCard struct {
	ID       uuid.UUID `json:"id"`
	Username string    `json:"username"`
}

// Friendship is a friend request or a friendship as returned by the API.
type Friendship struct {
	ID          uuid.UUID              `json:"id"`
	RequesterID uuid.UUID              `json:"requester_id"`
	AddresseeID uuid.UUID              `json:"addressee_id"`
	Status      model.FriendshipStatus `json:"status"`
	RespondedAt *time.Time             `json:"responded_at"`
	CreatedAt   time.Time              `json:"created_at"`
}

// FriendRequest is a pending request: User is the other side.
type FriendRequest struct {
	ID        uuid.UUID `json:"id"`
	User      UserCard  `json:"user"`
	CreatedAt time.Time `json:"created_at"`
}

// FriendRequests holds the pending requests received and sent (GET /v1/friends/requests).
type FriendRequests struct {
	Incoming []FriendRequest `json:"incoming"`
	Outgoing []FriendRequest `json:"outgoing"`
}

// FriendUser is a friend: the full name is shown to friends only.
type FriendUser struct {
	ID        uuid.UUID `json:"id"`
	Username  string    `json:"username"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
}

// Friend is an accepted friendship.
type Friend struct {
	FriendshipID uuid.UUID  `json:"friendship_id"`
	User         FriendUser `json:"user"`
	Since        time.Time  `json:"since"`
}

// FriendList is one page of friends (GET /v1/friends).
type FriendList struct {
	Friends []Friend `json:"friends"`
	Total   int      `json:"total"`
	Limit   int      `json:"limit"`
	Offset  int      `json:"offset"`
}

// UserSearchResult is a user found by a search, with its relation to the caller.
type UserSearchResult struct {
	ID           uuid.UUID          `json:"id"`
	Username     string             `json:"username"`
	Relation     model.UserRelation `json:"relation"`
	FriendshipID *uuid.UUID         `json:"friendship_id"`
}

// UserSearchList is one page of a user search (GET /v1/users/search).
type UserSearchList struct {
	Users  []UserSearchResult `json:"users"`
	Total  int                `json:"total"`
	Limit  int                `json:"limit"`
	Offset int                `json:"offset"`
}

// FriendshipToResponse converts a friendship.
func FriendshipToResponse(friendship model.Friendship) Friendship {
	return Friendship{
		ID:          friendship.ID,
		RequesterID: friendship.RequesterID,
		AddresseeID: friendship.AddresseeID,
		Status:      friendship.Status,
		RespondedAt: friendship.RespondedAt,
		CreatedAt:   friendship.CreatedAt,
	}
}

// FriendRequestsToResponse converts the pending requests.
func FriendRequestsToResponse(requests model.FriendRequests) FriendRequests {
	return FriendRequests{
		Incoming: friendRequestsToResponse(requests.Incoming),
		Outgoing: friendRequestsToResponse(requests.Outgoing),
	}
}

// FriendPageToResponse converts a page of friends.
func FriendPageToResponse(page model.FriendPage) FriendList {
	friends := make([]Friend, 0, len(page.Friends))
	for _, friend := range page.Friends {
		friends = append(friends, Friend{
			FriendshipID: friend.FriendshipID,
			User: FriendUser{
				ID:        friend.User.ID,
				Username:  friend.User.Username,
				FirstName: friend.FirstName,
				LastName:  friend.LastName,
			},
			Since: friend.Since,
		})
	}

	return FriendList{Friends: friends, Total: page.Total, Limit: page.Pagination.Limit, Offset: page.Pagination.Offset}
}

// UserSearchPageToResponse converts a page of a user search.
func UserSearchPageToResponse(page model.UserSearchPage) UserSearchList {
	users := make([]UserSearchResult, 0, len(page.Users))
	for _, result := range page.Users {
		users = append(users, UserSearchResult{
			ID:           result.User.ID,
			Username:     result.User.Username,
			Relation:     result.Relation,
			FriendshipID: result.FriendshipID,
		})
	}

	return UserSearchList{Users: users, Total: page.Total, Limit: page.Pagination.Limit, Offset: page.Pagination.Offset}
}

func friendRequestsToResponse(requests []model.FriendRequest) []FriendRequest {
	converted := make([]FriendRequest, 0, len(requests))
	for _, request := range requests {
		converted = append(converted, FriendRequest{
			ID:        request.ID,
			User:      userCardToResponse(request.User),
			CreatedAt: request.CreatedAt,
		})
	}

	return converted
}

func userCardToResponse(card model.UserCard) UserCard {
	return UserCard{ID: card.ID, Username: card.Username}
}
