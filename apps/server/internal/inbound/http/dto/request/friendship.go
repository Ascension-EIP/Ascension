// @date 2026-11-13
// @file friendship.go
// @brief HTTP request DTOs of the friendship, user search and feed endpoints.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import "github.com/Ascension-EIP/Ascension/apps/server/internal/model"

// AnswerFriendRequest is the body of PUT /v1/friends/requests/:id.
type AnswerFriendRequest struct {
	Action *string `json:"action" binding:"required"`
}

// IntoFriendRequestAnswer converts the body; the value is validated by the model.
func (req AnswerFriendRequest) IntoFriendRequestAnswer() model.FriendRequestAnswer {
	if req.Action == nil {
		return ""
	}

	return model.FriendRequestAnswer(*req.Action)
}

// UserSearchQuery is the query string of GET /v1/users/search (?q=&limit=&offset=).
type UserSearchQuery struct {
	PageQuery
	Q string `form:"q"`
}

// FeedQuery is the query string of GET /v1/feed (?scope=&limit=&offset=).
type FeedQuery struct {
	PageQuery
	Scope *string `form:"scope"`
}

// IntoFeedScope converts the scope; it defaults to all.
func (req FeedQuery) IntoFeedScope() model.FeedScope {
	if req.Scope == nil {
		return model.FeedScopeAll
	}

	return model.FeedScope(*req.Scope)
}
