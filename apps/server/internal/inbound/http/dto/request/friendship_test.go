// @date 2026-11-13
// @file friendship_test.go
// @brief Unit tests of the friendship, feed, body constraint and page query request DTOs.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"errors"
	"testing"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

func TestAnswerFriendRequestIntoFriendRequestAnswer(t *testing.T) {
	if got := (AnswerFriendRequest{}).IntoFriendRequestAnswer(); got != "" {
		t.Errorf("IntoFriendRequestAnswer() without action = %q, want empty", got)
	}
	if got := (AnswerFriendRequest{Action: new("accept")}).IntoFriendRequestAnswer(); got != model.FriendRequestAnswer("accept") {
		t.Errorf("IntoFriendRequestAnswer() = %q, want accept", got)
	}
	if err := bindJSON(`{}`, &AnswerFriendRequest{}); err == nil {
		t.Error("bind({}) = nil, want an error: action is required")
	}
}

func TestFeedQueryIntoFeedScope(t *testing.T) {
	if got := (FeedQuery{}).IntoFeedScope(); got != model.FeedScopeAll {
		t.Errorf("IntoFeedScope() without scope = %q, want all", got)
	}
	if got := (FeedQuery{Scope: new("friends")}).IntoFeedScope(); got != model.FeedScopeFriends {
		t.Errorf("IntoFeedScope() = %q, want friends", got)
	}
	if got := (FeedQuery{Scope: new("nope")}).IntoFeedScope(); got != model.FeedScope("nope") {
		t.Errorf("IntoFeedScope() = %q, want the value as is (validated by the model)", got)
	}
}

func TestDeclareUserBodyConstraintIntoConfig(t *testing.T) {
	startedAt := time.Date(2026, 11, 1, 0, 0, 0, 0, time.UTC)

	config := DeclareUserBodyConstraint{Zone: new("left_knee"), Type: new("injured"), Note: new("ACL"), StartedAt: &startedAt}.IntoUserBodyConstraintConfig()
	if config.Zone != model.BodyZone("left_knee") || config.Type != model.BodyConstraintType("injured") {
		t.Errorf("zone/type = %q %q", config.Zone, config.Type)
	}
	if config.Note == nil || *config.Note != "ACL" || config.StartedAt == nil || !config.StartedAt.Equal(startedAt) {
		t.Errorf("note/started at = %v %v", config.Note, config.StartedAt)
	}

	empty := DeclareUserBodyConstraint{}.IntoUserBodyConstraintConfig()
	if empty.Zone != "" || empty.Type != "" || empty.Note != nil || empty.StartedAt != nil {
		t.Errorf("IntoUserBodyConstraintConfig() of an empty body = %+v, want zero", empty)
	}

	for _, body := range []string{`{"type":"injured"}`, `{"zone":"left_knee"}`} {
		if err := bindJSON(body, &DeclareUserBodyConstraint{}); err == nil {
			t.Errorf("bind(%s) = nil, want an error", body)
		}
	}
}

func TestPageQueryIntoPagination(t *testing.T) {
	pagination, err := (PageQuery{}).IntoPagination()
	if err != nil || pagination != (model.Pagination{Limit: model.PaginationDefaultLimit}) {
		t.Errorf("IntoPagination() = %+v, %v, want the default page", pagination, err)
	}

	pagination, err = (PageQuery{Limit: new(5), Offset: new(10)}).IntoPagination()
	if err != nil || pagination != (model.Pagination{Limit: 5, Offset: 10}) {
		t.Errorf("IntoPagination() = %+v, %v, want limit 5 offset 10", pagination, err)
	}

	if _, err := (PageQuery{Limit: new(model.PaginationMaxLimit + 1)}).IntoPagination(); !errors.Is(err, model.ErrInvalidInput) {
		t.Errorf("IntoPagination() over the max = %v, want ErrInvalidInput", err)
	}
}
