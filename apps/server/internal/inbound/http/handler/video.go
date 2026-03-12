package handler

import (
	"fmt"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
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
	filename := c.Query("filename")
	if err := validateVideoFilename(filename); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	size, err := validateVideoSize(c.Query("size"))
	if err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	contentType := c.Query("content_type")
	if err := validateVideoContentType(contentType); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	size = size

	c.Status(http.StatusOK)
}

func validateVideoFilename(filename string) error {
	var allowedExtensions = map[string]bool{
		".mp4":  true,
		".webm": true,
		".mov":  true,
		".avi":  true,
	}

	if filename == "" {
		return fmt.Errorf("filename missing")
	}

	ext := strings.ToLower(filepath.Ext(filename))

	if !allowedExtensions[ext] {
		return fmt.Errorf("extension unsupported: %s", ext)
	}

	return nil
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

func validateVideoContentType(contentType string) error {
	var allowedContentTypes = map[string]bool{
		"video/mp4":       true,
		"video/webm":      true,
		"video/quicktime": true,
		"video/x-msvideo": true,
	}

	if contentType == "" {
		return fmt.Errorf("content type missing")
	}

	if !allowedContentTypes[contentType] {
		return fmt.Errorf("content type unsupported: %s", contentType)
	}

	return nil
}
