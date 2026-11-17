// @date 2026-11-13
// @file validate_test.go
// @brief Unit tests of the shared length, range and time range validators.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"testing"
	"time"
)

func TestValidateStringLen(t *testing.T) {
	tests := []struct {
		value   string
		wantErr string
	}{
		{value: "ab", wantErr: "too short"},
		{value: "abc"},
		{value: "abcde"},
		{value: "abcdef", wantErr: "too long"},
	}

	for _, tt := range tests {
		err := validateStringLen(tt.value, 3, 5)
		if got := errString(err); got != tt.wantErr {
			t.Errorf("validateStringLen(%q, 3, 5) = %q, want %q", tt.value, got, tt.wantErr)
		}
	}
}

func TestValidateRange(t *testing.T) {
	if got := errString(validateRange(int64(-1), 0, 10)); got != "below minimum" {
		t.Errorf("validateRange(-1, 0, 10) = %q, want below minimum", got)
	}
	if got := errString(validateRange(int64(11), 0, 10)); got != "above maximum" {
		t.Errorf("validateRange(11, 0, 10) = %q, want above maximum", got)
	}
	for _, v := range []int64{0, 5, 10} {
		if err := validateRange(v, 0, 10); err != nil {
			t.Errorf("validateRange(%d, 0, 10) = %v, want nil", v, err)
		}
	}
	if err := validateRange(float64(1.5), 1, 2); err != nil {
		t.Errorf("validateRange(1.5, 1, 2) = %v, want nil", err)
	}
	if err := validateRange(uint8(255), 0, 254); err == nil {
		t.Error("validateRange(uint8 255, 0, 254) = nil, want an error")
	}
}

func TestValidateTimeRange(t *testing.T) {
	start := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	end := start.Add(24 * time.Hour)

	tests := []struct {
		name    string
		value   time.Time
		wantErr bool
	}{
		{name: "at start", value: start},
		{name: "inside", value: start.Add(time.Hour)},
		{name: "at end", value: end},
		{name: "before", value: start.Add(-time.Nanosecond), wantErr: true},
		{name: "after", value: end.Add(time.Nanosecond), wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := validateTimeRange(tt.value, start, end); (err != nil) != tt.wantErr {
				t.Errorf("validateTimeRange() = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func errString(err error) string {
	if err == nil {
		return ""
	}
	return err.Error()
}
