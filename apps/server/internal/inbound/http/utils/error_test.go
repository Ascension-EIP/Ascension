// @date 2026-11-13
// @file error_test.go
// @brief Unit tests of the mapping of the domain errors to HTTP responses.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package utils

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/knownbug"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/gin-gonic/gin"
)

func TestMain(m *testing.M) {
	gin.SetMode(gin.TestMode)
	os.Exit(m.Run())
}

func newContext(req *http.Request) (*gin.Context, *httptest.ResponseRecorder) {
	rec := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(rec)
	if req == nil {
		req = httptest.NewRequest(http.MethodGet, "/", nil)
	}
	c.Request = req
	return c, rec
}

// knownBug skips a test that asserts the expected behaviour of a bug not fixed yet. Set
// RUN_KNOWN_BUGS=1 to run it anyway and see it fail.
func knownBug(t *testing.T, bug string) {
	t.Helper()
	knownbug.Skip(t, bug)
}

func TestErrorNilWritesNothing(t *testing.T) {
	c, rec := newContext(nil)
	Error(c, nil)

	if c.Writer.Written() || rec.Body.Len() != 0 || len(c.Errors) != 0 {
		t.Errorf("Error(nil) wrote %d %q, errors %v, want nothing", rec.Code, rec.Body.String(), c.Errors)
	}
}

func TestErrorMapping(t *testing.T) {
	tests := []struct {
		err  error
		want int
	}{
		{model.ErrInvalidInput, http.StatusUnprocessableEntity},
		{model.ErrEmailDuplicated, http.StatusConflict},
		{model.ErrFriendshipExists, http.StatusConflict},
		{model.ErrUserNotFound, http.StatusNotFound},
		{model.ErrClimbingSessionNotFound, http.StatusNotFound},
		{model.ErrAnalysisNotFound, http.StatusNotFound},
		{model.ErrUserBodyConstraintNotFound, http.StatusNotFound},
		{model.ErrFriendRequestNotFound, http.StatusNotFound},
		{model.ErrInternalDB, http.StatusInternalServerError},
		{model.ErrUnknown, http.StatusInternalServerError},
		{errors.New("anything else"), http.StatusInternalServerError},
	}

	for _, tt := range tests {
		for _, err := range []error{tt.err, fmt.Errorf("service: %w", tt.err)} {
			t.Run(err.Error(), func(t *testing.T) {
				c, rec := newContext(nil)
				Error(c, err)

				if rec.Code != tt.want {
					t.Errorf("status = %d, want %d", rec.Code, tt.want)
				}
				var body response.Error
				if decodeErr := json.Unmarshal(rec.Body.Bytes(), &body); decodeErr != nil || body.Message != err.Error() {
					t.Errorf("body = %s, want the error message %q", rec.Body.String(), err.Error())
				}

				// Only the unexpected errors are attached to the gin context.
				if attached := len(c.Errors) == 1; attached != (tt.want == http.StatusInternalServerError) {
					t.Errorf("c.Errors = %v, want attached only on 500", c.Errors)
				}
			})
		}
	}
}

func TestErrorMappingOfUnmappedDomainErrors(t *testing.T) {
	knownBug(t, "utils.Error has no case for these domain errors, so every one of them answers 500")

	tests := []struct {
		err  error
		want int
	}{
		{model.ErrNotFound, http.StatusNotFound},
		{model.ErrConflict, http.StatusConflict},
		{model.ErrBadPassword, http.StatusUnauthorized},
		{model.ErrInvalidToken, http.StatusUnauthorized},
		{model.ErrVideoNotFound, http.StatusNotFound},
		{model.ErrVideoUploading, http.StatusConflict},
	}

	for _, tt := range tests {
		t.Run(tt.err.Error(), func(t *testing.T) {
			c, rec := newContext(nil)
			Error(c, tt.err)
			if rec.Code != tt.want {
				t.Errorf("status = %d, want %d", rec.Code, tt.want)
			}
		})
	}
}
