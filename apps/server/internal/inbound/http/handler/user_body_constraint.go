// @date 2026-11-13
// @file user_body_constraint.go
// @brief HTTP handlers of /v1/profile/constraints.
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

// UserBodyConstraintHandler serves the authenticated user's body constraints.
type UserBodyConstraintHandler struct {
	s *service.UserBodyConstraintService
}

// NewUserBodyConstraintHandler builds a UserBodyConstraintHandler.
func NewUserBodyConstraintHandler(s *service.UserBodyConstraintService) UserBodyConstraintHandler {
	return UserBodyConstraintHandler{s: s}
}

// List returns the user's active constraints (GET /v1/profile/constraints).
func (h *UserBodyConstraintHandler) List(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	constraints, err := h.s.ListActiveConstraints(c.Request.Context(), user.ID)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.UserBodyConstraintsToResponse(constraints))
}

// Declare records a constraint on a zone (POST /v1/profile/constraints): 201 Created for a
// new active constraint, 200 OK when it replaces the one already active on the zone.
func (h *UserBodyConstraintHandler) Declare(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	var req request.DeclareUserBodyConstraint
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	constraint, created, err := h.s.DeclareConstraint(c.Request.Context(), user.ID, req.IntoUserBodyConstraintConfig())
	if err != nil {
		utils.Error(c, err)
		return
	}

	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	c.JSON(status, response.UserBodyConstraintToResponse(constraint))
}

// Remove resolves an injury or deletes a missing zone (DELETE /v1/profile/constraints/:id).
func (h *UserBodyConstraintHandler) Remove(c *gin.Context) {
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

	if err := h.s.RemoveConstraint(c.Request.Context(), id, user.ID); err != nil {
		utils.Error(c, err)
		return
	}

	c.Status(http.StatusNoContent)
}
