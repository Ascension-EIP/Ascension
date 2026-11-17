// @date 2026-11-13
// @file logger_test.go
// @brief Unit tests of the slog logger: level parsing and JSON or text output.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package logger

import (
	"bytes"
	"encoding/json"
	"io"
	"log/slog"
	"os"
	"strings"
	"testing"
)

func TestParseLevel(t *testing.T) {
	tests := map[string]slog.Level{
		"debug":   slog.LevelDebug,
		"DEBUG":   slog.LevelDebug,
		"info":    slog.LevelInfo,
		"Warn":    slog.LevelWarn,
		"error":   slog.LevelError,
		"":        slog.LevelInfo,
		"verbose": slog.LevelInfo,
	}
	for level, want := range tests {
		t.Run(level, func(t *testing.T) {
			if got := parseLevel(level); got != want {
				t.Errorf("parseLevel(%q) = %v, want %v", level, got, want)
			}
		})
	}
}

// captureStdout replaces os.Stdout while fn builds and uses a logger, and returns what
// was written to it.
func captureStdout(t *testing.T, fn func()) string {
	t.Helper()

	r, w, err := os.Pipe()
	if err != nil {
		t.Fatalf("Pipe() error = %v", err)
	}
	stdout := os.Stdout
	os.Stdout = w
	defer func() { os.Stdout = stdout }()

	fn()

	if err := w.Close(); err != nil {
		t.Fatalf("Close() error = %v", err)
	}
	var out bytes.Buffer
	if _, err := io.Copy(&out, r); err != nil {
		t.Fatalf("Copy() error = %v", err)
	}

	return out.String()
}

func TestNewJSON(t *testing.T) {
	out := captureStdout(t, func() {
		l := New("warn", false)
		l.Info("dropped")
		l.Warn("kept", slog.String("key", "value"))
	})

	lines := strings.Split(strings.TrimSpace(out), "\n")
	if len(lines) != 1 {
		t.Fatalf("output = %q, want only the warning", out)
	}
	var record map[string]any
	if err := json.Unmarshal([]byte(lines[0]), &record); err != nil {
		t.Fatalf("Unmarshal(%q) error = %v, want JSON", lines[0], err)
	}
	if record["msg"] != "kept" || record["level"] != "WARN" || record["key"] != "value" {
		t.Errorf("record = %v, want the warning with its attribute", record)
	}
}

func TestNewPretty(t *testing.T) {
	out := captureStdout(t, func() {
		l := New("debug", true)
		l.Debug("details", slog.Int("count", 3))
	})

	if !strings.Contains(out, "level=DEBUG") || !strings.Contains(out, "msg=details") || !strings.Contains(out, "count=3") {
		t.Errorf("output = %q, want a text record at debug level", out)
	}
	if strings.HasPrefix(strings.TrimSpace(out), "{") {
		t.Errorf("output = %q, want text, not JSON", out)
	}
}
