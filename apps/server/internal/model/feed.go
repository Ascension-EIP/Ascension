// @date 2026-11-13
// @file feed.go
// @brief Social feed domain types: the climbing sessions other users share with the viewer.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import "fmt"

// FeedScope selects whose sessions the feed shows.
type FeedScope string

const (
	// FeedScopeAll shows the public sessions of everyone and the sessions friends share.
	FeedScopeAll FeedScope = "all"
	// FeedScopeFriends shows only the sessions friends share, public or friends-only.
	FeedScopeFriends FeedScope = "friends"
)

// Validate checks the scope is all or friends.
func (s FeedScope) Validate() error {
	switch s {
	case FeedScopeAll, FeedScopeFriends:
		return nil
	default:
		return fmt.Errorf("%w: scope: unknown", ErrInvalidInput)
	}
}

// FeedItem is a climbing session shared with the viewer, with its author.
type FeedItem struct {
	Session ClimbingSession
	Author  UserCard
}

// FeedPage is one page of the feed.
type FeedPage struct {
	Items      []FeedItem
	Total      int
	Pagination Pagination
}
