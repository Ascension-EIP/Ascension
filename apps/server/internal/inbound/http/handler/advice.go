// @date 2026-11-15
// @file advice.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package handler

import (
	"net/http"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/macro"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/utils"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
)

type AdviceHandler struct {
	s *service.AdviceService
}

func NewAdviceHandler(s *service.AdviceService) AdviceHandler {
	return AdviceHandler{s: s}
}

func (h *AdviceHandler) Trigger(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	videoIDStr := c.Param("id")
	videoID, err := uuid.Parse(videoIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	advice, err := h.s.TriggerAdvice(c.Request.Context(), user.ID, videoID)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusAccepted, response.AdviceToResponse(advice))
}

func (h *AdviceHandler) GetByID(c *gin.Context) {
	videoIDStr := c.Param("id")
	videoID, err := uuid.Parse(videoIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	advice, err := h.s.GetAdviceByVideoID(c.Request.Context(), videoID)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusOK, response.AdviceToResponse(advice))
}

func (h *AdviceHandler) Retry(c *gin.Context) {
	videoIDStr := c.Param("id")
	videoID, err := uuid.Parse(videoIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	advice, err := h.s.RetryAdvice(c.Request.Context(), videoID)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusAccepted, response.AdviceToResponse(advice))
}
