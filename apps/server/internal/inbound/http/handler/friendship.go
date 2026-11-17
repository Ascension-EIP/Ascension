// @date 2026-11-13
// @file friendship.go
// @brief HTTP handlers of /v1/friends and /v1/users/search.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package handler

import (
	"net/http"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/request"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/macro"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/utils"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
)

// FriendshipHandler serves the authenticated user's friendships and the user search.
type FriendshipHandler struct {
	s *service.FriendshipService
}

// NewFriendshipHandler builds a FriendshipHandler.
func NewFriendshipHandler(s *service.FriendshipService) FriendshipHandler {
	return FriendshipHandler{s: s}
}

// SendRequest sends a friend request to a user (POST /v1/friends/requests/:userId).
func (h *FriendshipHandler) SendRequest(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	addresseeID, err := uuid.Parse(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	friendship, err := h.s.SendFriendRequest(c.Request.Context(), user.ID, addresseeID)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusCreated, response.FriendshipToResponse(friendship))
}

// ListRequests returns the pending requests received and sent (GET /v1/friends/requests).
func (h *FriendshipHandler) ListRequests(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	requests, err := h.s.ListFriendRequests(c.Request.Context(), user.ID)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.FriendRequestsToResponse(requests))
}

// AnswerRequest accepts (200 with the friendship) or declines (204) a request addressed to
// the user (PUT /v1/friends/requests/:id).
func (h *FriendshipHandler) AnswerRequest(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	var req request.AnswerFriendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	answer := req.IntoFriendRequestAnswer()
	if err := answer.Validate(); err != nil {
		utils.Error(c, err)
		return
	}

	if answer == model.FriendRequestDecline {
		if err := h.s.DeclineFriendRequest(c.Request.Context(), id, user.ID); err != nil {
			utils.Error(c, err)
			return
		}
		c.Status(http.StatusNoContent)
		return
	}

	friendship, err := h.s.AcceptFriendRequest(c.Request.Context(), id, user.ID)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.FriendshipToResponse(friendship))
}

// ListFriends returns one page of the user's friends (GET /v1/friends?limit=&offset=).
func (h *FriendshipHandler) ListFriends(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	var req request.PageQuery
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	pagination, err := req.IntoPagination()
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	page, err := h.s.ListFriends(c.Request.Context(), user.ID, pagination)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.FriendPageToResponse(page))
}

// SearchUsers finds users by username (GET /v1/users/search?q=&limit=&offset=).
func (h *FriendshipHandler) SearchUsers(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	var req request.UserSearchQuery
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	pagination, err := req.IntoPagination()
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	page, err := h.s.SearchUsers(c.Request.Context(), user.ID, req.Q, pagination)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.UserSearchPageToResponse(page))
}
