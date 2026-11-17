// @date 2026-11-13
// @file dto_test.go
// @brief Unit tests of the conversions from PostgreSQL rows to domain models.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

func TestRowConversionsCopyEveryField(t *testing.T) {
	t.Run("analysis", func(t *testing.T) {
		var row Analysis
		fillDistinct(&row)
		checkFields(t, row, row.ToAnalysis(), nil)
	})

	t.Run("analysis summary", func(t *testing.T) {
		var row AnalysisSummary
		fillDistinct(&row)
		checkFields(t, row, row.ToAnalysisSummary(), nil)
	})

	t.Run("climbing session", func(t *testing.T) {
		var row ClimbingSession
		fillDistinct(&row)
		checkFields(t, row, row.ToClimbingSession(), nil)
	})

	t.Run("friendship", func(t *testing.T) {
		var row Friendship
		fillDistinct(&row)
		checkFields(t, row, row.ToFriendship(), nil)
	})

	t.Run("session", func(t *testing.T) {
		var row Session
		fillDistinct(&row)
		checkFields(t, row, row.ToSession(), nil)
	})

	t.Run("user", func(t *testing.T) {
		var row User
		fillDistinct(&row)
		checkFields(t, row, row.ToUser(), nil)
	})

	t.Run("user body constraint", func(t *testing.T) {
		var row UserBodyConstraint
		fillDistinct(&row)
		checkFields(t, row, row.ToUserBodyConstraint(), nil)
	})

	t.Run("user profile", func(t *testing.T) {
		var row UserProfile
		fillDistinct(&row)
		checkFields(t, row, row.ToUserProfile(), map[string]string{"YearsOfPratice": "YearsOfPractice"})
	})

	t.Run("video", func(t *testing.T) {
		var row Video
		fillDistinct(&row)
		checkFields(t, row, row.ToVideo(), map[string]string{"DurationMS": "DurationMs"})
	})
}

func TestRowListConversions(t *testing.T) {
	t.Run("empty lists stay non-nil", func(t *testing.T) {
		if got := AnalysesToAnalyses(nil); got == nil || len(got) != 0 {
			t.Errorf("AnalysesToAnalyses(nil) = %#v, want []", got)
		}
		if got := AnalysisSummariesToAnalysisSummaries(nil); got == nil || len(got) != 0 {
			t.Errorf("AnalysisSummariesToAnalysisSummaries(nil) = %#v, want []", got)
		}
		if got := ClimbingSessionsToClimbingSessions(nil); got == nil || len(got) != 0 {
			t.Errorf("ClimbingSessionsToClimbingSessions(nil) = %#v, want []", got)
		}
		if got := UsersToUsers(nil); got == nil || len(got) != 0 {
			t.Errorf("UsersToUsers(nil) = %#v, want []", got)
		}
		if got := UserBodyConstraintsToUserBodyConstraints(nil); got == nil || len(got) != 0 {
			t.Errorf("UserBodyConstraintsToUserBodyConstraints(nil) = %#v, want []", got)
		}
		if got := VideosToVideos(nil); got == nil || len(got) != 0 {
			t.Errorf("VideosToVideos(nil) = %#v, want []", got)
		}
		if got := FriendsToFriends(nil); got == nil || len(got) != 0 {
			t.Errorf("FriendsToFriends(nil) = %#v, want []", got)
		}
		if got := UserSearchResultsToUserSearchResults(nil, uuid.NewV7()); got == nil || len(got) != 0 {
			t.Errorf("UserSearchResultsToUserSearchResults(nil) = %#v, want []", got)
		}
		if got := FeedItemsToFeedItems(nil); got == nil || len(got) != 0 {
			t.Errorf("FeedItemsToFeedItems(nil) = %#v, want []", got)
		}
	})

	t.Run("lists keep the order", func(t *testing.T) {
		a, b := uuid.NewV7(), uuid.NewV7()

		analyses := AnalysesToAnalyses([]Analysis{{ID: a}, {ID: b}})
		summaries := AnalysisSummariesToAnalysisSummaries([]AnalysisSummary{{ID: a}, {ID: b}})
		sessions := ClimbingSessionsToClimbingSessions([]ClimbingSession{{ID: a}, {ID: b}})
		users := UsersToUsers([]User{{ID: a}, {ID: b}})
		constraints := UserBodyConstraintsToUserBodyConstraints([]UserBodyConstraint{{ID: a}, {ID: b}})
		videos := VideosToVideos([]Video{{ID: a}, {ID: b}})

		for name, ids := range map[string][]uuid.UUID{
			"analyses":    {analyses[0].ID, analyses[1].ID},
			"summaries":   {summaries[0].ID, summaries[1].ID},
			"sessions":    {sessions[0].ID, sessions[1].ID},
			"users":       {users[0].ID, users[1].ID},
			"constraints": {constraints[0].ID, constraints[1].ID},
			"videos":      {videos[0].ID, videos[1].ID},
		} {
			if ids[0] != a || ids[1] != b {
				t.Errorf("%s ids = %v, want [%v %v]", name, ids, a, b)
			}
		}
	})
}

func TestFriendRequestToFriendRequest(t *testing.T) {
	var row FriendRequest
	fillDistinct(&row)

	got := row.ToFriendRequest()
	want := model.FriendRequest{ID: row.ID, User: model.UserCard{ID: row.UserID, Username: row.Username}, CreatedAt: row.CreatedAt}
	if got != want {
		t.Errorf("ToFriendRequest() = %+v, want %+v", got, want)
	}
}

func TestFriendsToFriends(t *testing.T) {
	var row Friend
	fillDistinct(&row)

	got := FriendsToFriends([]Friend{row})
	want := model.Friend{
		FriendshipID: row.FriendshipID,
		User:         model.UserCard{ID: row.UserID, Username: row.Username},
		FirstName:    row.FirstName,
		LastName:     row.LastName,
		Since:        row.Since,
	}
	if len(got) != 1 || got[0] != want {
		t.Errorf("FriendsToFriends() = %+v, want [%+v]", got, want)
	}
}

func TestUserSearchResultsToUserSearchResults(t *testing.T) {
	viewerID, otherID, friendshipID := uuid.NewV7(), uuid.NewV7(), uuid.NewV7()

	tests := []struct {
		name             string
		row              UserSearchResult
		wantRelation     model.UserRelation
		wantFriendshipID bool
	}{
		{name: "no friendship", row: UserSearchResult{UserID: otherID, Username: "other"}, wantRelation: model.UserRelationNone},
		{
			name:         "incomplete friendship columns",
			row:          UserSearchResult{UserID: otherID, Username: "other", FriendshipID: &friendshipID},
			wantRelation: model.UserRelationNone,
		},
		{
			name:             "friends",
			row:              UserSearchResult{UserID: otherID, Username: "other", FriendshipID: &friendshipID, FriendshipStatus: new(model.FriendshipAccepted), RequesterID: &otherID},
			wantRelation:     model.UserRelationFriends,
			wantFriendshipID: true,
		},
		{
			name:             "request sent by the viewer",
			row:              UserSearchResult{UserID: otherID, Username: "other", FriendshipID: &friendshipID, FriendshipStatus: new(model.FriendshipPending), RequesterID: &viewerID},
			wantRelation:     model.UserRelationRequestSent,
			wantFriendshipID: true,
		},
		{
			name:             "request received by the viewer",
			row:              UserSearchResult{UserID: otherID, Username: "other", FriendshipID: &friendshipID, FriendshipStatus: new(model.FriendshipPending), RequesterID: &otherID},
			wantRelation:     model.UserRelationRequestReceived,
			wantFriendshipID: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := UserSearchResultsToUserSearchResults([]UserSearchResult{tt.row}, viewerID)
			if len(got) != 1 {
				t.Fatalf("len = %d, want 1", len(got))
			}
			result := got[0]
			if result.User != (model.UserCard{ID: otherID, Username: "other"}) {
				t.Errorf("User = %+v", result.User)
			}
			if result.Relation != tt.wantRelation {
				t.Errorf("Relation = %q, want %q", result.Relation, tt.wantRelation)
			}
			if tt.wantFriendshipID != (result.FriendshipID != nil) {
				t.Errorf("FriendshipID = %v, want set %v", result.FriendshipID, tt.wantFriendshipID)
			}
		})
	}
}

func TestFeedItemsToFeedItems(t *testing.T) {
	var row FeedItem
	fillDistinct(&row)

	got := FeedItemsToFeedItems([]FeedItem{row})
	if len(got) != 1 {
		t.Fatalf("len = %d, want 1", len(got))
	}
	checkFields(t, row.ClimbingSession, got[0].Session, nil)
	if want := (model.UserCard{ID: row.UserID, Username: row.AuthorUsername}); got[0].Author != want {
		t.Errorf("Author = %+v, want %+v", got[0].Author, want)
	}
}
