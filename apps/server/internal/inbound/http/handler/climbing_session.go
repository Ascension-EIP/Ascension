// @date 2026-11-12
// @file climbing_session.go
// @brief HTTP handlers of the climbing session lifecycle (/v1/sessions).
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package handler

import (
	"errors"
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

// ClimbingSessionHandler serves the authenticated user's climbing sessions.
type ClimbingSessionHandler struct {
	s *service.ClimbingSessionService
}

// NewClimbingSessionHandler builds a ClimbingSessionHandler.
func NewClimbingSessionHandler(s *service.ClimbingSessionService) ClimbingSessionHandler {
	return ClimbingSessionHandler{s: s}
}

// Create starts a climbing session (POST /v1/sessions).
func (h *ClimbingSessionHandler) Create(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	var req request.StartClimbingSession
	if c.Request.ContentLength != 0 {
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, response.NewError(err))
			return
		}
	}

	session, err := h.s.StartClimbingSession(c.Request.Context(), user.ID, req.IntoClimbingSessionConfig())
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusCreated, response.ClimbingSessionToResponse(session))
}

// List returns one page of the user's climbing sessions (GET /v1/sessions?limit=&offset=).
func (h *ClimbingSessionHandler) List(c *gin.Context) {
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

	page, err := h.s.ListClimbingSessions(c.Request.Context(), user.ID, pagination)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.ClimbingSessionPageToResponse(page))
}

// GetByID returns a climbing session with its analyses (GET /v1/sessions/:id).
func (h *ClimbingSessionHandler) GetByID(c *gin.Context) {
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

	details, err := h.s.GetClimbingSessionDetails(c.Request.Context(), id, user.ID)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.ClimbingSessionDetailsToResponse(details))
}

// GetActive returns the user's ongoing climbing session with its analyses, or 204 No Content
// when every session has ended (GET /v1/sessions/active).
func (h *ClimbingSessionHandler) GetActive(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	details, err := h.s.GetActiveClimbingSession(c.Request.Context(), user.ID)
	if errors.Is(err, model.ErrClimbingSessionNotFound) {
		c.Status(http.StatusNoContent)
		return
	}
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.ClimbingSessionDetailsToResponse(details))
}

// AddAnalysis links one of the user's analyses to a climbing session (POST /v1/sessions/:id/analyses).
func (h *ClimbingSessionHandler) AddAnalysis(c *gin.Context) {
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

	var req request.AddAnalysisToClimbingSession
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	if err := h.s.AddAnalysisToClimbingSession(c.Request.Context(), id, *req.AnalysisID, user.ID); err != nil {
		utils.Error(c, err)
		return
	}

	c.Status(http.StatusNoContent)
}

// Update changes the title, the notes or the end time of a climbing session (PUT /v1/sessions/:id).
func (h *ClimbingSessionHandler) Update(c *gin.Context) {
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

	var req request.UpdateClimbingSession
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	session, err := h.s.UpdateClimbingSession(c.Request.Context(), req.IntoPartial(id, user.ID))
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.ClimbingSessionToResponse(session))
}

// Delete deletes a climbing session (DELETE /v1/sessions/:id).
func (h *ClimbingSessionHandler) Delete(c *gin.Context) {
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

	if err := h.s.DeleteClimbingSession(c.Request.Context(), id, user.ID); err != nil {
		utils.Error(c, err)
		return
	}

	c.Status(http.StatusNoContent)
}
