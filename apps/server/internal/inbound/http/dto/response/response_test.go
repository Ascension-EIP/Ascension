// @date 2026-11-13
// @file response_test.go
// @brief Unit tests of the conversions from domain models to API responses and of their JSON keys.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package response

import (
	"encoding/json"
	"errors"
	"net/url"
	"slices"
	"testing"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

// jsonKeys returns the top-level keys of v encoded in JSON.
func jsonKeys(t *testing.T, v any) []string {
	t.Helper()

	raw, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("Marshal() error = %v", err)
	}
	var object map[string]json.RawMessage
	if err := json.Unmarshal(raw, &object); err != nil {
		t.Fatalf("Unmarshal() error = %v", err)
	}

	keys := make([]string, 0, len(object))
	for key := range object {
		keys = append(keys, key)
	}
	slices.Sort(keys)
	return keys
}

func checkKeys(t *testing.T, v any, want ...string) {
	t.Helper()

	slices.Sort(want)
	if got := jsonKeys(t, v); !slices.Equal(got, want) {
		t.Errorf("JSON keys = %v, want %v", got, want)
	}
}

func TestNewError(t *testing.T) {
	got := NewError(errors.New("boom"))
	if got.Message != "boom" {
		t.Errorf("Message = %q, want boom", got.Message)
	}
	checkKeys(t, got, "error")
}

func TestAnalysisToResponse(t *testing.T) {
	var analysis model.Analysis
	fillDistinct(&analysis)

	got := AnalysisToResponse(analysis)
	checkFields(t, analysis, got, nil)
	checkKeys(t, got, "id", "video_id", "type", "status", "visibility", "progress", "result", "advice", "error",
		"processing_time_ms", "started_at", "completed_at", "hints")
}

func TestAuthResponses(t *testing.T) {
	user := model.User{ID: uuid.NewV7(), Username: "climber", Email: "climber@ascension.app", Role: model.UserRoleUser, Status: model.UserStatusActive}
	tokens := model.Tokens{
		RefreshToken: model.RefreshToken{SessionToken: "refresh"},
		AccessToken:  model.AccessToken{Token: "access", TokenType: "Bearer", ExpiresIn: 900},
	}

	t.Run("login", func(t *testing.T) {
		got := TokensUserToResponse(tokens, user)
		if got.RefreshToken != "refresh" || got.AccessToken != "access" || got.TokenType != "Bearer" || got.ExpiresIn != 900 {
			t.Errorf("TokensUserToResponse() = %+v", got)
		}
		if got.User != UserToResponse(user) {
			t.Errorf("User = %+v, want %+v", got.User, UserToResponse(user))
		}
		checkKeys(t, got, "refresh_token", "access_token", "token_type", "expires_in", "user")
	})

	t.Run("refresh", func(t *testing.T) {
		got := AccessTokenToResponse(tokens.AccessToken)
		if got != (AccessTokenResponse{AccessToken: "access", TokenType: "Bearer", ExpiresIn: 900}) {
			t.Errorf("AccessTokenToResponse() = %+v", got)
		}
		checkKeys(t, got, "access_token", "token_type", "expires_in")
	})
}

func TestUserToResponse(t *testing.T) {
	var user model.User
	fillDistinct(&user)

	got := UserToResponse(user)
	checkFields(t, user, got, nil)

	// The password hash never leaves the server.
	for _, key := range jsonKeys(t, got) {
		if key == "Password" || key == "password" || key == "password_hash" {
			t.Errorf("the user response exposes %q", key)
		}
	}

	list := UsersToResponse([]model.User{user, {ID: uuid.NewV7()}})
	if len(list) != 2 || list[0] != got {
		t.Errorf("UsersToResponse() = %+v", list)
	}
	if empty := UsersToResponse(nil); empty == nil || len(empty) != 0 {
		t.Errorf("UsersToResponse(nil) = %#v, want []", empty)
	}
}

func TestUserProfileToResponse(t *testing.T) {
	var profile model.UserProfile
	fillDistinct(&profile)

	got := UserProfileToResponse(profile)
	checkFields(t, profile, got, nil)
	checkKeys(t, got, "user_id", "birth_date", "height_cm", "weight_kg", "arm_span_cm", "dominant_hand", "climbing_level",
		"grading_system", "years_of_practice", "bio", "avatar_object_key")

	empty := UserProfileToResponse(model.UserProfile{UserID: profile.UserID})
	if empty.DominantHand != nil || empty.GradingSystem != nil || empty.HeightCM != nil {
		t.Errorf("UserProfileToResponse() of an empty profile = %+v, want null fields", empty)
	}
}

func TestClimbingSessionResponses(t *testing.T) {
	var session model.ClimbingSession
	fillDistinct(&session)
	var summary model.AnalysisSummary
	fillDistinct(&summary)

	t.Run("session", func(t *testing.T) {
		got := ClimbingSessionToResponse(session)
		checkFields(t, session, got, nil)
		for _, key := range jsonKeys(t, got) {
			if key == "user_id" {
				t.Error("the session response exposes user_id")
			}
		}
	})

	t.Run("details", func(t *testing.T) {
		got := ClimbingSessionDetailsToResponse(model.ClimbingSessionDetails{Session: session, Analyses: []model.AnalysisSummary{summary}})
		checkFields(t, session, got.ClimbingSession, nil)
		if len(got.Analyses) != 1 {
			t.Fatalf("len(Analyses) = %d, want 1", len(got.Analyses))
		}
		checkFields(t, summary, got.Analyses[0], nil)

		empty := ClimbingSessionDetailsToResponse(model.ClimbingSessionDetails{Session: session})
		if empty.Analyses == nil {
			t.Error("Analyses = nil, want [] so the JSON is not null")
		}
	})

	t.Run("pages", func(t *testing.T) {
		pagination := model.Pagination{Limit: 5, Offset: 10}

		sessions := ClimbingSessionPageToResponse(model.ClimbingSessionPage{Sessions: []model.ClimbingSession{session}, Total: 11, Pagination: pagination})
		if len(sessions.Sessions) != 1 || sessions.Total != 11 || sessions.Limit != 5 || sessions.Offset != 10 {
			t.Errorf("ClimbingSessionPageToResponse() = %+v", sessions)
		}
		checkKeys(t, sessions, "sessions", "total", "limit", "offset")

		analyses := AnalysisSummaryPageToResponse(model.AnalysisSummaryPage{Analyses: []model.AnalysisSummary{summary}, Total: 11, Pagination: pagination})
		if len(analyses.Analyses) != 1 || analyses.Total != 11 || analyses.Limit != 5 || analyses.Offset != 10 {
			t.Errorf("AnalysisSummaryPageToResponse() = %+v", analyses)
		}
		checkKeys(t, analyses, "analyses", "total", "limit", "offset")

		if got := ClimbingSessionPageToResponse(model.ClimbingSessionPage{}); got.Sessions == nil {
			t.Error("Sessions = nil, want []")
		}
		if got := AnalysisSummaryPageToResponse(model.AnalysisSummaryPage{}); got.Analyses == nil {
			t.Error("Analyses = nil, want []")
		}
	})
}

func TestFeedPageToResponse(t *testing.T) {
	var item model.FeedItem
	fillDistinct(&item)

	got := FeedPageToResponse(model.FeedPage{Items: []model.FeedItem{item}, Total: 3, Pagination: model.Pagination{Limit: 2, Offset: 1}})
	if got.Total != 3 || got.Limit != 2 || got.Offset != 1 || len(got.Sessions) != 1 {
		t.Fatalf("FeedPageToResponse() = %+v", got)
	}
	session := got.Sessions[0]
	checkFields(t, item.Session, session, map[string]string{"Author": ""})
	if session.Author != (UserCard{ID: item.Author.ID, Username: item.Author.Username}) {
		t.Errorf("Author = %+v, want %+v", session.Author, item.Author)
	}
	for _, key := range jsonKeys(t, session) {
		if key == "notes" {
			t.Error("the feed exposes the notes of the author")
		}
	}

	if empty := FeedPageToResponse(model.FeedPage{}); empty.Sessions == nil {
		t.Error("Sessions = nil, want []")
	}
}

func TestFriendshipResponses(t *testing.T) {
	var friendship model.Friendship
	fillDistinct(&friendship)
	var request model.FriendRequest
	fillDistinct(&request)
	var friend model.Friend
	fillDistinct(&friend)
	var result model.UserSearchResult
	fillDistinct(&result)

	t.Run("friendship", func(t *testing.T) {
		checkFields(t, friendship, FriendshipToResponse(friendship), nil)
	})

	t.Run("requests", func(t *testing.T) {
		got := FriendRequestsToResponse(model.FriendRequests{Incoming: []model.FriendRequest{request}})
		if len(got.Incoming) != 1 || got.Outgoing == nil || len(got.Outgoing) != 0 {
			t.Fatalf("FriendRequestsToResponse() = %+v, want one incoming and [] outgoing", got)
		}
		want := FriendRequest{ID: request.ID, User: UserCard{ID: request.User.ID, Username: request.User.Username}, CreatedAt: request.CreatedAt}
		if got.Incoming[0] != want {
			t.Errorf("Incoming[0] = %+v, want %+v", got.Incoming[0], want)
		}
	})

	t.Run("friends", func(t *testing.T) {
		got := FriendPageToResponse(model.FriendPage{Friends: []model.Friend{friend}, Total: 1, Pagination: model.Pagination{Limit: 20}})
		want := Friend{
			FriendshipID: friend.FriendshipID,
			User:         FriendUser{ID: friend.User.ID, Username: friend.User.Username, FirstName: friend.FirstName, LastName: friend.LastName},
			Since:        friend.Since,
		}
		if len(got.Friends) != 1 || got.Friends[0] != want || got.Total != 1 || got.Limit != 20 {
			t.Errorf("FriendPageToResponse() = %+v, want [%+v]", got, want)
		}
		if empty := FriendPageToResponse(model.FriendPage{}); empty.Friends == nil {
			t.Error("Friends = nil, want []")
		}
	})

	t.Run("search", func(t *testing.T) {
		got := UserSearchPageToResponse(model.UserSearchPage{Users: []model.UserSearchResult{result}, Total: 1, Pagination: model.Pagination{Limit: 20, Offset: 0}})
		want := UserSearchResult{ID: result.User.ID, Username: result.User.Username, Relation: result.Relation, FriendshipID: result.FriendshipID}
		if len(got.Users) != 1 || got.Users[0] != want || got.Total != 1 {
			t.Errorf("UserSearchPageToResponse() = %+v, want [%+v]", got, want)
		}
		if empty := UserSearchPageToResponse(model.UserSearchPage{}); empty.Users == nil {
			t.Error("Users = nil, want []")
		}
	})
}

func TestUserBodyConstraintResponses(t *testing.T) {
	var constraint model.UserBodyConstraint
	fillDistinct(&constraint)

	checkFields(t, constraint, UserBodyConstraintToResponse(constraint), nil)

	list := UserBodyConstraintsToResponse([]model.UserBodyConstraint{constraint})
	if len(list.Constraints) != 1 || list.Constraints[0] != UserBodyConstraintToResponse(constraint) {
		t.Errorf("UserBodyConstraintsToResponse() = %+v", list)
	}
	if empty := UserBodyConstraintsToResponse(nil); empty.Constraints == nil {
		t.Error("Constraints = nil, want []")
	}
}

func TestVideoResponses(t *testing.T) {
	link, err := url.Parse("https://s3.example.com/ascension-videos/key.mp4?X-Amz-Signature=abc")
	if err != nil {
		t.Fatal(err)
	}
	expiresAt := time.Date(2026, 11, 13, 12, 0, 0, 0, time.UTC)

	t.Run("download url", func(t *testing.T) {
		got := DownloadURLToResponse(model.VideoDownloadURL{URL: link, ExpiresAt: expiresAt})
		if got.URL != link.String() || !got.ExpiresAt.Equal(expiresAt) {
			t.Errorf("DownloadURLToResponse() = %+v", got)
		}
		checkKeys(t, got, "download_url", "expires_at")
	})

	t.Run("upload url", func(t *testing.T) {
		videoID := uuid.NewV7()
		got := UploadURLToResponse(model.VideoUploadURL{VideoID: videoID, URL: link, ExpiresAt: expiresAt})
		if got.ID != videoID || got.URL != link.String() || !got.ExpiresAt.Equal(expiresAt) {
			t.Errorf("UploadURLToResponse() = %+v", got)
		}
		checkKeys(t, got, "video_id", "upload_url", "expires_at")
	})

	t.Run("video", func(t *testing.T) {
		var video model.Video
		fillDistinct(&video)

		got := VideoToResponse(video)
		checkFields(t, video, got, nil)

		list := VideosToResponse([]model.Video{video})
		if len(list) != 1 || list[0].ID != video.ID {
			t.Errorf("VideosToResponse() = %+v", list)
		}
		if empty := VideosToResponse(nil); empty == nil || len(empty) != 0 {
			t.Errorf("VideosToResponse(nil) = %#v, want []", empty)
		}
	})
}
