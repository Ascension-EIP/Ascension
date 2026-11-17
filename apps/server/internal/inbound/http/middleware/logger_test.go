// @date 2026-11-13
// @file logger_test.go
// @brief Unit tests of the request logging middleware.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package middleware

import (
	"net/http"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestLoggerLogsEveryRequest(t *testing.T) {
	tests := []struct {
		status int
		level  string
	}{
		{http.StatusOK, "INFO"},
		{http.StatusNotFound, "INFO"},
		{http.StatusInternalServerError, "ERROR"},
		{http.StatusServiceUnavailable, "ERROR"},
	}

	for _, tt := range tests {
		t.Run(http.StatusText(tt.status), func(t *testing.T) {
			records := captureLogs(t)
			engine := gin.New()
			engine.Use(Logger())
			engine.GET("/climbs", func(c *gin.Context) { c.Status(tt.status) })

			serve(engine, http.MethodGet, "/climbs?grade=7a&grade=7b", "203.0.113.7:4242", map[string]string{"User-Agent": "ascension-test"})

			logs := records()
			if len(logs) != 1 {
				t.Fatalf("%d log records, want 1", len(logs))
			}
			record := logs[0]
			if record["msg"] != "request_completed" || record["level"] != tt.level {
				t.Errorf("msg / level = %v / %v, want request_completed / %s", record["msg"], record["level"], tt.level)
			}

			request := group(t, record, "request")
			if request["method"] != "GET" || request["path"] != "/climbs" || request["ip"] != "203.0.113.7" || request["user_agent"] != "ascension-test" {
				t.Errorf("request = %v", request)
			}
			params, _ := request["params"].(map[string]any)
			if grades, _ := params["grade"].([]any); len(grades) != 2 {
				t.Errorf("params = %v, want both grade values", request["params"])
			}

			response := group(t, record, "response")
			if response["status"] != float64(tt.status) {
				t.Errorf("response status = %v, want %d", response["status"], tt.status)
			}
			if _, ok := response["latency"]; !ok {
				t.Error("response has no latency")
			}
		})
	}
}

func TestLoggerLogsUnknownRoutes(t *testing.T) {
	records := captureLogs(t)
	engine := gin.New()
	engine.Use(Logger())

	serve(engine, http.MethodGet, "/missing", "", nil)

	logs := records()
	if len(logs) != 1 || group(t, logs[0], "response")["status"] != float64(http.StatusNotFound) {
		t.Errorf("logs = %v, want one 404 record", logs)
	}
}
