package rustfs

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
)

type RustFSStorage struct {
	client    *s3.Client
	presigner *s3.PresignClient
	cfg       config.StorageConfig
}

func New(cfg config.StorageConfig) (RustFSStorage, error) {
	httpClient := &http.Client{
		Timeout: 5 * time.Second,
	}

	client := s3.NewFromConfig(aws.Config{
		Region:      cfg.Region,
		Credentials: aws.NewCredentialsCache(credentials.NewStaticCredentialsProvider(cfg.AccessKeyID, cfg.SecretAccessKey, "")),
		HTTPClient:  httpClient,
	}, func(o *s3.Options) {
		o.BaseEndpoint = &cfg.Endpoint
		o.UsePathStyle = true
	})

	presigner := s3.NewPresignClient(client)

	storage := RustFSStorage{client: client, presigner: presigner, cfg: cfg}

	if err := storage.initBucket(); err != nil {
		return RustFSStorage{}, fmt.Errorf("init storage bucket: %w", err)
	}

	return storage, nil
}

func (s *RustFSStorage) initBucket() error {
	ctx := context.Background()

	if _, err := s.client.HeadBucket(ctx, &s3.HeadBucketInput{
		Bucket: &s.cfg.BucketName,
	}); err != nil {
		if _, ok := errors.AsType[*types.NoSuchBucket](err); ok {
			if _, err := s.client.CreateBucket(ctx, &s3.CreateBucketInput{
				Bucket: &s.cfg.BucketName,
			}); err != nil {
				return fmt.Errorf("create bucket: %w", err)
			}
		}
	}

	return nil
}
