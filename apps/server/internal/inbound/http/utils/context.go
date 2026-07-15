// @date 2026-03-11
// @file context.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package utils

import (
	"fmt"

	"github.com/gin-gonic/gin"
)

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
