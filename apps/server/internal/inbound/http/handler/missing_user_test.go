// @date 2026-11-14
// @file missing_user_test.go
// @brief Unit tests that the video and analysis handlers answer 500 when no authenticated user is in the context.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package handler

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

// TestHandlersWithoutAuthenticatedUser calls each handler that reads the user set by the auth
// middleware without that middleware: a route wired without it must fail closed with a 500, never
// reach the service. The handlers hold no service here, so reaching it would panic.
func TestHandlersWithoutAuthenticatedUser(t *testing.T) {
	gin.SetMode(gin.TestMode)
	videoH := NewVideoHandler(nil)
	analysisH := NewAnalysisHandler(nil)

	handlers := map[string]gin.HandlerFunc{
		"VideoHandler.GetDownloadURL": videoH.GetDownloadURL,
		"VideoHandler.GetUploadURL":   videoH.GetUploadURL,
		"VideoHandler.UploadComplete": videoH.UploadComplete,
		"VideoHandler.GetVideo":       videoH.GetVideo,
		"VideoHandler.ListVideos":     videoH.ListVideos,
		"AnalysisHandler.Create":      analysisH.Create,
		"AnalysisHandler.List":        analysisH.List,
	}

	for name, handle := range handlers {
		t.Run(name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(rec)
			c.Request = httptest.NewRequest(http.MethodGet, "/", nil)

			handle(c)

			// Gin writes the status set by c.Status at the end of the request, so it is read from the writer.
			if got := c.Writer.Status(); got != http.StatusInternalServerError {
				t.Errorf("status = %d, want %d", got, http.StatusInternalServerError)
			}
		})
	}
}
