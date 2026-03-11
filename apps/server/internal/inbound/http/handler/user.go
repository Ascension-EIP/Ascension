package handler

import (
	"net/http"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/request"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/utils"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

type UserHandler struct {
	s *service.UserService
	l *zerolog.Logger
}

func NewUserHandler(l *zerolog.Logger, s *service.UserService) UserHandler {
	return UserHandler{s: s, l: l}
}

func (h *UserHandler) Create(c *gin.Context) {
	var req request.CreateUser
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}
	user, err := req.IntoNewUser()
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	createdUser, err := h.s.CreateUser(c.Request.Context(), &user)
	if err != nil {
		utils.Error(c, err, h.l)
		return
	}

	resp := response.UserToResponse(createdUser)
	c.JSON(http.StatusCreated, resp)
}

func (h *UserHandler) GetByID(c *gin.Context) {
	id := c.Param("id")
	userID, err := request.IntoUserID(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	user, err := h.s.GetUserByID(c.Request.Context(), userID)
	if err != nil {
		utils.Error(c, err, h.l)
		return
	}

	resp := response.UserToResponse(user)
	c.JSON(http.StatusOK, resp)
}

func (h *UserHandler) List(c *gin.Context) {
	users, err := h.s.ListAllUsers(c.Request.Context())
	if err != nil {
		utils.Error(c, err, h.l)
		return
	}

	resp := response.UsersToResponse(users)
	c.JSON(http.StatusOK, resp)
}

func (h *UserHandler) Update(c *gin.Context) {
	var req request.UpdateUser
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}
	id := c.Param("id")
	user, err := req.IntoPartialUser(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	updatedUser, err := h.s.UpdateUser(c.Request.Context(), &user)
	if err != nil {
		utils.Error(c, err, h.l)
		return
	}

	resp := response.UserToResponse(updatedUser)
	c.JSON(http.StatusOK, resp)
}

func (h *UserHandler) Delete(c *gin.Context) {
	id := c.Param("id")
	userID, err := request.IntoUserID(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	if err := h.s.DeleteUser(c.Request.Context(), userID); err != nil {
		utils.Error(c, err, h.l)
		return
	}

	c.Status(http.StatusNoContent)
}
