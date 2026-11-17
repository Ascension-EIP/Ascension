// @date 2026-11-13
// @file video_test.go
// @brief Endpoint tests of /v1/videos through the real router, with an in-memory repository and object storage.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"net/http"
	"strings"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

type uploadURLBody struct {
	VideoID   uuid.UUID `json:"video_id"`
	UploadURL string    `json:"upload_url"`
	ExpiresAt time.Time `json:"expires_at"`
}

type downloadURLBody struct {
	DownloadURL string    `json:"download_url"`
	ExpiresAt   time.Time `json:"expires_at"`
}

type videoBody struct {
	ID                uuid.UUID
	UserID            uuid.UUID
	ClimbingSessionID *uuid.UUID
	Title             *string
	ObjectKey         string
	Status            string
	Visibility        string
	ContentType       string
	SizeBytes         *int
	Retained          bool
}

func uploadBody() map[string]any {
	return map[string]any{"content_type": "video/mp4", "size": 1024, "visibility": "private", "title": "Project", "retained": true}
}

// putCompletedVideo stores an uploaded video of the user and returns it.
func putCompletedVideo(repo *memrepo.Repo, userID uuid.UUID) model.Video {
	video := model.Video{
		ID:          uuid.NewV7(),
		UserID:      userID,
		ObjectKey:   userID.String() + "/" + uuid.NewV7().String() + ".mp4",
		Status:      model.VideoStatusCompleted,
		Visibility:  model.VisibilityPrivate,
		ContentType: "video/mp4",
	}
	repo.PutVideo(video)
	return video
}

func TestVideoEndpointsRequireAuthentication(t *testing.T) {
	id := uuid.NewV7().String()
	routes := []struct{ method, path string }{
		{http.MethodPost, "/v1/videos/upload-url"},
		{http.MethodPut, "/v1/videos/upload-done/" + id},
		{http.MethodGet, "/v1/videos/download-url/" + id},
		{http.MethodGet, "/v1/videos/"},
		{http.MethodGet, "/v1/videos/" + id},
	}

	for _, route := range routes {
		t.Run(route.method+" "+route.path, func(t *testing.T) {
			api := newTestAPI(t, memrepo.New())
			expect(t, api.do(route.method, route.path, "", nil), http.StatusUnauthorized, nil)
			expect(t, api.do(route.method, route.path, "not-a-jwt", nil), http.StatusUnauthorized, nil)
		})
	}
}

func TestVideoEndpointsAreRateLimited(t *testing.T) {
	api := newTestAPI(t, memrepo.New())
	token := api.token(uuid.NewV7())

	for range 10 {
		expect(t, api.do(http.MethodGet, "/v1/videos/", token, nil), http.StatusOK, nil)
	}
	expect(t, api.do(http.MethodGet, "/v1/videos/", token, nil), http.StatusTooManyRequests, nil)
}

func TestVideoUploadLifecycle(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	token := api.token(userID)

	var upload uploadURLBody
	expect(t, api.do(http.MethodPost, "/v1/videos/upload-url", token, uploadBody()), http.StatusOK, &upload)

	video, ok := repo.Video(upload.VideoID)
	if !ok {
		t.Fatalf("video %v not stored", upload.VideoID)
	}
	wantKey := userID.String() + "/" + upload.VideoID.String() + ".mp4"
	if video.ObjectKey != wantKey || video.UserID != userID || video.Status != model.VideoStatusPending {
		t.Fatalf("video = %+v, want a pending video with key %s", video, wantKey)
	}
	if video.Title == nil || *video.Title != "Project" || !video.Retained || video.SizeBytes == nil || *video.SizeBytes != 1024 {
		t.Errorf("video = %+v, want the title, retention and size of the request", video)
	}
	if video.UploadURLExpiresAt == nil {
		t.Error("pending video has no upload URL expiry")
	}
	if !strings.HasSuffix(upload.UploadURL, "/upload/"+wantKey) || !upload.ExpiresAt.Equal(fakeStorageExpiry) {
		t.Errorf("upload URL = %+v, want the presigned URL of %s", upload, wantKey)
	}

	// Download is refused until the upload is done.
	if rec := api.do(http.MethodGet, "/v1/videos/download-url/"+upload.VideoID.String(), token, nil); rec.Code < 400 {
		t.Fatalf("download of a pending video: status = %d, want an error", rec.Code)
	}

	api.storage.upload(wantKey)
	expect(t, api.do(http.MethodPut, "/v1/videos/upload-done/"+upload.VideoID.String(), token, nil), http.StatusNoContent, nil)
	video, _ = repo.Video(upload.VideoID)
	if video.Status != model.VideoStatusCompleted || video.UploadURLExpiresAt != nil {
		t.Errorf("after upload-done: status = %s, upload expiry = %v, want completed and nil", video.Status, video.UploadURLExpiresAt)
	}

	var download downloadURLBody
	expect(t, api.do(http.MethodGet, "/v1/videos/download-url/"+upload.VideoID.String(), token, nil), http.StatusOK, &download)
	if !strings.HasSuffix(download.DownloadURL, "/download/"+wantKey) {
		t.Errorf("download URL = %q, want the presigned URL of %s", download.DownloadURL, wantKey)
	}

	var got videoBody
	expect(t, api.do(http.MethodGet, "/v1/videos/"+upload.VideoID.String(), token, nil), http.StatusOK, &got)
	if got.ID != upload.VideoID || got.Status != "completed" || got.ObjectKey != wantKey {
		t.Errorf("GET video = %+v", got)
	}
}

func TestVideoUploadInClimbingSession(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	token := api.token(userID)

	var session sessionBody
	expect(t, api.do(http.MethodPost, "/v1/sessions", token, map[string]any{}), http.StatusCreated, &session)

	body := uploadBody()
	body["climbing_session_id"] = session.ID
	var upload uploadURLBody
	expect(t, api.do(http.MethodPost, "/v1/videos/upload-url", token, body), http.StatusOK, &upload)
	if video, _ := repo.Video(upload.VideoID); video.ClimbingSessionID == nil || *video.ClimbingSessionID != session.ID {
		t.Errorf("video session = %v, want %v", video.ClimbingSessionID, session.ID)
	}

	// Another user's session, or an unknown one, is an invalid input.
	other := api.token(uuid.NewV7())
	expect(t, api.do(http.MethodPost, "/v1/videos/upload-url", other, body), http.StatusUnprocessableEntity, nil)
	body["climbing_session_id"] = uuid.NewV7()
	expect(t, api.do(http.MethodPost, "/v1/videos/upload-url", token, body), http.StatusUnprocessableEntity, nil)
}

func TestVideoUploadURLInvalidBodies(t *testing.T) {
	tests := []struct {
		name   string
		change map[string]any
		drop   string
	}{
		{name: "missing content type", drop: "content_type"},
		{name: "missing size", drop: "size"},
		{name: "missing visibility", drop: "visibility"},
		{name: "unsupported content type", change: map[string]any{"content_type": "image/png"}},
		{name: "too big", change: map[string]any{"size": 2 << 30}},
		{name: "size not a number", change: map[string]any{"size": "big"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			api := newTestAPI(t, memrepo.New())
			body := uploadBody()
			delete(body, tt.drop)
			for k, v := range tt.change {
				body[k] = v
			}
			expect(t, api.do(http.MethodPost, "/v1/videos/upload-url", api.token(uuid.NewV7()), body), http.StatusBadRequest, nil)
		})
	}

	api := newTestAPI(t, memrepo.New())
	expect(t, api.do(http.MethodPost, "/v1/videos/upload-url", api.token(uuid.NewV7()), "{"), http.StatusBadRequest, nil)
}

func TestVideoUploadURLStorageFailure(t *testing.T) {
	api := newTestAPI(t, memrepo.New())
	api.storage.setFailing(true)

	expect(t, api.do(http.MethodPost, "/v1/videos/upload-url", api.token(uuid.NewV7()), uploadBody()), http.StatusInternalServerError, nil)
}

func TestVideoUploadURLRejectsUnknownVisibility(t *testing.T) {
	knownBug(t, "VideoConfig.Validate does not wrap model.ErrInvalidInput: an unknown visibility answers 500 instead of 422")

	api := newTestAPI(t, memrepo.New())
	body := uploadBody()
	body["visibility"] = "everyone"
	expect(t, api.do(http.MethodPost, "/v1/videos/upload-url", api.token(uuid.NewV7()), body), http.StatusUnprocessableEntity, nil)
}

func TestVideoInvalidIDs(t *testing.T) {
	api := newTestAPI(t, memrepo.New())
	token := api.token(uuid.NewV7())

	expect(t, api.do(http.MethodPut, "/v1/videos/upload-done/not-a-uuid", token, nil), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodGet, "/v1/videos/download-url/not-a-uuid", token, nil), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodGet, "/v1/videos/not-a-uuid", token, nil), http.StatusBadRequest, nil)
}

func TestListVideos(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	token := api.token(userID)

	mine := map[uuid.UUID]bool{}
	for range 3 {
		mine[putCompletedVideo(repo, userID).ID] = true
	}
	putCompletedVideo(repo, uuid.NewV7())

	var list []videoBody
	expect(t, api.do(http.MethodGet, "/v1/videos/", token, nil), http.StatusOK, &list)
	if len(list) != 3 {
		t.Fatalf("%d videos, want the user's 3", len(list))
	}
	for _, video := range list {
		if !mine[video.ID] {
			t.Errorf("video %v of another user listed", video.ID)
		}
	}

	var page []videoBody
	expect(t, api.do(http.MethodGet, "/v1/videos/?limit=2&offset=0", token, nil), http.StatusOK, &page)
	if len(page) != 2 {
		t.Errorf("limit=2: %d videos, want 2", len(page))
	}

	for _, query := range []string{"limit=0", "limit=21", "offset=-1", "limit=abc"} {
		expect(t, api.do(http.MethodGet, "/v1/videos/?"+query, token, nil), http.StatusBadRequest, nil)
	}
}

func TestUploadDoneWithoutUploadedFile(t *testing.T) {
	knownBug(t, "model.ErrVideoNotFound is not mapped by utils.Error: upload-done before the upload answers 500 instead of 404")

	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	video := putCompletedVideo(repo, userID)

	expect(t, api.do(http.MethodPut, "/v1/videos/upload-done/"+video.ID.String(), api.token(userID), nil), http.StatusNotFound, nil)
}

func TestDownloadOfPendingVideo(t *testing.T) {
	knownBug(t, "model.ErrVideoUploading is not mapped by utils.Error: downloading a pending video answers 500 instead of 409")

	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	video := putCompletedVideo(repo, userID)
	video.Status = model.VideoStatusPending
	repo.PutVideo(video)

	expect(t, api.do(http.MethodGet, "/v1/videos/download-url/"+video.ID.String(), api.token(userID), nil), http.StatusConflict, nil)
}

func TestVideosAreScopedToTheirOwner(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	video := putCompletedVideo(repo, uuid.NewV7())
	api.storage.upload(video.ObjectKey)
	other := api.token(uuid.NewV7())

	// Whatever the status code, another user never gets the video.
	for _, route := range []struct{ method, path string }{
		{http.MethodGet, "/v1/videos/" + video.ID.String()},
		{http.MethodGet, "/v1/videos/download-url/" + video.ID.String()},
		{http.MethodPut, "/v1/videos/upload-done/" + video.ID.String()},
	} {
		if rec := api.do(route.method, route.path, other, nil); rec.Code < 400 {
			t.Errorf("%s %s by another user: status = %d, want an error", route.method, route.path, rec.Code)
		}
	}
}

func TestVideoOfAnotherUserIsNotFound(t *testing.T) {
	knownBug(t, "model.ErrNotFound is not mapped by utils.Error: another user's or an unknown video answers 500 instead of 404")

	repo := memrepo.New()
	api := newTestAPI(t, repo)
	video := putCompletedVideo(repo, uuid.NewV7())
	other := api.token(uuid.NewV7())

	expect(t, api.do(http.MethodGet, "/v1/videos/"+video.ID.String(), other, nil), http.StatusNotFound, nil)
	expect(t, api.do(http.MethodGet, "/v1/videos/download-url/"+video.ID.String(), other, nil), http.StatusNotFound, nil)
	expect(t, api.do(http.MethodPut, "/v1/videos/upload-done/"+video.ID.String(), other, nil), http.StatusNotFound, nil)
}
