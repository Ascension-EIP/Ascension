// @date 2026-03-20
// @file video.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package handler

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/utils"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
	"uuid"
)

type VideoHandler struct {
	s *service.VideoService
}

func NewVideoHandler(s *service.VideoService) VideoHandler {
	return VideoHandler{s: s}
}

func (h *VideoHandler) GetDownloadURL(c *gin.Context) {
	userID, err := utils.GetFromContext[uuid.UUID](c, "userID")
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

	url, err := h.s.GetDownloadURL(c.Request.Context(), videoID, userID)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.DownloadURLToResponse(url))
}

func (h *VideoHandler) GetUploadURL(c *gin.Context) {
	userID, err := utils.GetFromContext[uuid.UUID](c, "userID")
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	ext, err := getVideoExtension(c.Query("content_type"))
	if err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	size, err := validateVideoSize(c.Query("size"))
	if err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	url, err := h.s.GetUploadURL(c.Request.Context(), model.FileInfo{
		UserID:    userID,
		Extension: ext,
		Size:      size,
	})
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.UploadURLToResponse(url))
}

func getVideoExtension(contentType string) (string, error) {
	var allowedContentTypes = map[string]string{
		"video/mp4":       "mp4",
		"video/webm":      "webm",
		"video/quicktime": "mov",
		"video/x-msvideo": "avi",
	}

	if contentType == "" {
		return "", fmt.Errorf("content type missing")
	}

	ext, ok := allowedContentTypes[contentType]
	if !ok {
		return "", fmt.Errorf("content type unsupported: %s", contentType)
	}

	return ext, nil
}

func validateVideoSize(s string) (int, error) {
	if s == "" {
		return 0, fmt.Errorf("size missing")
	}
	size, err := strconv.Atoi(s)
	if err != nil {
		return 0, fmt.Errorf("invalid size")
	}
	if size > 1*1024*1024*1024 {
		return 0, fmt.Errorf("file too big: maximum 1GB")
	}
	return size, nil
}

func (h *VideoHandler) UploadComplete(c *gin.Context) {
	userID, err := utils.GetFromContext[uuid.UUID](c, "userID")
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

	if err := h.s.UploadComplete(c.Request.Context(), videoID, userID); err != nil {
		utils.Error(c, err)
		return
	}

	c.Status(http.StatusNoContent)
}
