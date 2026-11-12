// @date 2026-11-13
// @file friendship.go
// @brief In-memory users, friendships and feed, with the rules of the PostgreSQL queries.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package memrepo

import (
	"cmp"
	"context"
	"slices"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

// -- Fixtures -- //

// AddUser stores an active user with the username and returns its ID.
func (r *Repo) AddUser(username string) uuid.UUID {
	r.mu.Lock()
	defer r.mu.Unlock()

	user := model.User{
		ID:        uuid.NewV7(),
		Username:  model.UserUsername(username),
		FirstName: "First " + username,
		LastName:  "Last " + username,
		Status:    model.UserStatusActive,
	}
	r.users[user.ID] = user

	return user.ID
}

// DeactivateUser deactivates a stored user.
func (r *Repo) DeactivateUser(id uuid.UUID) {
	r.mu.Lock()
	defer r.mu.Unlock()

	user := r.users[id]
	user.Status = model.UserStatusDeactivated
	r.users[id] = user
}

// BlockPair stores a blocked friendship, replacing the one of the pair if any. No endpoint
// blocks a user yet: the tests set it directly.
func (r *Repo) BlockPair(requesterID uuid.UUID, addresseeID uuid.UUID) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if existing, ok := r.friendshipOfPair(requesterID, addresseeID); ok {
		delete(r.friendships, existing.ID)
	}
	now := r.now()
	friendship := model.Friendship{
		ID:          uuid.NewV7(),
		RequesterID: requesterID,
		AddresseeID: addresseeID,
		Status:      model.FriendshipBlocked,
		RespondedAt: &now,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	r.friendships[friendship.ID] = friendship
}

// -- Friendships -- //

func (r *Repo) CreateFriendRequest(_ context.Context, requesterID uuid.UUID, addresseeID uuid.UUID) (model.Friendship, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if !r.isActive(addresseeID) {
		return model.Friendship{}, model.ErrNotFound
	}
	if _, ok := r.friendshipOfPair(requesterID, addresseeID); ok {
		return model.Friendship{}, model.ErrNotFound
	}

	now := r.now()
	friendship := model.Friendship{
		ID:          uuid.NewV7(),
		RequesterID: requesterID,
		AddresseeID: addresseeID,
		Status:      model.FriendshipPending,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	r.friendships[friendship.ID] = friendship

	return friendship, nil
}

func (r *Repo) GetFriendshipBetween(_ context.Context, userID uuid.UUID, otherID uuid.UUID) (model.Friendship, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	friendship, ok := r.friendshipOfPair(userID, otherID)
	if !ok {
		return model.Friendship{}, model.ErrNotFound
	}

	return friendship, nil
}

func (r *Repo) ListFriendRequests(_ context.Context, userID uuid.UUID) (model.FriendRequests, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	pending := r.friendshipsOf(userID, model.FriendshipPending)
	slices.SortFunc(pending, func(a, b model.Friendship) int {
		if c := b.CreatedAt.Compare(a.CreatedAt); c != 0 {
			return c
		}
		return cmp.Compare(b.ID.String(), a.ID.String())
	})

	requests := model.FriendRequests{Incoming: []model.FriendRequest{}, Outgoing: []model.FriendRequest{}}
	for _, friendship := range pending {
		other := r.users[otherSide(friendship, userID)]
		request := model.FriendRequest{ID: friendship.ID, User: cardOf(other), CreatedAt: friendship.CreatedAt}
		if friendship.RequesterID == userID {
			requests.Outgoing = append(requests.Outgoing, request)
		} else {
			requests.Incoming = append(requests.Incoming, request)
		}
	}

	return requests, nil
}

func (r *Repo) AcceptFriendRequest(_ context.Context, id uuid.UUID, addresseeID uuid.UUID) (model.Friendship, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	friendship, ok := r.friendships[id]
	if !ok || friendship.AddresseeID != addresseeID || friendship.Status != model.FriendshipPending {
		return model.Friendship{}, model.ErrNotFound
	}
	now := r.now()
	friendship.Status = model.FriendshipAccepted
	friendship.RespondedAt = &now
	friendship.UpdatedAt = now
	r.friendships[id] = friendship

	return friendship, nil
}

func (r *Repo) DeleteFriendRequest(_ context.Context, id uuid.UUID, addresseeID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	friendship, ok := r.friendships[id]
	if !ok || friendship.AddresseeID != addresseeID || friendship.Status != model.FriendshipPending {
		return model.ErrNotFound
	}
	delete(r.friendships, id)

	return nil
}

func (r *Repo) ListFriends(_ context.Context, userID uuid.UUID, pagination model.Pagination) ([]model.Friend, int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	friends := []model.Friend{}
	for _, friendship := range r.friendshipsOf(userID, model.FriendshipAccepted) {
		other := r.users[otherSide(friendship, userID)]
		friends = append(friends, model.Friend{
			FriendshipID: friendship.ID,
			User:         cardOf(other),
			FirstName:    other.FirstName,
			LastName:     other.LastName,
			Since:        *friendship.RespondedAt,
		})
	}
	slices.SortFunc(friends, func(a, b model.Friend) int { return cmp.Compare(a.User.Username, b.User.Username) })

	return page(friends, pagination)
}

func (r *Repo) SearchUsers(_ context.Context, viewerID uuid.UUID, query string, pagination model.Pagination) ([]model.UserSearchResult, int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	results := []model.UserSearchResult{}
	for _, user := range r.users {
		if user.ID == viewerID || user.Status != model.UserStatusActive || !strings.Contains(string(user.Username), query) {
			continue
		}
		result := model.UserSearchResult{User: cardOf(user), Relation: model.UserRelationNone}
		if friendship, ok := r.friendshipOfPair(viewerID, user.ID); ok {
			if friendship.Status == model.FriendshipBlocked {
				continue
			}
			result.Relation = friendship.RelationTo(viewerID)
			result.FriendshipID = &friendship.ID
		}
		results = append(results, result)
	}
	slices.SortFunc(results, func(a, b model.UserSearchResult) int {
		rank := func(username string) int {
			switch {
			case username == query:
				return 0
			case strings.HasPrefix(username, query):
				return 1
			default:
				return 2
			}
		}
		if c := cmp.Compare(rank(a.User.Username), rank(b.User.Username)); c != 0 {
			return c
		}
		return cmp.Compare(a.User.Username, b.User.Username)
	})

	return page(results, pagination)
}

// -- Feed -- //

func (r *Repo) ListFeed(_ context.Context, viewerID uuid.UUID, scope model.FeedScope, pagination model.Pagination) ([]model.FeedItem, int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	items := []model.FeedItem{}
	for _, session := range r.sessions {
		author, ok := r.users[session.UserID]
		if session.UserID == viewerID || !ok || author.Status != model.UserStatusActive {
			continue
		}
		friendship, linked := r.friendshipOfPair(viewerID, session.UserID)
		if linked && friendship.Status == model.FriendshipBlocked {
			continue
		}
		byFriend := linked && friendship.Status == model.FriendshipAccepted && session.Visibility != model.VisibilityPrivate
		public := scope == model.FeedScopeAll && session.Visibility == model.VisibilityPublic
		if byFriend || public {
			items = append(items, model.FeedItem{Session: session, Author: cardOf(author)})
		}
	}
	slices.SortFunc(items, func(a, b model.FeedItem) int {
		if c := b.Session.StartedAt.Compare(a.Session.StartedAt); c != 0 {
			return c
		}
		return cmp.Compare(b.Session.ID.String(), a.Session.ID.String())
	})

	return page(items, pagination)
}

// -- Helpers (callers hold r.mu) -- //

func (r *Repo) isActive(userID uuid.UUID) bool {
	user, ok := r.users[userID]
	return ok && user.Status == model.UserStatusActive
}

func (r *Repo) friendshipOfPair(userID uuid.UUID, otherID uuid.UUID) (model.Friendship, bool) {
	for _, friendship := range r.friendships {
		if (friendship.RequesterID == userID && friendship.AddresseeID == otherID) ||
			(friendship.RequesterID == otherID && friendship.AddresseeID == userID) {
			return friendship, true
		}
	}

	return model.Friendship{}, false
}

// friendshipsOf returns the user's friendships with the status whose other side is active.
func (r *Repo) friendshipsOf(userID uuid.UUID, status model.FriendshipStatus) []model.Friendship {
	friendships := []model.Friendship{}
	for _, friendship := range r.friendships {
		if friendship.Status != status || (friendship.RequesterID != userID && friendship.AddresseeID != userID) {
			continue
		}
		if r.isActive(otherSide(friendship, userID)) {
			friendships = append(friendships, friendship)
		}
	}

	return friendships
}

func otherSide(friendship model.Friendship, userID uuid.UUID) uuid.UUID {
	if friendship.RequesterID == userID {
		return friendship.AddresseeID
	}

	return friendship.RequesterID
}

func cardOf(user model.User) model.UserCard {
	return model.UserCard{ID: user.ID, Username: string(user.Username)}
}

// page returns the page of items and their total count.
func page[T any](items []T, pagination model.Pagination) ([]T, int, error) {
	total := len(items)
	start := min(pagination.Offset, total)
	end := min(start+pagination.Limit, total)

	return items[start:end], total, nil
}
