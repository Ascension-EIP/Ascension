// @date 2026-09-20
// @file validate.go
// @brief Generic validation helpers shared across models.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"fmt"
	"time"
)

func validateStringLen(value string, min int, max int) error {
	if len(value) < min {
		return fmt.Errorf("too short")
	}
	if len(value) > max {
		return fmt.Errorf("too long")
	}
	return nil
}

func validateRange[T int8 | int16 | int32 | int64 | uint8 | uint16 | uint32 | uint64 | float32 | float64](
	value, min, max T,
) error {
	if value < min {
		return fmt.Errorf("below minimum")
	}
	if value > max {
		return fmt.Errorf("above maximum")
	}
	return nil
}

func validateTimeRange(t, min, max time.Time) error {
	if t.Before(min) || t.After(max) {
		return fmt.Errorf("out of range")
	}
	return nil
}
