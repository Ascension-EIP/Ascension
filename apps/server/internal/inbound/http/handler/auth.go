package handler

import (
	"net/http"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/request"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/utils"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/rs/zerolog"
)

type AuthHandler struct {
	s *service.AuthService
	l *zerolog.Logger
}

func NewAuthHandler(l *zerolog.Logger, s *service.AuthService) AuthHandler {
	return AuthHandler{s: s, l: l}
}

func (h *AuthHandler) Signup(c *gin.Context) {
	var req request.SignupForm
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}
	form, err := req.IntoSignupForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	user, err := h.s.Signup(c.Request.Context(), &form)
	if err != nil {
		utils.Error(c, err, h.l)
		return
	}

	c.JSON(http.StatusCreated, response.UserToResponse(user))
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req request.LoginForm
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}
	form, err := req.IntoLoginForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	user, tokens, err := h.s.Login(c.Request.Context(), &form)
	if err != nil {
		utils.Error(c, err, h.l)
		return
	}

	c.JSON(http.StatusCreated, response.TokensUserToResponse(tokens, user))
}

func (h *AuthHandler) Logout(c *gin.Context) {
	var userID uuid.UUID

	var req request.RefreshToken
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	if err := h.s.Logout(c.Request.Context(), userID, req.Token); err != nil {
		utils.Error(c, err, h.l)
		return
	}

	c.Status(http.StatusNoContent)
}

func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req request.RefreshToken
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	// if err := h.s.Logout(c.Request.Context(), req.Token, req.Token); err != nil {
	// 	utils.Error(c, err, h.l)
	// 	return
	// }

	c.Status(http.StatusNoContent)
}
