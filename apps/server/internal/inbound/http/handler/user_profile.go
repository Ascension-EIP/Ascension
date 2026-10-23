// @date 2026-09-20
// @file user_profile.go
// @brief HTTP handlers for the authenticated user's profile (GET/PUT /profile).
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
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

type ProfileHandler struct {
	s *service.UserProfileService
}

func NewUserProfileHandler(s *service.UserProfileService) ProfileHandler {
	return ProfileHandler{s: s}
}

func (h *ProfileHandler) GetMyProfile(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	userProfile, err := h.s.GetUserProfileByUserID(c.Request.Context(), user.ID)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.UserProfileToResponse(userProfile))
}

func (h *ProfileHandler) UpdateMyProfile(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	var req request.UpdateUserProfile
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	userProfile, err := h.s.UpdateUserProfile(c.Request.Context(), req.IntoPartial(user.ID))
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.UserProfileToResponse(userProfile))
}
