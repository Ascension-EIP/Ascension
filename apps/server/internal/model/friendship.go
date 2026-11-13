// @date 2026-11-13
// @file friendship.go
// @brief Friendship domain types: friend requests, friends and the user search.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"fmt"
	"regexp"
	"strings"
	"time"

	"uuid"
)

const (
	UserSearchQueryMinLen = 2
	UserSearchQueryMaxLen = 30
)

// userSearchQueryPattern holds the characters a username can contain.
var userSearchQueryPattern = regexp.MustCompile(`^[a-z0-9_]+$`)

// FriendshipStatus mirrors the friendship_status enum.
type FriendshipStatus string

const (
	FriendshipPending  FriendshipStatus = "pending"
	FriendshipAccepted FriendshipStatus = "accepted"
	FriendshipBlocked  FriendshipStatus = "blocked"
)

// FriendRequestAnswer is the addressee's answer to a pending friend request.
type FriendRequestAnswer string

const (
	FriendRequestAccept  FriendRequestAnswer = "accept"
	FriendRequestDecline FriendRequestAnswer = "decline"
)

// Validate checks the answer is accept or decline.
func (a FriendRequestAnswer) Validate() error {
	switch a {
	case FriendRequestAccept, FriendRequestDecline:
		return nil
	default:
		return fmt.Errorf("%w: action: unknown", ErrInvalidInput)
	}
}

// UserRelation is what links the viewer to another user.
type UserRelation string

const (
	UserRelationNone            UserRelation = "none"
	UserRelationFriends         UserRelation = "friends"
	UserRelationRequestSent     UserRelation = "request_sent"
	UserRelationRequestReceived UserRelation = "request_received"
)

// NewUserSearchQuery normalizes a username search: trimmed, lowercased, and made of the
// characters a username can contain.
func NewUserSearchQuery(raw string) (string, error) {
	query := strings.ToLower(strings.TrimSpace(raw))

	if err := validateStringLen(query, UserSearchQueryMinLen, UserSearchQueryMaxLen); err != nil {
		return "", fmt.Errorf("%w: q: %w", ErrInvalidInput, err)
	}
	if !userSearchQueryPattern.MatchString(query) {
		return "", fmt.Errorf("%w: q: only letters, digits and underscores", ErrInvalidInput)
	}

	return query, nil
}

// -- Working type -- //

// Friendship mirrors a friendships row. There is one row per pair of users, whichever
// side sent the request.
type Friendship struct {
	ID          uuid.UUID
	RequesterID uuid.UUID
	AddresseeID uuid.UUID
	Status      FriendshipStatus
	RespondedAt *time.Time
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// RelationTo returns what the friendship means for viewerID. A blocked pair is never
// shown, so it has no relation.
func (f Friendship) RelationTo(viewerID uuid.UUID) UserRelation {
	switch {
	case f.Status == FriendshipAccepted:
		return UserRelationFriends
	case f.Status == FriendshipPending && f.RequesterID == viewerID:
		return UserRelationRequestSent
	case f.Status == FriendshipPending:
		return UserRelationRequestReceived
	default:
		return UserRelationNone
	}
}

// -- Output type -- //

// UserCard is what any user can see of another one: the full name is kept for friends.
type UserCard struct {
	ID       uuid.UUID
	Username string
}

// FriendRequest is a pending request seen by one side: User is the other side.
type FriendRequest struct {
	ID        uuid.UUID
	User      UserCard
	CreatedAt time.Time
}

// FriendRequests holds the pending requests a user received and sent.
type FriendRequests struct {
	Incoming []FriendRequest
	Outgoing []FriendRequest
}

// Friend is an accepted friendship seen by one side.
type Friend struct {
	FriendshipID uuid.UUID
	User         UserCard
	FirstName    string
	LastName     string
	Since        time.Time
}

// FriendPage is one page of a user's friends.
type FriendPage struct {
	Friends    []Friend
	Total      int
	Pagination Pagination
}

// UserSearchResult is a user found by a search, with its relation to the viewer.
// FriendshipID is set when a request or a friendship links them.
type UserSearchResult struct {
	User         UserCard
	Relation     UserRelation
	FriendshipID *uuid.UUID
}

// UserSearchPage is one page of a user search.
type UserSearchPage struct {
	Users      []UserSearchResult
	Total      int
	Pagination Pagination
}
