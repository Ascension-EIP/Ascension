package handler

import (
	"fmt"
	"net/http"
	"time"

	"github.com/DimitriLaPoudre/go-backend-base/internal/infra/config"
	"github.com/DimitriLaPoudre/go-backend-base/internal/service/auth"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/dto"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/dto/request"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/dto/response"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/utils"
	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	s          *auth.Service
	cookieName string
	https      bool
}

func NewAuthHandler(cfg *config.Config, s *auth.Service) *AuthHandler {
	return &AuthHandler{s: s, cookieName: cfg.Auth.CookieName, https: cfg.HTTP.HTTPS}
}

func (h *AuthHandler) Signup(c *gin.Context) {
	var req request.AuthForm
	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.Error{Error: err.Error()})
		return
	}
	user := dto.AuthFormToEntity(&req)
	if err := h.s.Signup(c.Request.Context(), user); err != nil {
		fmt.Println("--------------------", err)
		utils.Error(c, err)
		return
	}
	c.Status(http.StatusCreated)
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req request.AuthForm
	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.Error{Error: err.Error()})
		return
	}
	user := dto.AuthFormToEntity(&req)
	session, err := h.s.Login(c.Request.Context(), user)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.SetCookie(h.cookieName, session.ID, int(time.Until(session.ExpiresAt).Seconds()), "/", "", h.https, true)
	c.Status(http.StatusNoContent)
}

func (h *AuthHandler) Logout(c *gin.Context) {
	sessionID, err := c.Cookie(h.cookieName)
	if err == nil {
		userID, err := utils.GetFromContext[uint](c, "userID")
		if err != nil {
			c.Status(http.StatusInternalServerError)
			return
		}
		_ = h.s.Logout(c.Request.Context(), userID, sessionID)
	}
	c.SetCookie(h.cookieName, "", -1, "/", "", h.https, true)
	c.Status(http.StatusNoContent)
}
