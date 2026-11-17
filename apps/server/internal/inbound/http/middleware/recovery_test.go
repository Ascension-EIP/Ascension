// @date 2026-11-13
// @file recovery_test.go
// @brief Unit tests of the panic recovery middleware and of the broken pipe detection.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package middleware

import (
	"encoding/json"
	"errors"
	"net"
	"net/http"
	"os"
	"strings"
	"syscall"
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/gin-gonic/gin"
)

func opError(err error) *net.OpError {
	return &net.OpError{Op: "write", Net: "tcp", Err: &os.SyscallError{Syscall: "write", Err: err}}
}

func TestIsBrokenPipe(t *testing.T) {
	tests := []struct {
		name string
		err  any
		want bool
	}{
		{"broken pipe", opError(syscall.EPIPE), true},
		{"connection reset", opError(syscall.ECONNRESET), true},
		{"connection aborted", opError(errors.New("connection aborted")), true},
		{"other syscall error", opError(syscall.ENOSPC), false},
		{"op error without syscall error", &net.OpError{Op: "dial", Err: errors.New("broken pipe")}, false},
		{"plain error", errors.New("broken pipe"), false},
		{"string", "broken pipe", false},
		{"nil", nil, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := isBrokenPipe(tt.err); got != tt.want {
				t.Errorf("isBrokenPipe(%v) = %v, want %v", tt.err, got, tt.want)
			}
		})
	}
}

func recoveryEngine(handler gin.HandlerFunc) *gin.Engine {
	engine := gin.New()
	engine.Use(Recovery())
	engine.GET("/boom", handler)
	return engine
}

func TestRecoveryAnswers500OnPanic(t *testing.T) {
	for _, value := range []any{"boom", errors.New("boom"), 42} {
		records := captureLogs(t)
		engine := recoveryEngine(func(*gin.Context) { panic(value) })

		rec := serve(engine, http.MethodGet, "/boom?x=1", "", nil)
		if rec.Code != http.StatusInternalServerError {
			t.Fatalf("panic(%v): status = %d, want 500", value, rec.Code)
		}
		var body response.Error
		if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil || body.Message != "Internal server error" {
			t.Errorf("panic(%v): body = %s, want the generic error", value, rec.Body.String())
		}

		logs := records()
		if len(logs) != 1 || logs[0]["msg"] != "panic recovered" || logs[0]["level"] != "ERROR" {
			t.Fatalf("panic(%v): logs = %v, want one panic recovered error", value, logs)
		}
		if stack, _ := logs[0]["stack"].(string); !strings.Contains(stack, "recovery") {
			t.Errorf("panic(%v): stack = %q, want the goroutine stack", value, stack)
		}
		if group(t, logs[0], "request")["path"] != "/boom" {
			t.Errorf("panic(%v): logged request = %v", value, logs[0]["request"])
		}
	}
}

func TestRecoveryAbortsSilentlyOnBrokenPipe(t *testing.T) {
	records := captureLogs(t)
	after := false
	engine := gin.New()
	engine.Use(Recovery())
	engine.Use(func(c *gin.Context) {
		c.Next()
		after = true
	})
	engine.GET("/boom", func(*gin.Context) { panic(opError(syscall.EPIPE)) })

	rec := serve(engine, http.MethodGet, "/boom", "", nil)
	if rec.Body.Len() != 0 {
		t.Errorf("body = %q, want nothing written to a broken connection", rec.Body.String())
	}
	if after {
		t.Error("the middleware after the panic resumed")
	}

	logs := records()
	if len(logs) != 1 || logs[0]["msg"] != "client connection broken" {
		t.Errorf("logs = %v, want one client connection broken record", logs)
	}
}

func TestRecoveryLetsNormalRequestsThrough(t *testing.T) {
	records := captureLogs(t)
	engine := recoveryEngine(func(c *gin.Context) { c.String(http.StatusOK, "ok") })

	rec := serve(engine, http.MethodGet, "/boom", "", nil)
	if rec.Code != http.StatusOK || rec.Body.String() != "ok" {
		t.Errorf("response = %d %q, want 200 ok", rec.Code, rec.Body.String())
	}
	if logs := records(); len(logs) != 0 {
		t.Errorf("logs = %v, want none", logs)
	}
}
