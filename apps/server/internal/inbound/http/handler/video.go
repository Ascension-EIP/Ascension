// @date 2026-03-20
// @file video.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
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

type VideoHandler struct {
	s *service.VideoService
}

func NewVideoHandler(s *service.VideoService) VideoHandler {
	return VideoHandler{s: s}
}

func (h *VideoHandler) GetDownloadURL(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	id := c.Param("id")
	videoID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	url, err := h.s.GetDownloadURL(c.Request.Context(), videoID, user.ID)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.DownloadURLToResponse(url))
}

func (h *VideoHandler) GetUploadURL(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	var req request.VideoUpload
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}
	videoMetadata, videoConfig, err := req.IntoVideoMetadataAndVideoConfig()
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	url, err := h.s.GetUploadURL(c.Request.Context(), user.ID, videoMetadata, videoConfig)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.UploadURLToResponse(url))
}

func (h *VideoHandler) UploadComplete(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	id := c.Param("id")
	videoID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	if err := h.s.UploadComplete(c.Request.Context(), videoID, user.ID); err != nil {
		utils.Error(c, err)
		return
	}

	c.Status(http.StatusNoContent)
}
