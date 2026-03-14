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
	"github.com/google/uuid"
	"github.com/rs/zerolog"
)

type VideoHandler struct {
	s *service.VideoService
	l *zerolog.Logger
}

func NewVideoHandler(l *zerolog.Logger, s *service.VideoService) VideoHandler {
	return VideoHandler{l: l, s: s}
}

func (h *VideoHandler) GetUploadURL(c *gin.Context) {
	userID, err := utils.GetFromContext[uuid.UUID](c, "userID")
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	contentType := c.Query("content_type")
	ext, err := getVideoExtension(contentType)
	if err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	size, err := validateVideoSize(c.Query("size"))
	if err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	fileInfo := &model.FileInfo{
		UserID:    userID,
		Extension: ext,
		Size:      size,
	}

	uploadUrl, err := h.s.GetUploadURL(c.Request.Context(), fileInfo)
	if err != nil {
		utils.Error(c, err, h.l)
		return
	}

	c.JSON(http.StatusOK, response.UploadURLToResponse(uploadUrl))
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
