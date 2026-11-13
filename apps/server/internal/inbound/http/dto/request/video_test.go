// @date 2026-11-13
// @file video_test.go
// @brief Unit tests of the video upload, analysis creation and offset pagination request DTOs.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"net/http/httptest"
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/gin-gonic/gin/binding"
	"uuid"
)

func TestVideoUploadIntoVideoMetadataAndVideoConfig(t *testing.T) {
	sessionID := uuid.NewV7()

	t.Run("valid upload", func(t *testing.T) {
		var req VideoUpload
		body := `{"content_type":"video/mp4","size":2048,"climbing_session_id":"` + sessionID.String() + `","title":"Project","visibility":"friends","retained":true}`
		if err := bindJSON(body, &req); err != nil {
			t.Fatalf("bind error = %v", err)
		}

		metadata, config, err := req.IntoVideoMetadataAndVideoConfig()
		if err != nil {
			t.Fatalf("IntoVideoMetadataAndVideoConfig() error = %v", err)
		}
		if metadata != (model.VideoMetadata{ContentType: "video/mp4", Extension: "mp4", Size: 2048}) {
			t.Errorf("metadata = %+v", metadata)
		}
		if config.ClimbingSessionID == nil || *config.ClimbingSessionID != sessionID {
			t.Errorf("ClimbingSessionID = %v, want %v", config.ClimbingSessionID, sessionID)
		}
		if config.Title == nil || *config.Title != "Project" || config.Visibility != model.VisibilityFriends || !config.Retained {
			t.Errorf("config = %+v", config)
		}
	})

	t.Run("unsupported content type", func(t *testing.T) {
		_, _, err := VideoUpload{ContentType: "image/png", Size: 10, Visibility: "private"}.IntoVideoMetadataAndVideoConfig()
		if err == nil {
			t.Fatal("IntoVideoMetadataAndVideoConfig() = nil error, want an error")
		}
	})

	t.Run("too big", func(t *testing.T) {
		_, _, err := VideoUpload{ContentType: "video/mp4", Size: 1<<30 + 1, Visibility: "private"}.IntoVideoMetadataAndVideoConfig()
		if err == nil {
			t.Fatal("IntoVideoMetadataAndVideoConfig() = nil error, want an error")
		}
	})

	for _, body := range []string{
		`{"size":10,"visibility":"private"}`,
		`{"content_type":"video/mp4","visibility":"private"}`,
		`{"content_type":"video/mp4","size":10}`,
	} {
		if err := bindJSON(body, &VideoUpload{}); err == nil {
			t.Errorf("bind(%s) = nil, want an error", body)
		}
	}
}

func TestCreateAnalyseRequestIntoAnalysisConfig(t *testing.T) {
	videoID := uuid.NewV7()

	var req CreateAnalyseRequest
	if err := bindJSON(`{"video_id":"`+videoID.String()+`","type":"2d","visibility":"public"}`, &req); err != nil {
		t.Fatalf("bind error = %v", err)
	}
	want := model.AnalysisConfig{VideoID: videoID, Type: model.AnalysisType2D, Visibility: model.VisibilityPublic}
	if got := req.IntoAnalysisConfig(); got != want {
		t.Errorf("IntoAnalysisConfig() = %+v, want %+v", got, want)
	}

	for _, body := range []string{`{"type":"2d","visibility":"public"}`, `{"video_id":"` + videoID.String() + `","visibility":"public"}`, `{"video_id":"` + videoID.String() + `","type":"2d"}`, `{"video_id":"nope","type":"2d","visibility":"public"}`} {
		if err := bindJSON(body, &CreateAnalyseRequest{}); err == nil {
			t.Errorf("bind(%s) = nil, want an error", body)
		}
	}
}

func TestPaginationQuery(t *testing.T) {
	tests := []struct {
		query   string
		want    model.Pagination
		wantErr bool
	}{
		{query: "", want: model.Pagination{Limit: 10, Offset: 0}},
		{query: "limit=5&offset=40", want: model.Pagination{Limit: 5, Offset: 40}},
		{query: "limit=1", want: model.Pagination{Limit: 1}},
		{query: "limit=20", want: model.Pagination{Limit: 20}},
		{query: "limit=0", wantErr: true},
		{query: "limit=21", wantErr: true},
		{query: "offset=-1", wantErr: true},
		{query: "limit=abc", wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.query, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/videos?"+tt.query, nil)
			var query PaginationQuery
			err := binding.Query.Bind(req, &query)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("bind(%q) = %+v, want an error", tt.query, query)
				}
				return
			}
			if err != nil {
				t.Fatalf("bind(%q) error = %v", tt.query, err)
			}
			if got := query.IntoPagination(); got != tt.want {
				t.Errorf("IntoPagination() = %+v, want %+v", got, tt.want)
			}
		})
	}
}
