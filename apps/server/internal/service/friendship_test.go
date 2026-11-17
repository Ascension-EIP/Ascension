// @date 2026-11-13
// @file friendship_test.go
// @brief Unit tests of the friendship and feed services.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

var firstPage = model.Pagination{Limit: model.PaginationDefaultLimit}

func mustSendFriendRequest(t *testing.T, s FriendshipService, requesterID uuid.UUID, addresseeID uuid.UUID) model.Friendship {
	t.Helper()

	friendship, err := s.SendFriendRequest(context.Background(), requesterID, addresseeID)
	if err != nil {
		t.Fatalf("SendFriendRequest() error = %v", err)
	}

	return friendship
}

func TestFriendRequestLifecycle(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewFriendshipService(repo)
	alice, bob := repo.AddUser("alice"), repo.AddUser("bob")

	request := mustSendFriendRequest(t, s, alice, bob)
	if request.RequesterID != alice || request.AddresseeID != bob || request.Status != model.FriendshipPending || request.RespondedAt != nil {
		t.Fatalf("request = %+v", request)
	}

	// The pair has one friendship, whichever side asks.
	if _, err := s.SendFriendRequest(ctx, alice, bob); !errors.Is(err, model.ErrFriendshipExists) {
		t.Errorf("second request error = %v, want ErrFriendshipExists", err)
	}
	if _, err := s.SendFriendRequest(ctx, bob, alice); !errors.Is(err, model.ErrFriendshipExists) {
		t.Errorf("reverse request error = %v, want ErrFriendshipExists", err)
	}

	aliceRequests, _ := s.ListFriendRequests(ctx, alice)
	bobRequests, _ := s.ListFriendRequests(ctx, bob)
	if len(aliceRequests.Outgoing) != 1 || len(aliceRequests.Incoming) != 0 || aliceRequests.Outgoing[0].User.Username != "bob" {
		t.Errorf("alice's requests = %+v, want one outgoing to bob", aliceRequests)
	}
	if len(bobRequests.Incoming) != 1 || len(bobRequests.Outgoing) != 0 || bobRequests.Incoming[0].ID != request.ID || bobRequests.Incoming[0].User.Username != "alice" {
		t.Errorf("bob's requests = %+v, want one incoming from alice", bobRequests)
	}

	// Only the addressee answers.
	if _, err := s.AcceptFriendRequest(ctx, request.ID, alice); !errors.Is(err, model.ErrFriendRequestNotFound) {
		t.Errorf("AcceptFriendRequest(by the requester) error = %v, want ErrFriendRequestNotFound", err)
	}
	accepted, err := s.AcceptFriendRequest(ctx, request.ID, bob)
	if err != nil || accepted.Status != model.FriendshipAccepted || accepted.RespondedAt == nil {
		t.Fatalf("AcceptFriendRequest() = %+v, %v", accepted, err)
	}
	if _, err := s.AcceptFriendRequest(ctx, request.ID, bob); !errors.Is(err, model.ErrFriendRequestNotFound) {
		t.Errorf("AcceptFriendRequest(accepted) error = %v, want ErrFriendRequestNotFound", err)
	}
	if _, err := s.SendFriendRequest(ctx, bob, alice); !errors.Is(err, model.ErrFriendshipExists) {
		t.Errorf("request between friends error = %v, want ErrFriendshipExists", err)
	}

	// Both sides see the friendship, and no pending request is left.
	for user, friend := range map[uuid.UUID]string{alice: "bob", bob: "alice"} {
		page, err := s.ListFriends(ctx, user, firstPage)
		if err != nil || page.Total != 1 || len(page.Friends) != 1 || page.Friends[0].User.Username != friend ||
			page.Friends[0].FriendshipID != request.ID || page.Friends[0].FirstName != "First "+friend {
			t.Errorf("ListFriends() = %+v, %v, want %s", page, err, friend)
		}
		if requests, _ := s.ListFriendRequests(ctx, user); len(requests.Incoming)+len(requests.Outgoing) != 0 {
			t.Errorf("requests after acceptance = %+v, want none", requests)
		}
	}
}

func TestDeclineFriendRequestDeletesIt(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewFriendshipService(repo)
	alice, bob := repo.AddUser("alice"), repo.AddUser("bob")
	request := mustSendFriendRequest(t, s, alice, bob)

	if err := s.DeclineFriendRequest(ctx, request.ID, alice); !errors.Is(err, model.ErrFriendRequestNotFound) {
		t.Errorf("DeclineFriendRequest(by the requester) error = %v, want ErrFriendRequestNotFound", err)
	}
	if err := s.DeclineFriendRequest(ctx, request.ID, bob); err != nil {
		t.Fatalf("DeclineFriendRequest() error = %v", err)
	}
	if err := s.DeclineFriendRequest(ctx, request.ID, bob); !errors.Is(err, model.ErrFriendRequestNotFound) {
		t.Errorf("DeclineFriendRequest(declined) error = %v, want ErrFriendRequestNotFound", err)
	}
	if page, _ := s.ListFriends(ctx, bob, firstPage); page.Total != 0 {
		t.Errorf("friends after a decline = %+v, want none", page)
	}

	// Nothing is left of the declined request: either side can ask again.
	if again := mustSendFriendRequest(t, s, bob, alice); again.ID == request.ID {
		t.Errorf("new request = %+v, want a new row", again)
	}
}

func TestSendFriendRequestRejections(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewFriendshipService(repo)
	alice, bob, carol, gone := repo.AddUser("alice"), repo.AddUser("bob"), repo.AddUser("carol"), repo.AddUser("gone")
	repo.DeactivateUser(gone)
	repo.BlockPair(bob, alice)
	repo.BlockPair(alice, carol)

	if _, err := s.SendFriendRequest(ctx, alice, alice); !errors.Is(err, model.ErrInvalidInput) {
		t.Errorf("request to self error = %v, want ErrInvalidInput", err)
	}
	for name, addressee := range map[string]uuid.UUID{
		"unknown user":        uuid.NewV7(),
		"deactivated user":    gone,
		"user who blocked me": bob,
		"user I have blocked": carol,
	} {
		if _, err := s.SendFriendRequest(ctx, alice, addressee); !errors.Is(err, model.ErrUserNotFound) {
			t.Errorf("request to a %s error = %v, want ErrUserNotFound", name, err)
		}
	}
}

func TestSearchUsers(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewFriendshipService(repo)
	viewer := repo.AddUser("climb")
	exact := repo.AddUser("lou")
	prefix := repo.AddUser("lou_p")
	inner := repo.AddUser("big_lou")
	friend := repo.AddUser("loubna")
	asker := repo.AddUser("louis")
	gone := repo.AddUser("lou_gone")
	blocked := repo.AddUser("lou_blocked")
	repo.AddUser("nicolas")
	repo.DeactivateUser(gone)
	repo.BlockPair(blocked, viewer)

	sent := mustSendFriendRequest(t, s, viewer, prefix)
	received := mustSendFriendRequest(t, s, asker, viewer)
	friendship := mustSendFriendRequest(t, s, friend, viewer)
	if _, err := s.AcceptFriendRequest(ctx, friendship.ID, viewer); err != nil {
		t.Fatalf("AcceptFriendRequest() error = %v", err)
	}

	page, err := s.SearchUsers(ctx, viewer, "  LOU ", firstPage)
	if err != nil {
		t.Fatalf("SearchUsers() error = %v", err)
	}
	want := []struct {
		id           uuid.UUID
		relation     model.UserRelation
		friendshipID *uuid.UUID
	}{
		// The exact match, then the prefixes in byte order ("_" sorts before letters), then the rest.
		{exact, model.UserRelationNone, nil},
		{prefix, model.UserRelationRequestSent, &sent.ID},
		{friend, model.UserRelationFriends, &friendship.ID},
		{asker, model.UserRelationRequestReceived, &received.ID},
		{inner, model.UserRelationNone, nil},
	}
	if page.Total != len(want) || len(page.Users) != len(want) {
		t.Fatalf("SearchUsers() = %+v, want %d users", page, len(want))
	}
	for i, w := range want {
		got := page.Users[i]
		if got.User.ID != w.id || got.Relation != w.relation || (w.friendshipID == nil) != (got.FriendshipID == nil) ||
			(w.friendshipID != nil && *got.FriendshipID != *w.friendshipID) {
			t.Errorf("result %d = %+v (%s), want user %v with relation %s", i, got, got.User.Username, w.id, w.relation)
		}
	}

	second, err := s.SearchUsers(ctx, viewer, "lou", model.Pagination{Limit: 2, Offset: 4})
	if err != nil || second.Total != 5 || len(second.Users) != 1 || second.Users[0].User.ID != inner {
		t.Errorf("second page = %+v, %v, want big_lou only", second, err)
	}

	for _, query := range []string{"", "l", "lou pellegrino", "lou%"} {
		if _, err := s.SearchUsers(ctx, viewer, query, firstPage); !errors.Is(err, model.ErrInvalidInput) {
			t.Errorf("SearchUsers(%q) error = %v, want ErrInvalidInput", query, err)
		}
	}
}

func TestFeedVisibility(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	friendships := NewFriendshipService(repo)
	feed := NewFeedService(repo)
	viewer, friend, stranger, blocker, gone := repo.AddUser("viewer"), repo.AddUser("friend"), repo.AddUser("stranger"), repo.AddUser("blocker"), repo.AddUser("gone")

	request := mustSendFriendRequest(t, friendships, viewer, friend)
	if _, err := friendships.AcceptFriendRequest(ctx, request.ID, friend); err != nil {
		t.Fatalf("AcceptFriendRequest() error = %v", err)
	}
	// A pending request does not share friends-only sessions.
	mustSendFriendRequest(t, friendships, stranger, viewer)
	repo.BlockPair(blocker, viewer)

	day := time.Date(2026, 11, 1, 10, 0, 0, 0, time.UTC)
	newSession := func(userID uuid.UUID, visibility model.Visibility, daysAgo int) uuid.UUID {
		session, err := repo.CreateClimbingSession(ctx, model.ClimbingSession{UserID: userID, StartedAt: day.AddDate(0, 0, -daysAgo), Visibility: visibility})
		if err != nil {
			t.Fatalf("CreateClimbingSession() error = %v", err)
		}
		return session.ID
	}
	friendPublic := newSession(friend, model.VisibilityPublic, 1)
	friendFriends := newSession(friend, model.VisibilityFriends, 3)
	newSession(friend, model.VisibilityPrivate, 0)
	strangerPublic := newSession(stranger, model.VisibilityPublic, 2)
	newSession(stranger, model.VisibilityFriends, 0)
	newSession(blocker, model.VisibilityPublic, 0)
	newSession(gone, model.VisibilityPublic, 0)
	newSession(viewer, model.VisibilityPublic, 0)
	repo.DeactivateUser(gone)

	for scope, want := range map[model.FeedScope][]uuid.UUID{
		model.FeedScopeAll:     {friendPublic, strangerPublic, friendFriends},
		model.FeedScopeFriends: {friendPublic, friendFriends},
	} {
		page, err := feed.GetFeed(ctx, viewer, scope, firstPage)
		if err != nil || page.Total != len(want) || len(page.Items) != len(want) {
			t.Fatalf("GetFeed(%s) = %+v, %v, want %d sessions", scope, page, err, len(want))
		}
		for i, id := range want {
			if page.Items[i].Session.ID != id {
				t.Errorf("GetFeed(%s)[%d] = %v by %s, want %v", scope, i, page.Items[i].Session.ID, page.Items[i].Author.Username, id)
			}
		}
	}

	// The friend sees the viewer's public session, not the viewer's own feed.
	if page, _ := feed.GetFeed(ctx, friend, model.FeedScopeFriends, firstPage); page.Total != 1 || page.Items[0].Author.ID != viewer {
		t.Errorf("friend's feed = %+v, want the viewer's public session", page)
	}

	if _, err := feed.GetFeed(ctx, viewer, "public", firstPage); !errors.Is(err, model.ErrInvalidInput) {
		t.Errorf("GetFeed(unknown scope) error = %v, want ErrInvalidInput", err)
	}
}
