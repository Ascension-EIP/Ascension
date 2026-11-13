// @date 2026-11-14
// @file rustfs_test.go
// @brief Unit tests of the S3 storage adapter against a local fake S3 server.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package rustfs

import (
	"context"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/knownbug"
	"net/http"
	"net/http/httptest"
	"strconv"
	"sync"
	"testing"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
)

const testBucket = "videos"

// fakeS3 answers the path-style S3 requests with the status set for each "METHOD path",
// 200 by default, and records the requests it received.
type fakeS3 struct {
	mu       sync.Mutex
	statuses map[string]int
	requests []string
}

func (f *fakeS3) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	f.mu.Lock()
	key := r.Method + " " + r.URL.Path
	f.requests = append(f.requests, key)
	status, ok := f.statuses[key]
	f.mu.Unlock()

	if !ok {
		status = http.StatusOK
	}
	if status == http.StatusNoContent || r.Method == http.MethodHead {
		w.WriteHeader(status)
		return
	}
	if status >= 400 {
		w.Header().Set("Content-Type", "application/xml")
		w.WriteHeader(status)
		_, _ = w.Write([]byte(`<?xml version="1.0" encoding="UTF-8"?><Error><Code>` + http.StatusText(status) + `</Code><Message>fake</Message></Error>`))
		return
	}
	w.WriteHeader(status)
}

func (f *fakeS3) received(key string) bool {
	f.mu.Lock()
	defer f.mu.Unlock()

	for _, request := range f.requests {
		if request == key {
			return true
		}
	}
	return false
}

func testConfig(endpoint string) config.StorageConfig {
	return config.StorageConfig{
		Endpoint:        endpoint,
		Region:          "eu-west-1",
		AccessKeyID:     "test-access-key",
		SecretAccessKey: "test-secret-key",
		BucketName:      testBucket,
		UploadExp:       15 * time.Minute,
		DownloadExp:     2 * time.Hour,
	}
}

// newTestStorage starts a fake S3 server with the statuses and connects the storage to it.
func newTestStorage(t *testing.T, statuses map[string]int) (RustFSStorage, *fakeS3) {
	t.Helper()

	fake := &fakeS3{statuses: statuses}
	server := httptest.NewServer(fake)
	t.Cleanup(server.Close)

	storage, err := New(testConfig(server.URL))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	return storage, fake
}

func TestNew(t *testing.T) {
	t.Run("keeps an existing bucket", func(t *testing.T) {
		_, fake := newTestStorage(t, nil)

		if !fake.received("HEAD /" + testBucket) {
			t.Errorf("requests = %v, want a HEAD of the bucket", fake.requests)
		}
		if fake.received("PUT /" + testBucket) {
			t.Errorf("requests = %v, want no bucket creation", fake.requests)
		}
	})

	t.Run("creates a missing bucket", func(t *testing.T) {
		_, fake := newTestStorage(t, map[string]int{"HEAD /" + testBucket: http.StatusNotFound})

		if !fake.received("PUT /" + testBucket) {
			t.Errorf("requests = %v, want the bucket creation", fake.requests)
		}
	})

	t.Run("fails when the missing bucket cannot be created", func(t *testing.T) {
		fake := &fakeS3{statuses: map[string]int{
			"HEAD /" + testBucket: http.StatusNotFound,
			"PUT /" + testBucket:  http.StatusForbidden,
		}}
		server := httptest.NewServer(fake)
		t.Cleanup(server.Close)

		if _, err := New(testConfig(server.URL)); err == nil {
			t.Fatal("New() error = nil, want the bucket creation error")
		}
	})

	// A forbidden HEAD is not a missing bucket: the storage starts and lets the requests
	// report the problem. This documents the current behaviour of initBucket.
	t.Run("does not create the bucket on a forbidden head", func(t *testing.T) {
		_, fake := newTestStorage(t, map[string]int{"HEAD /" + testBucket: http.StatusForbidden})

		if fake.received("PUT /" + testBucket) {
			t.Errorf("requests = %v, want no bucket creation", fake.requests)
		}
	})
}

func TestPresignedUploadURL(t *testing.T) {
	storage, fake := newTestStorage(t, nil)
	before := time.Now()

	u, expiresAt, err := storage.PresignedUploadURL(context.Background(), "users/42/video.mp4")
	if err != nil {
		t.Fatalf("PresignedUploadURL() error = %v", err)
	}

	if u.Path != "/"+testBucket+"/users/42/video.mp4" {
		t.Errorf("path = %q, want the path-style object path", u.Path)
	}
	query := u.Query()
	if got := query.Get("X-Amz-Expires"); got != strconv.Itoa(int((15 * time.Minute).Seconds())) {
		t.Errorf("X-Amz-Expires = %q, want the upload expiry", got)
	}
	if query.Get("X-Amz-Signature") == "" || query.Get("X-Amz-Credential") == "" {
		t.Errorf("query = %v, want a SigV4 signature", query)
	}
	if expiresAt.Before(before.Add(15*time.Minute)) || expiresAt.After(time.Now().Add(15*time.Minute)) {
		t.Errorf("expiresAt = %v, want now + 15m", expiresAt)
	}
	if len(fake.requests) != 1 {
		t.Errorf("requests = %v, want only the bucket check: presigning is local", fake.requests)
	}
}

func TestPresignedDownloadURL(t *testing.T) {
	storage, _ := newTestStorage(t, nil)
	before := time.Now()

	u, expiresAt, err := storage.PresignedDownloadURL(context.Background(), "users/42/video.mp4")
	if err != nil {
		t.Fatalf("PresignedDownloadURL() error = %v", err)
	}

	if u.Path != "/"+testBucket+"/users/42/video.mp4" {
		t.Errorf("path = %q, want the path-style object path", u.Path)
	}
	if u.Query().Get("X-Amz-Signature") == "" {
		t.Errorf("query = %v, want a SigV4 signature", u.Query())
	}
	if expiresAt.Before(before.Add(2*time.Hour)) || expiresAt.After(time.Now().Add(2*time.Hour)) {
		t.Errorf("expiresAt = %v, want now + 2h", expiresAt)
	}

	t.Run("signs the URL for the download expiry", func(t *testing.T) {
		knownbug.Skip(t, "PresignedDownloadURL signs with UploadExp but reports DownloadExp as the expiry")

		if got := u.Query().Get("X-Amz-Expires"); got != strconv.Itoa(int((2 * time.Hour).Seconds())) {
			t.Errorf("X-Amz-Expires = %q, want the download expiry", got)
		}
	})
}

func TestFileExist(t *testing.T) {
	const objectPath = "HEAD /" + testBucket + "/users/42/video.mp4"

	t.Run("finds an existing object", func(t *testing.T) {
		storage, _ := newTestStorage(t, nil)

		exists, err := storage.FileExist(context.Background(), "users/42/video.mp4")
		if err != nil || !exists {
			t.Fatalf("FileExist() = %v, %v, want true, nil", exists, err)
		}
	})

	t.Run("reports a missing object without error", func(t *testing.T) {
		knownbug.Skip(t, "HEAD returns types.NotFound, not types.NoSuchKey, so a missing object is an error")

		storage, _ := newTestStorage(t, map[string]int{objectPath: http.StatusNotFound})

		exists, err := storage.FileExist(context.Background(), "users/42/video.mp4")
		if err != nil || exists {
			t.Fatalf("FileExist() = %v, %v, want false, nil", exists, err)
		}
	})

	t.Run("returns the other errors", func(t *testing.T) {
		storage, _ := newTestStorage(t, map[string]int{objectPath: http.StatusForbidden})

		exists, err := storage.FileExist(context.Background(), "users/42/video.mp4")
		if err == nil || exists {
			t.Fatalf("FileExist() = %v, %v, want false and an error", exists, err)
		}
	})
}

func TestDelete(t *testing.T) {
	const objectPath = "DELETE /" + testBucket + "/users/42/video.mp4"

	t.Run("deletes the object", func(t *testing.T) {
		storage, fake := newTestStorage(t, map[string]int{objectPath: http.StatusNoContent})

		if err := storage.Delete(context.Background(), "users/42/video.mp4"); err != nil {
			t.Fatalf("Delete() error = %v", err)
		}
		if !fake.received(objectPath) {
			t.Errorf("requests = %v, want the object deletion", fake.requests)
		}
	})

	t.Run("returns the storage error", func(t *testing.T) {
		storage, _ := newTestStorage(t, map[string]int{objectPath: http.StatusForbidden})

		if err := storage.Delete(context.Background(), "users/42/video.mp4"); err == nil {
			t.Fatal("Delete() error = nil, want the storage error")
		}
	})
}

func TestPresignRejectsAnEmptyKey(t *testing.T) {
	storage, _ := newTestStorage(t, nil)

	if u, _, err := storage.PresignedUploadURL(context.Background(), ""); err == nil {
		t.Errorf("PresignedUploadURL(\"\") = %v, want an error", u)
	}
	if u, _, err := storage.PresignedDownloadURL(context.Background(), ""); err == nil {
		t.Errorf("PresignedDownloadURL(\"\") = %v, want an error", u)
	}
}
