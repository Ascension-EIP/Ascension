// @date 2026-03-18
// @file analysis.go
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

type AnalysisHandler struct {
	s *service.AnalysisService
}

func NewAnalysisHandler(s *service.AnalysisService) AnalysisHandler {
	return AnalysisHandler{s: s}
}

func (h *AnalysisHandler) Create(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	var req request.CreateAnalyseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}
	analysisConfig := req.IntoAnalysisConfig()

	analysis, err := h.s.TriggerAnalysis(c.Request.Context(), user.ID, analysisConfig)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusAccepted, response.AnalysisToResponse(analysis))
}

func (h *AnalysisHandler) GetByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	analysis, err := h.s.GetAnalysisByID(c.Request.Context(), id)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.AnalysisToResponse(analysis))
}
