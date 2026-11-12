// @date 2026-11-12
// @file climbing_session_test.go
// @brief Unit tests of the climbing session request DTOs and of the Optional JSON field.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

func TestUpdateClimbingSessionDecoding(t *testing.T) {
	endedAt := time.Date(2026, 11, 12, 20, 30, 0, 0, time.UTC)
	id, userID := uuid.NewV7(), uuid.NewV7()

	t.Run("absent fields stay unchanged", func(t *testing.T) {
		partial := decodeUpdate(t, `{}`).IntoPartial(id, userID)
		if partial.Title != nil || partial.Notes != nil || partial.EndedAt != nil {
			t.Fatalf("IntoPartial() = %+v, want no field set", partial)
		}
		if partial.ID != id || partial.UserID != userID {
			t.Fatalf("IntoPartial() ids = %v/%v, want %v/%v", partial.ID, partial.UserID, id, userID)
		}
	})

	t.Run("null clears the field", func(t *testing.T) {
		partial := decodeUpdate(t, `{"title": null, "ended_at": null}`).IntoPartial(id, userID)
		if partial.Title == nil || *partial.Title != nil {
			t.Fatalf("Title = %v, want a pointer to nil", partial.Title)
		}
		if partial.EndedAt == nil || *partial.EndedAt != nil {
			t.Fatalf("EndedAt = %v, want a pointer to nil", partial.EndedAt)
		}
		if partial.Notes != nil {
			t.Fatalf("Notes = %v, want nil", partial.Notes)
		}
	})

	t.Run("values are set", func(t *testing.T) {
		partial := decodeUpdate(t, `{"title": "Evening bloc", "notes": "", "ended_at": "2026-11-12T20:30:00Z"}`).IntoPartial(id, userID)
		if partial.Title == nil || *partial.Title == nil || **partial.Title != "Evening bloc" {
			t.Fatalf("Title = %v, want Evening bloc", partial.Title)
		}
		if partial.Notes == nil || *partial.Notes == nil || **partial.Notes != "" {
			t.Fatalf("Notes = %v, want an empty string", partial.Notes)
		}
		if partial.EndedAt == nil || *partial.EndedAt == nil || !(**partial.EndedAt).Equal(endedAt) {
			t.Fatalf("EndedAt = %v, want %v", partial.EndedAt, endedAt)
		}
	})

	t.Run("wrong type is rejected", func(t *testing.T) {
		var req UpdateClimbingSession
		if err := json.Unmarshal([]byte(`{"ended_at": "tomorrow"}`), &req); err == nil {
			t.Fatal("Unmarshal() error = nil, want an error for an invalid timestamp")
		}
	})
}

func TestStartClimbingSessionDefaultsToPrivate(t *testing.T) {
	config := StartClimbingSession{}.IntoClimbingSessionConfig()
	if config.Visibility != model.VisibilityPrivate {
		t.Errorf("Visibility = %q, want %q", config.Visibility, model.VisibilityPrivate)
	}

	config = StartClimbingSession{Visibility: new("public")}.IntoClimbingSessionConfig()
	if config.Visibility != model.VisibilityPublic {
		t.Errorf("Visibility = %q, want %q", config.Visibility, model.VisibilityPublic)
	}
}

func decodeUpdate(t *testing.T, body string) UpdateClimbingSession {
	t.Helper()

	var req UpdateClimbingSession
	if err := json.Unmarshal([]byte(body), &req); err != nil {
		t.Fatalf("Unmarshal(%s) error = %v", body, err)
	}

	return req
}
