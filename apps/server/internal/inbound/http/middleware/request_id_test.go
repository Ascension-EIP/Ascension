// @date 2026-11-13
// @file request_id_test.go
// @brief Unit tests of the request ID middleware.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package middleware

import (
	"net/http"
	"testing"

	"uuid"

	"github.com/gin-gonic/gin"
)

func TestRequestID(t *testing.T) {
	var inContext string
	engine := gin.New()
	engine.Use(RequestID())
	engine.GET("/", func(c *gin.Context) {
		inContext = c.GetString("request_id")
		c.Status(http.StatusOK)
	})

	seen := map[string]bool{}
	for range 3 {
		rec := serve(engine, http.MethodGet, "/", "", nil)
		header := rec.Header().Get("X-Request-ID")

		id, err := uuid.Parse(header)
		if err != nil {
			t.Fatalf("X-Request-ID = %q, want a UUID: %v", header, err)
		}
		if version := id[6] >> 4; version != 7 {
			t.Errorf("X-Request-ID version = %d, want 7", version)
		}
		if inContext != header {
			t.Errorf("context request_id = %q, want the header %q", inContext, header)
		}
		if seen[header] {
			t.Errorf("request ID %s reused", header)
		}
		seen[header] = true
	}
}

func TestRequestIDIsSetOnUnknownRoutes(t *testing.T) {
	engine := gin.New()
	engine.Use(RequestID())

	if rec := serve(engine, http.MethodGet, "/missing", "", nil); rec.Header().Get("X-Request-ID") == "" {
		t.Error("no X-Request-ID on a 404")
	}
}
