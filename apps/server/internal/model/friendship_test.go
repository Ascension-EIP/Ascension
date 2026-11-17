// @date 2026-11-13
// @file friendship_test.go
// @brief Unit tests of the friendship and feed domain rules.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"errors"
	"testing"

	"uuid"
)

func TestNewUserSearchQuery(t *testing.T) {
	for _, tc := range []struct {
		raw  string
		want string
	}{
		{"ab", "ab"},
		{"  Lou_P  ", "lou_p"},
		{"CLIMBER42", "climber42"},
		{"abcdefghijklmnopqrstuvwxyz0123", "abcdefghijklmnopqrstuvwxyz0123"},
	} {
		got, err := NewUserSearchQuery(tc.raw)
		if err != nil || got != tc.want {
			t.Errorf("NewUserSearchQuery(%q) = %q, %v, want %q", tc.raw, got, err, tc.want)
		}
	}

	for _, raw := range []string{"", " ", "a", "  a  ", "lou pellegrino", "lou%", "o'neil", "abcdefghijklmnopqrstuvwxyz01234"} {
		if _, err := NewUserSearchQuery(raw); !errors.Is(err, ErrInvalidInput) {
			t.Errorf("NewUserSearchQuery(%q) error = %v, want ErrInvalidInput", raw, err)
		}
	}
}

func TestFriendshipRelationTo(t *testing.T) {
	requester, addressee := uuid.NewV7(), uuid.NewV7()

	for _, tc := range []struct {
		status FriendshipStatus
		viewer uuid.UUID
		want   UserRelation
	}{
		{FriendshipPending, requester, UserRelationRequestSent},
		{FriendshipPending, addressee, UserRelationRequestReceived},
		{FriendshipAccepted, requester, UserRelationFriends},
		{FriendshipAccepted, addressee, UserRelationFriends},
		{FriendshipBlocked, requester, UserRelationNone},
	} {
		f := Friendship{RequesterID: requester, AddresseeID: addressee, Status: tc.status}
		if got := f.RelationTo(tc.viewer); got != tc.want {
			t.Errorf("RelationTo(%s, requester %v) = %s, want %s", tc.status, tc.viewer == requester, got, tc.want)
		}
	}
}

func TestFriendRequestAnswerAndFeedScopeValidate(t *testing.T) {
	for _, answer := range []FriendRequestAnswer{FriendRequestAccept, FriendRequestDecline} {
		if err := answer.Validate(); err != nil {
			t.Errorf("FriendRequestAnswer(%q).Validate() = %v", answer, err)
		}
	}
	for _, answer := range []FriendRequestAnswer{"", "accepted", "block"} {
		if err := answer.Validate(); !errors.Is(err, ErrInvalidInput) {
			t.Errorf("FriendRequestAnswer(%q).Validate() = %v, want ErrInvalidInput", answer, err)
		}
	}

	for _, scope := range []FeedScope{FeedScopeAll, FeedScopeFriends} {
		if err := scope.Validate(); err != nil {
			t.Errorf("FeedScope(%q).Validate() = %v", scope, err)
		}
	}
	for _, scope := range []FeedScope{"", "public", "private"} {
		if err := scope.Validate(); !errors.Is(err, ErrInvalidInput) {
			t.Errorf("FeedScope(%q).Validate() = %v, want ErrInvalidInput", scope, err)
		}
	}
}
