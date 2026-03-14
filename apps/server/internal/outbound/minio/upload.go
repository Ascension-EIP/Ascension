package minio

import (
	"context"
	"net/url"
	"time"

	"github.com/minio/minio-go/v7"
)

func (s *MinIOStorage) PresignedUploadURL(ctx context.Context, objectKey string) (*url.URL, time.Time, error) {
	url, err := s.client.PresignedPutObject(ctx, s.cfg.BucketName, objectKey, s.cfg.UploadExp)
	if err != nil {
		return nil, time.Time{}, err
	}
	return url, time.Now().Add(s.cfg.UploadExp), nil
}

func (s *MinIOStorage) PresignedDownloadURL(ctx context.Context, objectKey string) (*url.URL, time.Time, error) {
	url, err := s.client.PresignedGetObject(ctx, s.cfg.BucketName, objectKey, s.cfg.UploadExp, url.Values{})
	if err != nil {
		return nil, time.Time{}, err
	}
	return url, time.Now().Add(s.cfg.DownloadExp), nil
}

func (s *MinIOStorage) Delete(ctx context.Context, objectKey string) error {
	err := s.client.RemoveObject(ctx, s.cfg.BucketName, objectKey, minio.RemoveObjectOptions{})
	if err != nil {
		return err
	}
	return nil
}
