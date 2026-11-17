// @date 2026-11-12
// @file router_test.go
// @brief Unit tests of the liveness probe.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestHealthz(t *testing.T) {
	gin.SetMode(gin.TestMode)
	app := gin.New()
	app.GET("/healthz", Healthz)
	app.HEAD("/healthz", Healthz)

	for _, method := range []string{http.MethodGet, http.MethodHead} {
		t.Run(method, func(t *testing.T) {
			rec := httptest.NewRecorder()
			app.ServeHTTP(rec, httptest.NewRequest(method, "/healthz", nil))
			if rec.Code != http.StatusOK {
				t.Errorf("%s /healthz = %d, want %d", method, rec.Code, http.StatusOK)
			}
		})
	}
}
