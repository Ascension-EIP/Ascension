// @date 2026-11-12
// @file minio_test.go
// @brief Unit tests of the S3 client options (TLS and signing region).
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package minio

import (
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

func TestUseTLS(t *testing.T) {
	tests := []struct {
		name     string
		endpoint string
		ssl      bool
		want     bool
	}{
		{name: "https scheme wins over ssl off", endpoint: "https://s3.gra.io.cloud.ovh.net", ssl: false, want: true},
		{name: "http scheme wins over ssl on", endpoint: "http://rustfs:9000", ssl: true, want: false},
		{name: "uppercase scheme", endpoint: "HTTPS://s3.gra.io.cloud.ovh.net", ssl: false, want: true},
		{name: "no scheme, ssl on", endpoint: "s3.gra.io.cloud.ovh.net", ssl: true, want: true},
		{name: "no scheme, ssl off", endpoint: "localhost:9000", ssl: false, want: false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := useTLS(tt.endpoint, tt.ssl); got != tt.want {
				t.Errorf("useTLS(%q, %v) = %v, want %v", tt.endpoint, tt.ssl, got, tt.want)
			}
		})
	}
}

func TestClientOptions(t *testing.T) {
	opts := clientOptions(config.MinIOConfig{
		Endpoint: "https://s3.gra.io.cloud.ovh.net",
		ID:       "access",
		Secret:   "secret",
		Region:   "gra",
	})

	if !opts.Secure {
		t.Error("Secure = false, want true for an https endpoint")
	}
	if opts.Region != "gra" {
		t.Errorf("Region = %q, want %q", opts.Region, "gra")
	}
	creds, err := opts.Creds.GetWithContext(&credentials.CredContext{})
	if err != nil {
		t.Fatalf("Creds.GetWithContext() error = %v", err)
	}
	if creds.AccessKeyID != "access" || creds.SecretAccessKey != "secret" {
		t.Errorf("credentials = %q/%q, want access/secret", creds.AccessKeyID, creds.SecretAccessKey)
	}
}

// TestNewClientAcceptsOVHEndpoint checks that minio-go accepts the endpoint
// forms used in production and in development with the derived options.
func TestNewClientAcceptsOVHEndpoint(t *testing.T) {
	for _, endpoint := range []string{
		"https://s3.gra.io.cloud.ovh.net",
		"s3.gra.io.cloud.ovh.net",
		"http://rustfs:9000",
	} {
		cfg := config.MinIOConfig{Endpoint: endpoint, ID: "access", Secret: "secret", SSL: true, Region: "gra"}
		if _, err := minio.New(cfg.Endpoint, clientOptions(cfg)); err != nil {
			t.Errorf("minio.New(%q) error = %v", endpoint, err)
		}
	}
}
