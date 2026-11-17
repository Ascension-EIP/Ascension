// @date 2026-11-13
// @file middleware_test.go
// @brief Test helpers of the middleware tests: a gin engine, a request helper and a captured slog output.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package middleware

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestMain(m *testing.M) {
	gin.SetMode(gin.TestMode)
	os.Exit(m.Run())
}

// serve sends a request to the engine from the remote address and returns the response.
func serve(engine *gin.Engine, method string, target string, remoteAddr string, header map[string]string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(method, target, nil)
	if remoteAddr != "" {
		req.RemoteAddr = remoteAddr
	}
	for k, v := range header {
		req.Header.Set(k, v)
	}

	rec := httptest.NewRecorder()
	engine.ServeHTTP(rec, req)
	return rec
}

// captureLogs sends the default slog logger to a buffer for the test, and returns a
// function that decodes the JSON records written so far.
func captureLogs(t *testing.T) func() []map[string]any {
	t.Helper()

	var buf bytes.Buffer
	previous := slog.Default()
	slog.SetDefault(slog.New(slog.NewJSONHandler(&buf, &slog.HandlerOptions{Level: slog.LevelDebug})))
	t.Cleanup(func() { slog.SetDefault(previous) })

	return func() []map[string]any {
		records := []map[string]any{}
		for line := range strings.SplitSeq(strings.TrimSpace(buf.String()), "\n") {
			if line == "" {
				continue
			}
			record := map[string]any{}
			if err := json.Unmarshal([]byte(line), &record); err != nil {
				t.Fatalf("Unmarshal(%s) error = %v", line, err)
			}
			records = append(records, record)
		}
		return records
	}
}

// group returns a nested group of a log record.
func group(t *testing.T, record map[string]any, name string) map[string]any {
	t.Helper()

	g, ok := record[name].(map[string]any)
	if !ok {
		t.Fatalf("record %v has no %q group", record, name)
	}
	return g
}
