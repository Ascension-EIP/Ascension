// @date 2026-11-13
// @file context_test.go
// @brief Unit test of the context keys shared by the middlewares and the handlers.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package macro

import "testing"

// Me must not be empty nor collide with the "request_id" key set by the RequestID
// middleware in the same gin context.
func TestMeKey(t *testing.T) {
	if Me == "" || Me == "request_id" {
		t.Errorf("Me = %q, want a non-empty key distinct from request_id", Me)
	}
}
