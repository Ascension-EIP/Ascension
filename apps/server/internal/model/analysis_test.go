// @date 2026-11-13
// @file analysis_test.go
// @brief Unit tests of the analysis type, job status and configuration rules.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"strings"
	"testing"
)

func TestAnalysisTypeValidate(t *testing.T) {
	for _, analysisType := range []AnalysisType{AnalysisType2D, AnalysisType3D} {
		if err := analysisType.Validate(); err != nil {
			t.Errorf("Validate(%q) = %v, want nil", analysisType, err)
		}
	}
	for _, analysisType := range []AnalysisType{"", "4d", "2D"} {
		if err := analysisType.Validate(); err == nil {
			t.Errorf("Validate(%q) = nil, want an error", analysisType)
		}
	}
}

func TestJobStatusValidate(t *testing.T) {
	for _, status := range []JobStatus{JobStatusPending, JobStatusStarted, JobStatusRunning, JobStatusSuccess, JobStatusFailed} {
		if err := status.Validate(); err != nil {
			t.Errorf("Validate(%q) = %v, want nil", status, err)
		}
	}
	for _, status := range []JobStatus{"", "done", "SUCCESS"} {
		if err := status.Validate(); err == nil {
			t.Errorf("Validate(%q) = nil, want an error", status)
		}
	}
}

func TestAnalysisConfigValidate(t *testing.T) {
	tests := []struct {
		name    string
		config  AnalysisConfig
		wantErr string
	}{
		{name: "valid", config: AnalysisConfig{Type: AnalysisType2D, Visibility: VisibilityPrivate}},
		{name: "unknown type", config: AnalysisConfig{Type: "4d", Visibility: VisibilityPrivate}, wantErr: "type"},
		{name: "unknown visibility", config: AnalysisConfig{Type: AnalysisType3D, Visibility: "everyone"}, wantErr: "visibility"},
		{name: "empty", config: AnalysisConfig{}, wantErr: "type"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()
			if tt.wantErr == "" {
				if err != nil {
					t.Fatalf("Validate() = %v, want nil", err)
				}
				return
			}
			if err == nil || !strings.HasPrefix(err.Error(), tt.wantErr+":") {
				t.Fatalf("Validate() = %v, want an error starting with %q", err, tt.wantErr)
			}
		})
	}
}
