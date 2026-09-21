// @date 2026-09-09
// @file logger.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package logger

import (
	"io"
	"log/slog"
	"os"
	"strings"
)

func New(level string, pretty bool) *slog.Logger {
	var output io.Writer = os.Stdout

	handlerOpts := &slog.HandlerOptions{Level: parseLevel(level)}

	var handler slog.Handler
	if pretty {
		handler = slog.NewTextHandler(output, handlerOpts)
	} else {
		handler = slog.NewJSONHandler(output, handlerOpts)
	}

	return slog.New(handler)
}

func parseLevel(level string) slog.Level {
	switch strings.ToLower(level) {
	case "debug":
		return slog.LevelDebug
	case "info":
		return slog.LevelInfo
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}
