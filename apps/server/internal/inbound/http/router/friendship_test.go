// @date 2026-11-13
// @file friendship_test.go
// @brief Endpoint tests of /v1/friends, /v1/users/search and /v1/feed.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"net/http"
	"testing"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

type userCardBody struct {
	ID       uuid.UUID `json:"id"`
	Username string    `json:"username"`
}

type friendshipBody struct {
	ID          uuid.UUID `json:"id"`
	RequesterID uuid.UUID `json:"requester_id"`
	AddresseeID uuid.UUID `json:"addressee_id"`
	Status      string    `json:"status"`
	RespondedAt *string   `json:"responded_at"`
}

type friendRequestBody struct {
	ID   uuid.UUID    `json:"id"`
	User userCardBody `json:"user"`
}

type friendRequestsBody struct {
	Incoming []friendRequestBody `json:"incoming"`
	Outgoing []friendRequestBody `json:"outgoing"`
}

type friendListBody struct {
	Friends []struct {
		FriendshipID uuid.UUID `json:"friendship_id"`
		User         struct {
			ID        uuid.UUID `json:"id"`
			Username  string    `json:"username"`
			FirstName string    `json:"first_name"`
			LastName  string    `json:"last_name"`
		} `json:"user"`
		Since string `json:"since"`
	} `json:"friends"`
	Total int `json:"total"`
}

type userSearchBody struct {
	Users []struct {
		ID           uuid.UUID  `json:"id"`
		Username     string     `json:"username"`
		Relation     string     `json:"relation"`
		FriendshipID *uuid.UUID `json:"friendship_id"`
	} `json:"users"`
	Total int `json:"total"`
	Limit int `json:"limit"`
}

type feedBody struct {
	Sessions []struct {
		ID         uuid.UUID    `json:"id"`
		Author     userCardBody `json:"author"`
		Visibility string       `json:"visibility"`
		Notes      *string      `json:"notes"`
	} `json:"sessions"`
	Total int `json:"total"`
}

// socialFixture creates the users of the social scenario in the repository under test.
type socialFixture struct {
	repo       testRepo
	createUser func(t *testing.T, username string) uuid.UUID
	deactivate func(t *testing.T, id uuid.UUID)
	block      func(t *testing.T, requesterID uuid.UUID, addresseeID uuid.UUID)
}

func TestSocialEndpoints(t *testing.T) {
	repo := memrepo.New()
	testSocialEndpoints(t, socialFixture{
		repo:       repo,
		createUser: func(_ *testing.T, username string) uuid.UUID { return repo.AddUser(username) },
		deactivate: func(_ *testing.T, id uuid.UUID) { repo.DeactivateUser(id) },
		block:      func(_ *testing.T, requesterID, addresseeID uuid.UUID) { repo.BlockPair(requesterID, addresseeID) },
	})
}

// testSocialEndpoints runs the friendship and feed scenario against a repository: memrepo
// in the unit test, PostgreSQL in the integration test.
func testSocialEndpoints(t *testing.T, fx socialFixture) {
	t.Helper()

	alice, bob, carol := fx.createUser(t, "alice"), fx.createUser(t, "bob"), fx.createUser(t, "carol")
	blocker, gone := fx.createUser(t, "bob_blocker"), fx.createUser(t, "bob_gone")
	fx.block(t, blocker, alice)
	fx.deactivate(t, gone)

	// One API per block of requests: /v1/friends allows 10 requests per minute.
	api := newTestAPI(t, fx.repo)
	aliceToken, bobToken, carolToken := api.token(alice), api.token(bob), api.token(carol)

	expect(t, api.do(http.MethodGet, "/v1/friends", "", nil), http.StatusUnauthorized, nil)
	expect(t, api.do(http.MethodPost, "/v1/friends/requests/not-a-uuid", aliceToken, nil), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodPost, "/v1/friends/requests/"+alice.String(), aliceToken, nil), http.StatusUnprocessableEntity, nil)
	expect(t, api.do(http.MethodPost, "/v1/friends/requests/"+uuid.NewV7().String(), aliceToken, nil), http.StatusNotFound, nil)
	expect(t, api.do(http.MethodPost, "/v1/friends/requests/"+gone.String(), aliceToken, nil), http.StatusNotFound, nil)
	// A blocked pair looks like an unknown user, both ways.
	expect(t, api.do(http.MethodPost, "/v1/friends/requests/"+blocker.String(), aliceToken, nil), http.StatusNotFound, nil)

	var request friendshipBody
	expect(t, api.do(http.MethodPost, "/v1/friends/requests/"+bob.String(), aliceToken, nil), http.StatusCreated, &request)
	if request.RequesterID != alice || request.AddresseeID != bob || request.Status != "pending" || request.RespondedAt != nil {
		t.Fatalf("request = %+v", request)
	}
	expect(t, api.do(http.MethodPost, "/v1/friends/requests/"+bob.String(), aliceToken, nil), http.StatusConflict, nil)
	expect(t, api.do(http.MethodPost, "/v1/friends/requests/"+alice.String(), bobToken, nil), http.StatusConflict, nil)

	var carolRequest friendshipBody
	expect(t, api.do(http.MethodPost, "/v1/friends/requests/"+bob.String(), carolToken, nil), http.StatusCreated, &carolRequest)

	api = newTestAPI(t, fx.repo)

	var bobRequests friendRequestsBody
	expect(t, api.do(http.MethodGet, "/v1/friends/requests", bobToken, nil), http.StatusOK, &bobRequests)
	if len(bobRequests.Incoming) != 2 || len(bobRequests.Outgoing) != 0 || bobRequests.Incoming[0].ID != carolRequest.ID || bobRequests.Incoming[1].User.Username != "alice" {
		t.Fatalf("bob's requests = %+v, want carol's then alice's", bobRequests)
	}
	var aliceRequests friendRequestsBody
	expect(t, api.do(http.MethodGet, "/v1/friends/requests", aliceToken, nil), http.StatusOK, &aliceRequests)
	if len(aliceRequests.Outgoing) != 1 || aliceRequests.Outgoing[0].User.ID != bob || aliceRequests.Incoming == nil {
		t.Fatalf("alice's requests = %+v, want one outgoing to bob", aliceRequests)
	}

	requestPath := "/v1/friends/requests/" + request.ID.String()
	expect(t, api.do(http.MethodPut, requestPath, bobToken, `{"action":`), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodPut, requestPath, bobToken, map[string]any{}), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodPut, requestPath, bobToken, map[string]any{"action": "block"}), http.StatusUnprocessableEntity, nil)
	// Only the addressee answers.
	expect(t, api.do(http.MethodPut, requestPath, aliceToken, map[string]any{"action": "accept"}), http.StatusNotFound, nil)

	var accepted friendshipBody
	expect(t, api.do(http.MethodPut, requestPath, bobToken, map[string]any{"action": "accept"}), http.StatusOK, &accepted)
	if accepted.ID != request.ID || accepted.Status != "accepted" || accepted.RespondedAt == nil {
		t.Fatalf("accepted = %+v", accepted)
	}
	expect(t, api.do(http.MethodPut, requestPath, bobToken, map[string]any{"action": "decline"}), http.StatusNotFound, nil)

	// A declined request is deleted.
	expect(t, api.do(http.MethodPut, "/v1/friends/requests/"+carolRequest.ID.String(), bobToken, map[string]any{"action": "decline"}), http.StatusNoContent, nil)

	api = newTestAPI(t, fx.repo)

	var bobFriends friendListBody
	expect(t, api.do(http.MethodGet, "/v1/friends", bobToken, nil), http.StatusOK, &bobFriends)
	if bobFriends.Total != 1 || len(bobFriends.Friends) != 1 || bobFriends.Friends[0].User.ID != alice ||
		bobFriends.Friends[0].User.FirstName != "First alice" || bobFriends.Friends[0].FriendshipID != request.ID || bobFriends.Friends[0].Since == "" {
		t.Fatalf("bob's friends = %+v, want alice", bobFriends)
	}
	var carolFriends friendListBody
	expect(t, api.do(http.MethodGet, "/v1/friends", carolToken, nil), http.StatusOK, &carolFriends)
	if carolFriends.Total != 0 || carolFriends.Friends == nil {
		t.Fatalf("carol's friends = %+v, want []", carolFriends)
	}
	expect(t, api.do(http.MethodGet, "/v1/friends?limit=0", carolToken, nil), http.StatusBadRequest, nil)
	// Carol can ask again after the decline.
	expect(t, api.do(http.MethodPost, "/v1/friends/requests/"+bob.String(), carolToken, nil), http.StatusCreated, nil)

	// -- User search -- //

	expect(t, api.do(http.MethodGet, "/v1/users/search?q=bob", "", nil), http.StatusUnauthorized, nil)
	expect(t, api.do(http.MethodGet, "/v1/users/search", aliceToken, nil), http.StatusUnprocessableEntity, nil)
	expect(t, api.do(http.MethodGet, "/v1/users/search?q=b%25", aliceToken, nil), http.StatusUnprocessableEntity, nil)

	var search userSearchBody
	expect(t, api.do(http.MethodGet, "/v1/users/search?q=BOB", aliceToken, nil), http.StatusOK, &search)
	// The blocker and the deactivated user stay hidden.
	if search.Total != 1 || len(search.Users) != 1 || search.Users[0].ID != bob || search.Users[0].Relation != "friends" ||
		search.Users[0].FriendshipID == nil || *search.Users[0].FriendshipID != request.ID || search.Limit != 20 {
		t.Fatalf("alice's search = %+v, want bob as a friend", search)
	}
	var bobSearch userSearchBody
	expect(t, api.do(http.MethodGet, "/v1/users/search?q=bob", bobToken, nil), http.StatusOK, &bobSearch)
	if bobSearch.Total != 1 || bobSearch.Users[0].ID != blocker || bobSearch.Users[0].Relation != "none" {
		t.Fatalf("bob's search = %+v, want bob_blocker only, never himself", bobSearch)
	}
	var carolSearch userSearchBody
	expect(t, api.do(http.MethodGet, "/v1/users/search?q=bo&limit=1", carolToken, nil), http.StatusOK, &carolSearch)
	if carolSearch.Total != 2 || len(carolSearch.Users) != 1 || carolSearch.Users[0].ID != bob || carolSearch.Users[0].Relation != "request_sent" {
		t.Fatalf("carol's search = %+v, want bob first with a sent request", carolSearch)
	}

	// -- Feed -- //

	api = newTestAPI(t, fx.repo)
	startSession := func(token string, visibility string, startedAt string) uuid.UUID {
		t.Helper()
		var session sessionBody
		expect(t, api.do(http.MethodPost, "/v1/sessions", token,
			map[string]any{"visibility": visibility, "started_at": startedAt, "notes": "Private notes"}), http.StatusCreated, &session)
		return session.ID
	}
	bobPublic := startSession(bobToken, "public", "2026-11-03T10:00:00Z")
	bobFriendsOnly := startSession(bobToken, "friends", "2026-11-02T10:00:00Z")
	startSession(bobToken, "private", "2026-11-04T10:00:00Z")
	carolPublic := startSession(carolToken, "public", "2026-11-01T10:00:00Z")
	startSession(carolToken, "friends", "2026-11-05T10:00:00Z")
	blockerPublic := startSession(api.token(blocker), "public", "2026-11-06T10:00:00Z")
	startSession(aliceToken, "public", "2026-11-07T10:00:00Z")

	expect(t, api.do(http.MethodGet, "/v1/feed", "", nil), http.StatusUnauthorized, nil)
	expect(t, api.do(http.MethodGet, "/v1/feed?scope=public", aliceToken, nil), http.StatusUnprocessableEntity, nil)

	for path, want := range map[string][]uuid.UUID{
		"/v1/feed":               {bobPublic, bobFriendsOnly, carolPublic},
		"/v1/feed?scope=all":     {bobPublic, bobFriendsOnly, carolPublic},
		"/v1/feed?scope=friends": {bobPublic, bobFriendsOnly},
	} {
		var feed feedBody
		expect(t, api.do(http.MethodGet, path, aliceToken, nil), http.StatusOK, &feed)
		if feed.Total != len(want) || len(feed.Sessions) != len(want) {
			t.Fatalf("GET %s = %+v, want %d sessions", path, feed, len(want))
		}
		for i, id := range want {
			if feed.Sessions[i].ID != id || feed.Sessions[i].Notes != nil {
				t.Errorf("GET %s [%d] = %+v, want %v without notes", path, i, feed.Sessions[i], id)
			}
		}
		if feed.Sessions[0].Author.ID != bob || feed.Sessions[0].Author.Username != "bob" {
			t.Errorf("GET %s author = %+v, want bob", path, feed.Sessions[0].Author)
		}
	}

	// The block only hides the pair: bob, a friend of alice and a stranger to the others,
	// sees alice's public session, the blocker's and carol's (her request is still pending).
	var bobFeed feedBody
	expect(t, api.do(http.MethodGet, "/v1/feed?limit=2", bobToken, nil), http.StatusOK, &bobFeed)
	if bobFeed.Total != 3 || len(bobFeed.Sessions) != 2 || bobFeed.Sessions[0].Author.ID != alice || bobFeed.Sessions[1].ID != blockerPublic {
		t.Fatalf("bob's feed = %+v, want alice's then the blocker's public session", bobFeed)
	}
}
