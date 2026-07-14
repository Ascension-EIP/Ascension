package logger

import (
	"io"
	"os"
	"time"

	"github.com/rs/zerolog"
)

func New(level string, pretty bool) zerolog.Logger {
	var output io.Writer = os.Stdout
	if pretty {
		output = zerolog.ConsoleWriter{
			Out:         os.Stdout,
			TimeFormat:  time.RFC3339,
			FieldsOrder: []string{"time", "level", "request_id", "ip", "method", "path", "status", "latency"},
		}
	}

	lvl := parseLevel(level)

	return zerolog.New(output).Level(lvl).With().Timestamp().Logger()
}

func parseLevel(level string) zerolog.Level {
	switch level {
	case "debug":
		return zerolog.DebugLevel
	case "info":
		return zerolog.InfoLevel
	case "warn":
		return zerolog.WarnLevel
	case "error":
		return zerolog.ErrorLevel
	default:
		return zerolog.InfoLevel
	}
}
