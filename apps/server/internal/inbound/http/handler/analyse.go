package handler

import (
	"net/http"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

type AnalyseHandler struct {
	s *service.AnalyseService
	l *zerolog.Logger
}

func NewAnalyseHandler(l *zerolog.Logger, s *service.AnalyseService) AnalyseHandler {
	return AnalyseHandler{s: s, l: l}
}

func (h *AnalyseHandler) Create(c *gin.Context) {
	c.Status(http.StatusOK)
}

func (h *AnalyseHandler) GetByID(c *gin.Context) {
	c.Status(http.StatusOK)
}
