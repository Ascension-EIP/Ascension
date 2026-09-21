// @date 2026-09-20
// @file context.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package utils

import (
	"fmt"
	"net/netip"

	"github.com/gin-gonic/gin"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

func ClientInfo(c *gin.Context) model.ClientInfo {
	var clientInfo model.ClientInfo
	userAgent := c.GetHeader("User-Agent")
	if userAgent != "" {
		clientInfo.UserAgent = &userAgent
	}
	clientIP := c.ClientIP()
	ipAddress, err := netip.ParseAddr(clientIP)
	if err == nil {
		clientInfo.IPAddress = &ipAddress
	}

	return clientInfo
}

func GetFromContext[T any](c *gin.Context, key string) (T, error) {
	var empty T

	value, exists := c.Get(key)
	if !exists {
		return empty, fmt.Errorf("key %q not found in context", key)
	}

	typedValue, ok := value.(T)
	if !ok {
		return empty, fmt.Errorf("key %q not found in context", key)
	}

	return typedValue, nil
}
