// @date 2026-11-12
// @file climbing_session_test.go
// @brief Unit tests of the climbing session validation rules and of the pagination.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"errors"
	"strings"
	"testing"
	"time"
)

func TestClimbingSessionConfigValidate(t *testing.T) {
	tests := []struct {
		name    string
		config  ClimbingSessionConfig
		wantErr bool
	}{
		{name: "empty private session", config: ClimbingSessionConfig{Visibility: VisibilityPrivate}},
		{name: "full session", config: ClimbingSessionConfig{Title: new("Arkose Nation"), Notes: new("Worked on heel hooks"), Visibility: VisibilityFriends}},
		{name: "empty notes", config: ClimbingSessionConfig{Notes: new(""), Visibility: VisibilityPublic}},
		{name: "unknown visibility", config: ClimbingSessionConfig{Visibility: "everyone"}, wantErr: true},
		{name: "missing visibility", config: ClimbingSessionConfig{}, wantErr: true},
		{name: "blank title", config: ClimbingSessionConfig{Title: new("   "), Visibility: VisibilityPrivate}, wantErr: true},
		{name: "title too long", config: ClimbingSessionConfig{Title: new(strings.Repeat("a", ClimbingSessionTitleMaxLen+1)), Visibility: VisibilityPrivate}, wantErr: true},
		{name: "notes too long", config: ClimbingSessionConfig{Notes: new(strings.Repeat("a", ClimbingSessionNotesMaxLen+1)), Visibility: VisibilityPrivate}, wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()
			if tt.wantErr {
				if !errors.Is(err, ErrInvalidInput) {
					t.Fatalf("Validate() = %v, want ErrInvalidInput", err)
				}
				return
			}
			if err != nil {
				t.Fatalf("Validate() = %v, want nil", err)
			}
		})
	}
}

func TestClimbingSessionPartialValidate(t *testing.T) {
	startedAt := time.Date(2026, 11, 12, 18, 0, 0, 0, time.UTC)
	session := ClimbingSession{StartedAt: startedAt}

	tests := []struct {
		name    string
		partial ClimbingSessionPartial
		wantErr bool
	}{
		{name: "nothing", partial: ClimbingSessionPartial{}},
		{name: "end after start", partial: ClimbingSessionPartial{EndedAt: new(new(startedAt.Add(2 * time.Hour)))}},
		{name: "end at start", partial: ClimbingSessionPartial{EndedAt: new(new(startedAt))}},
		{name: "reopen", partial: ClimbingSessionPartial{EndedAt: new((*time.Time)(nil))}},
		{name: "clear title and notes", partial: ClimbingSessionPartial{Title: new((*string)(nil)), Notes: new((*string)(nil))}},
		{name: "rename", partial: ClimbingSessionPartial{Title: new(new("Bloc session"))}},
		{name: "end before start", partial: ClimbingSessionPartial{EndedAt: new(new(startedAt.Add(-time.Minute)))}, wantErr: true},
		{name: "blank title", partial: ClimbingSessionPartial{Title: new(new(""))}, wantErr: true},
		{name: "notes too long", partial: ClimbingSessionPartial{Notes: new(new(strings.Repeat("a", ClimbingSessionNotesMaxLen+1)))}, wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.partial.Validate(session)
			if tt.wantErr {
				if !errors.Is(err, ErrInvalidInput) {
					t.Fatalf("Validate() = %v, want ErrInvalidInput", err)
				}
				return
			}
			if err != nil {
				t.Fatalf("Validate() = %v, want nil", err)
			}
		})
	}
}

func TestClimbingSessionPartialIsEmpty(t *testing.T) {
	if !(ClimbingSessionPartial{}).IsEmpty() {
		t.Error("IsEmpty() = false for a partial without fields")
	}
	if (ClimbingSessionPartial{EndedAt: new((*time.Time)(nil))}).IsEmpty() {
		t.Error("IsEmpty() = true for a partial that clears ended_at")
	}
}

func TestNewPagination(t *testing.T) {
	tests := []struct {
		name    string
		limit   *int
		offset  *int
		want    Pagination
		wantErr bool
	}{
		{name: "defaults", want: Pagination{Limit: PaginationDefaultLimit, Offset: 0}},
		{name: "explicit values", limit: new(5), offset: new(10), want: Pagination{Limit: 5, Offset: 10}},
		{name: "max limit", limit: new(PaginationMaxLimit), want: Pagination{Limit: PaginationMaxLimit}},
		{name: "zero limit", limit: new(0), wantErr: true},
		{name: "limit too big", limit: new(PaginationMaxLimit + 1), wantErr: true},
		{name: "negative offset", offset: new(-1), wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := NewPagination(tt.limit, tt.offset)
			if tt.wantErr {
				if !errors.Is(err, ErrInvalidInput) {
					t.Fatalf("NewPagination() error = %v, want ErrInvalidInput", err)
				}
				return
			}
			if err != nil {
				t.Fatalf("NewPagination() error = %v", err)
			}
			if got != tt.want {
				t.Errorf("NewPagination() = %+v, want %+v", got, tt.want)
			}
		})
	}
}
