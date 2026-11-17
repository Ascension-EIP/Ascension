// @date 2026-11-13
// @file feed.go
// @brief HTTP handler of /v1/feed.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package handler

import (
	"net/http"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/request"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/macro"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/utils"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
)

// FeedHandler serves the authenticated user's feed.
type FeedHandler struct {
	s *service.FeedService
}

// NewFeedHandler builds a FeedHandler.
func NewFeedHandler(s *service.FeedService) FeedHandler {
	return FeedHandler{s: s}
}

// Get returns one page of the climbing sessions shared with the user
// (GET /v1/feed?scope=all|friends&limit=&offset=).
func (h *FeedHandler) Get(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	var req request.FeedQuery
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	pagination, err := req.IntoPagination()
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	page, err := h.s.GetFeed(c.Request.Context(), user.ID, req.IntoFeedScope(), pagination)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.FeedPageToResponse(page))
}
