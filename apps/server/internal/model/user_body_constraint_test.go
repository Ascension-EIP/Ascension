// @date 2026-11-13
// @file user_body_constraint_test.go
// @brief Unit tests of the body constraint validation.
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

func TestBodyZoneValidate(t *testing.T) {
	if len(BodyZones) != 30 {
		t.Fatalf("len(BodyZones) = %d, want the 30 values of the body_zone enum", len(BodyZones))
	}
	for _, zone := range BodyZones {
		if err := zone.Validate(); err != nil {
			t.Errorf("BodyZone(%q).Validate() = %v, want nil", zone, err)
		}
	}
	for _, zone := range []BodyZone{"", "left_arm", "Left_Knee", "tail"} {
		if err := zone.Validate(); err == nil {
			t.Errorf("BodyZone(%q).Validate() = nil, want an error", zone)
		}
	}
}

func TestBodyConstraintTypeValidate(t *testing.T) {
	for _, constraintType := range []BodyConstraintType{BodyConstraintMissing, BodyConstraintInjured} {
		if err := constraintType.Validate(); err != nil {
			t.Errorf("BodyConstraintType(%q).Validate() = %v, want nil", constraintType, err)
		}
	}
	// The issue spoke of injury and missing_limb: the database enum is missing and injured.
	for _, constraintType := range []BodyConstraintType{"", "injury", "missing_limb", "INJURED"} {
		if err := constraintType.Validate(); err == nil {
			t.Errorf("BodyConstraintType(%q).Validate() = nil, want an error", constraintType)
		}
	}
}

func TestUserBodyConstraintConfigValidate(t *testing.T) {
	now := time.Date(2026, 11, 13, 10, 0, 0, 0, time.UTC)
	tomorrow := now.AddDate(0, 0, 1)
	inTwoDays := now.AddDate(0, 0, 2)
	lastYear := now.AddDate(-1, 0, 0)
	longNote := strings.Repeat("a", UserBodyConstraintNoteMaxLen+1)
	maxNote := strings.Repeat("a", UserBodyConstraintNoteMaxLen)

	tests := []struct {
		name    string
		config  UserBodyConstraintConfig
		wantErr bool
	}{
		{name: "injury today", config: UserBodyConstraintConfig{Zone: "left_knee", Type: BodyConstraintInjured}},
		{name: "missing hand with a note", config: UserBodyConstraintConfig{Zone: "right_hand", Type: BodyConstraintMissing, Note: &maxNote}},
		{name: "injury last year", config: UserBodyConstraintConfig{Zone: "lower_back", Type: BodyConstraintInjured, StartedAt: &lastYear}},
		{name: "tomorrow, for the time zone", config: UserBodyConstraintConfig{Zone: "neck", Type: BodyConstraintInjured, StartedAt: &tomorrow}},
		{name: "unknown zone", config: UserBodyConstraintConfig{Zone: "wing", Type: BodyConstraintInjured}, wantErr: true},
		{name: "unknown type", config: UserBodyConstraintConfig{Zone: "neck", Type: "injury"}, wantErr: true},
		{name: "note too long", config: UserBodyConstraintConfig{Zone: "neck", Type: BodyConstraintInjured, Note: &longNote}, wantErr: true},
		{name: "starts in two days", config: UserBodyConstraintConfig{Zone: "neck", Type: BodyConstraintInjured, StartedAt: &inTwoDays}, wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate(now)
			if tt.wantErr && !errors.Is(err, ErrInvalidInput) {
				t.Errorf("Validate() = %v, want ErrInvalidInput", err)
			}
			if !tt.wantErr && err != nil {
				t.Errorf("Validate() = %v, want nil", err)
			}
		})
	}
}
