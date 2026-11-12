// @date 2026-11-12
// @file minio.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package minio

import (
	"context"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type MinIOStorage struct {
	client *minio.Client
	cfg    config.MinIOConfig
}

func New(cfg config.MinIOConfig) (MinIOStorage, error) {
	minioClient, err := minio.New(cfg.Endpoint, clientOptions(cfg))
	if err != nil {
		return MinIOStorage{}, err
	}

	if err := initBucket(minioClient, cfg.BucketName); err != nil {
		return MinIOStorage{}, err
	}

	return MinIOStorage{client: minioClient, cfg: cfg}, nil
}

// clientOptions builds the S3 client options from the configuration.
// The region is signed into every request and presigned URL: OVHcloud
// Object Storage expects its own (e.g. "gra"), an empty one lets the
// client ask the bucket.
func clientOptions(cfg config.MinIOConfig) *minio.Options {
	return &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.ID, cfg.Secret, ""),
		Secure: useTLS(cfg.Endpoint, cfg.SSL),
		Region: cfg.Region,
	}
}

// useTLS tells whether the client talks HTTPS. A scheme in the endpoint
// wins over the SSL flag, which only applies to an endpoint without one.
func useTLS(endpoint string, ssl bool) bool {
	lower := strings.ToLower(endpoint)
	switch {
	case strings.HasPrefix(lower, "https://"):
		return true
	case strings.HasPrefix(lower, "http://"):
		return false
	default:
		return ssl
	}
}

func initBucket(client *minio.Client, bucket string) error {
	exist, err := client.BucketExists(context.Background(), bucket)
	if exist {
		return nil
	}
	if err != nil {
		return err
	}

	err = client.MakeBucket(context.Background(), bucket, minio.MakeBucketOptions{})
	if err != nil {
		return err
	}

	return nil
}
