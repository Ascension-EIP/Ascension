// @date 2026-11-13
// @file friendship_integration_test.go
// @brief Integration tests of the friendship and feed queries against PostgreSQL.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres_test

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/pgtest"
)

func TestConcurrentFriendRequestsOfAPairCreateOneRow(t *testing.T) {
	db := pgtest.Open(t)
	ctx := context.Background()
	alice, bob := db.CreateUserNamed(t, "alice"), db.CreateUserNamed(t, "bob")

	// Both sides ask at the same time, several times: the pair index keeps one row.
	var wg sync.WaitGroup
	var mu sync.Mutex
	created, refused := 0, 0
	for i := range 10 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			requester, addressee := alice, bob
			if i%2 == 1 {
				requester, addressee = bob, alice
			}
			_, err := db.Repo.CreateFriendRequest(ctx, requester, addressee)
			mu.Lock()
			defer mu.Unlock()
			switch {
			case err == nil:
				created++
			case errors.Is(err, model.ErrNotFound):
				refused++
			default:
				t.Errorf("CreateFriendRequest() error = %v", err)
			}
		}()
	}
	wg.Wait()

	if created != 1 || refused != 9 {
		t.Fatalf("created %d, refused %d, want 1 and 9", created, refused)
	}
	var rows int
	if err := db.Repo.Pool.QueryRow(ctx, "SELECT COUNT(*) FROM friendships").Scan(&rows); err != nil || rows != 1 {
		t.Fatalf("friendships rows = %d, %v, want 1", rows, err)
	}
	if _, err := db.Repo.GetFriendshipBetween(ctx, bob, alice); err != nil {
		t.Errorf("GetFriendshipBetween(reversed) error = %v", err)
	}
}

func TestFriendshipQueriesWithPostgres(t *testing.T) {
	db := pgtest.Open(t)
	ctx := context.Background()
	alice, bob := db.CreateUserNamed(t, "alice"), db.CreateUserNamed(t, "bob")
	page := model.Pagination{Limit: 20}

	// The not-self check of the table backs the service rule.
	if _, err := db.Repo.CreateFriendRequest(ctx, alice, alice); !errors.Is(err, model.ErrInvalidInput) {
		t.Errorf("CreateFriendRequest(self) error = %v, want ErrInvalidInput", err)
	}

	request, err := db.Repo.CreateFriendRequest(ctx, alice, bob)
	if err != nil || request.Status != model.FriendshipPending || request.RespondedAt != nil {
		t.Fatalf("CreateFriendRequest() = %+v, %v", request, err)
	}
	if err := db.Repo.DeleteFriendRequest(ctx, request.ID, alice); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("DeleteFriendRequest(by the requester) error = %v, want ErrNotFound", err)
	}

	accepted, err := db.Repo.AcceptFriendRequest(ctx, request.ID, bob)
	if err != nil || accepted.Status != model.FriendshipAccepted || accepted.RespondedAt == nil || !accepted.UpdatedAt.After(request.UpdatedAt) {
		t.Fatalf("AcceptFriendRequest() = %+v, %v", accepted, err)
	}
	// An accepted friendship is not a pending request any more.
	if err := db.Repo.DeleteFriendRequest(ctx, request.ID, bob); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("DeleteFriendRequest(accepted) error = %v, want ErrNotFound", err)
	}

	friends, total, err := db.Repo.ListFriends(ctx, alice, page)
	if err != nil || total != 1 || len(friends) != 1 || friends[0].User.Username != "bob" || friends[0].LastName != "Last bob" ||
		!friends[0].Since.Equal(*accepted.RespondedAt) {
		t.Fatalf("ListFriends() = %+v, %d, %v", friends, total, err)
	}

	// The LIKE wildcards of the query are escaped: "_" only matches an underscore.
	db.CreateUserNamed(t, "lou_p")
	db.CreateUserNamed(t, "loup")
	results, total, err := db.Repo.SearchUsers(ctx, alice, "u_p", page)
	if err != nil || total != 1 || len(results) != 1 || results[0].User.Username != "lou_p" {
		t.Errorf("SearchUsers(u_p) = %+v, %d, %v, want lou_p only", results, total, err)
	}

	// A deactivated friend leaves the list, and comes back with the account.
	db.DeactivateUser(t, bob)
	if _, total, _ := db.Repo.ListFriends(ctx, alice, page); total != 0 {
		t.Errorf("friends with bob deactivated = %d, want 0", total)
	}
}

func TestFeedQueryWithPostgres(t *testing.T) {
	db := pgtest.Open(t)
	ctx := context.Background()
	viewer, friend, stranger := db.CreateUserNamed(t, "viewer"), db.CreateUserNamed(t, "friend"), db.CreateUserNamed(t, "stranger")
	request, err := db.Repo.CreateFriendRequest(ctx, friend, viewer)
	if err != nil {
		t.Fatalf("CreateFriendRequest() error = %v", err)
	}
	if _, err := db.Repo.AcceptFriendRequest(ctx, request.ID, viewer); err != nil {
		t.Fatalf("AcceptFriendRequest() error = %v", err)
	}

	startedAt := time.Date(2026, 11, 1, 10, 0, 0, 0, time.UTC)
	newSession := func(userID uuid.UUID, visibility model.Visibility, hours int) model.ClimbingSession {
		title := string(visibility)
		session, err := db.Repo.CreateClimbingSession(ctx, model.ClimbingSession{UserID: userID, Title: &title, StartedAt: startedAt.Add(time.Duration(hours) * time.Hour), Visibility: visibility})
		if err != nil {
			t.Fatalf("CreateClimbingSession() error = %v", err)
		}
		return session
	}
	friendsOnly := newSession(friend, model.VisibilityFriends, 2)
	public := newSession(stranger, model.VisibilityPublic, 1)
	newSession(stranger, model.VisibilityFriends, 3)
	newSession(friend, model.VisibilityPrivate, 4)

	items, total, err := db.Repo.ListFeed(ctx, viewer, model.FeedScopeAll, model.Pagination{Limit: 1, Offset: 1})
	if err != nil || total != 2 || len(items) != 1 || items[0].Session.ID != public.ID || items[0].Author.Username != "stranger" ||
		items[0].Session.Title == nil || *items[0].Session.Title != "public" {
		t.Fatalf("ListFeed(all, second page) = %+v, %d, %v, want the stranger's public session", items, total, err)
	}
	items, total, err = db.Repo.ListFeed(ctx, viewer, model.FeedScopeFriends, model.Pagination{Limit: 20})
	if err != nil || total != 1 || items[0].Session.ID != friendsOnly.ID || items[0].Author.ID != friend {
		t.Fatalf("ListFeed(friends) = %+v, %d, %v, want the friend's friends-only session", items, total, err)
	}

	// A block hides even the public sessions.
	db.BlockPair(t, stranger, viewer)
	if _, total, _ := db.Repo.ListFeed(ctx, viewer, model.FeedScopeAll, model.Pagination{Limit: 20}); total != 1 {
		t.Errorf("feed with the stranger blocked = %d sessions, want 1", total)
	}
}
