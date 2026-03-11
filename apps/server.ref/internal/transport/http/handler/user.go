package handler

import (
	"net/http"
	"strconv"

	"github.com/DimitriLaPoudre/go-backend-base/internal/service/user"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/dto"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/dto/request"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/dto/response"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/utils"
	"github.com/gin-gonic/gin"
)

type UserHandler struct {
	s *user.Service
}

func NewUserHandler(s *user.Service) *UserHandler {
	return &UserHandler{s: s}
}

func (h *UserHandler) Create(c *gin.Context) {
	var req request.CreateUser
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.Error{Error: err.Error()})
		return
	}

	user := dto.CreateUserToEntity(&req)
	if err := h.s.CreateUser(c.Request.Context(), user); err != nil {
		utils.Error(c, err)
		return
	}
	resp := dto.UserToResponse(user)
	c.JSON(http.StatusCreated, resp)
}

func (h *UserHandler) GetByID(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, response.Error{Error: "invalid user ID"})
		return
	}
	user, err := h.s.GetUserByID(c.Request.Context(), uint(id))
	if err != nil {
		utils.Error(c, err)
		return
	}
	resp := dto.UserToResponse(user)
	c.JSON(http.StatusOK, resp)
}

func (h *UserHandler) List(c *gin.Context) {
	users, err := h.s.ListAllUsers(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, response.Error{Error: "could not list users"})
		return
	}
	resp := dto.UsersToResponse(users)
	c.JSON(http.StatusOK, resp)
}

func (h *UserHandler) Update(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, response.Error{Error: "invalid user ID"})
		return
	}
	var req request.UpdateUser
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.Error{Error: err.Error()})
		return
	}
	user := dto.UpdateUserToEntity(uint(id), &req)
	if err := h.s.UpdateUser(c.Request.Context(), user); err != nil {
		c.JSON(http.StatusInternalServerError, response.Error{Error: "could not update user"})
		return
	}
	resp := dto.UserToResponse(user)
	c.JSON(http.StatusOK, resp)
}

func (h *UserHandler) Delete(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, response.Error{Error: "invalid user ID"})
		return
	}
	if err := h.s.DeleteUser(c.Request.Context(), uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, response.Error{Error: "could not delete user"})
		return
	}
	c.Status(http.StatusNoContent)
}
