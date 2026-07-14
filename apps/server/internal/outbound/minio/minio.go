package minio

import (
	"context"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type MinIOStorage struct {
	client *minio.Client
	cfg    *config.MinIOConfig
}

func New(cfg *config.MinIOConfig) (MinIOStorage, error) {
	minioClient, err := minio.New(cfg.Endpoint, &minio.Options{
		Creds: credentials.NewStaticV4(cfg.ID, cfg.Secret, ""),
	})
	if err != nil {
		return MinIOStorage{}, err
	}

	if err := initBucket(minioClient, cfg.BucketName); err != nil {
		return MinIOStorage{}, err
	}

	return MinIOStorage{client: minioClient, cfg: cfg}, nil
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
