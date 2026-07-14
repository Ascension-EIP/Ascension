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

type AnalyseHandler struct {
	s *service.AnalysisService
	l *zerolog.Logger
}

func NewAnalyseHandler(l *zerolog.Logger, s *service.AnalysisService) AnalyseHandler {
	return AnalyseHandler{s: s, l: l}
}

func (h *AnalyseHandler) Create(c *gin.Context) {
	userID, err := utils.GetFromContext[uuid.UUID](c, "userID")
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	var req request.CreateAnalyseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	analysis, err := h.s.TriggerAnalysis(c.Request.Context(), req.VideoID, userID)
	if err != nil {
		utils.Error(c, err, h.l)
		return
	}

	c.JSON(http.StatusAccepted, response.AnalysisToResponse(analysis))
}

func (h *AnalyseHandler) GetByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := request.IntoUUID(idStr)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	analysis, err := h.s.GetAnalysis(c.Request.Context(), id)
	if err != nil {
		utils.Error(c, err, h.l)
		return
	}

	c.JSON(http.StatusOK, response.AnalysisInfoToResponse(analysis))
}
