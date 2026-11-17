// @date 2026-11-13
// @file context_test.go
// @brief Unit tests of the client information and typed context value helpers.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package utils

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

func TestClientInfo(t *testing.T) {
	tests := []struct {
		name       string
		remoteAddr string
		userAgent  string
		wantIP     string
	}{
		{"ipv4 and user agent", "203.0.113.7:4242", "ascension/1.0", "203.0.113.7"},
		{"ipv6", "[2001:db8::1]:4242", "ascension/1.0", "2001:db8::1"},
		{"no user agent", "203.0.113.7:4242", "", "203.0.113.7"},
		{"unparsable address", "not-an-address", "ascension/1.0", ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/", nil)
			req.RemoteAddr = tt.remoteAddr
			req.Header.Del("User-Agent")
			if tt.userAgent != "" {
				req.Header.Set("User-Agent", tt.userAgent)
			}
			c, _ := newContext(req)

			info := ClientInfo(c)

			switch {
			case tt.userAgent == "" && info.UserAgent != nil:
				t.Errorf("UserAgent = %q, want nil", *info.UserAgent)
			case tt.userAgent != "" && (info.UserAgent == nil || *info.UserAgent != tt.userAgent):
				t.Errorf("UserAgent = %v, want %q", info.UserAgent, tt.userAgent)
			}
			switch {
			case tt.wantIP == "" && info.IPAddress != nil:
				t.Errorf("IPAddress = %v, want nil", info.IPAddress)
			case tt.wantIP != "" && (info.IPAddress == nil || info.IPAddress.String() != tt.wantIP):
				t.Errorf("IPAddress = %v, want %s", info.IPAddress, tt.wantIP)
			}
		})
	}
}

func TestGetFromContext(t *testing.T) {
	c, _ := newContext(nil)
	user := model.User{Username: "climber1"}
	c.Set("user", user)
	c.Set("count", 3)

	got, err := GetFromContext[model.User](c, "user")
	if err != nil || got.Username != "climber1" {
		t.Errorf("GetFromContext(user) = %+v, %v, want the stored user", got, err)
	}

	if got, err := GetFromContext[model.User](c, "missing"); err == nil || got.Username != "" {
		t.Errorf("GetFromContext(missing) = %+v, %v, want the zero value and an error", got, err)
	}
	if got, err := GetFromContext[model.User](c, "count"); err == nil || got.Username != "" {
		t.Errorf("GetFromContext(count as User) = %+v, %v, want the zero value and an error", got, err)
	}
	if got, err := GetFromContext[*model.User](c, "user"); err == nil || got != nil {
		t.Errorf("GetFromContext(user as *User) = %v, %v, want nil and an error", got, err)
	}
	if got, err := GetFromContext[int](c, "count"); err != nil || got != 3 {
		t.Errorf("GetFromContext(count) = %d, %v, want 3", got, err)
	}
}
