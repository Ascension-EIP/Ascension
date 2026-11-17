// @date 2026-11-13
// @file video_test.go
// @brief Unit tests of the video visibility, metadata and configuration rules.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import "testing"

func TestVisibilityValidate(t *testing.T) {
	for _, visibility := range []Visibility{VisibilityPrivate, VisibilityFriends, VisibilityPublic} {
		if err := visibility.Validate(); err != nil {
			t.Errorf("Validate(%q) = %v, want nil", visibility, err)
		}
	}
	for _, visibility := range []Visibility{"", "everyone", "Public"} {
		if err := visibility.Validate(); err == nil {
			t.Errorf("Validate(%q) = nil, want an error", visibility)
		}
	}
}

func TestNewVideoMetadata(t *testing.T) {
	const gigabyte = 1024 * 1024 * 1024

	tests := []struct {
		contentType string
		size        int
		wantExt     string
		wantErr     bool
	}{
		{contentType: "video/mp4", size: 1024, wantExt: "mp4"},
		{contentType: "video/webm", size: 1024, wantExt: "webm"},
		{contentType: "video/quicktime", size: 1024, wantExt: "mov"},
		{contentType: "video/x-matroska", size: 1024, wantExt: "mkv"},
		{contentType: "video/x-msvideo", size: 1024, wantExt: "avi"},
		{contentType: "video/mp4", size: gigabyte, wantExt: "mp4"},
		{contentType: "video/mp4", size: 0, wantExt: "mp4"},
		{contentType: "video/mp4", size: gigabyte + 1, wantErr: true},
		{contentType: "image/png", size: 1024, wantErr: true},
		{contentType: "VIDEO/MP4", size: 1024, wantErr: true},
		{contentType: "", size: 1024, wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.contentType, func(t *testing.T) {
			metadata, err := NewVideoMetadata(tt.contentType, tt.size)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("NewVideoMetadata(%q, %d) = %+v, want an error", tt.contentType, tt.size, metadata)
				}
				return
			}
			if err != nil {
				t.Fatalf("NewVideoMetadata(%q, %d) error = %v", tt.contentType, tt.size, err)
			}
			want := VideoMetadata{ContentType: tt.contentType, Extension: tt.wantExt, Size: tt.size}
			if metadata != want {
				t.Errorf("NewVideoMetadata() = %+v, want %+v", metadata, want)
			}
		})
	}
}

func TestVideoConfigValidate(t *testing.T) {
	if err := (VideoConfig{Visibility: VisibilityFriends, Title: new("Project"), Retained: true}).Validate(); err != nil {
		t.Errorf("Validate() = %v, want nil", err)
	}
	if err := (VideoConfig{}).Validate(); err == nil {
		t.Error("Validate() without visibility = nil, want an error")
	}
	if err := (VideoConfig{Visibility: "everyone"}).Validate(); err == nil {
		t.Error("Validate() with an unknown visibility = nil, want an error")
	}
}
