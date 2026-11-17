// @date 2026-11-14
// @file upload.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package rustfs

import (
	"context"
	"errors"
	"net/url"
	"time"

	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
)

func (s *RustFSStorage) PresignedUploadURL(ctx context.Context, objectKey string) (*url.URL, time.Time, error) {
	result, err := s.presigner.PresignPutObject(ctx, &s3.PutObjectInput{Bucket: &s.cfg.BucketName, Key: &objectKey}, func(opts *s3.PresignOptions) {
		opts.Expires = s.cfg.UploadExp
	})
	if err != nil {
		return nil, time.Time{}, err
	}

	url, err := url.Parse(result.URL)
	if err != nil {
		return nil, time.Time{}, err
	}

	return url, time.Now().Add(s.cfg.UploadExp), nil
}

func (s *RustFSStorage) PresignedDownloadURL(ctx context.Context, objectKey string) (*url.URL, time.Time, error) {
	result, err := s.presigner.PresignGetObject(ctx, &s3.GetObjectInput{Bucket: &s.cfg.BucketName, Key: &objectKey}, func(opts *s3.PresignOptions) {
		opts.Expires = s.cfg.UploadExp
	})
	if err != nil {
		return nil, time.Time{}, err
	}

	url, err := url.Parse(result.URL)
	if err != nil {
		return nil, time.Time{}, err
	}

	return url, time.Now().Add(s.cfg.DownloadExp), nil
}

func (s *RustFSStorage) Delete(ctx context.Context, objectKey string) error {
	_, err := s.client.DeleteObject(ctx, &s3.DeleteObjectInput{Bucket: &s.cfg.BucketName, Key: &objectKey})
	if err != nil {
		return err
	}
	return nil
}

func (s *RustFSStorage) FileExist(ctx context.Context, objectKey string) (bool, error) {
	_, err := s.client.HeadObject(ctx, &s3.HeadObjectInput{
		Bucket: &s.cfg.BucketName,
		Key:    &objectKey,
	})
	if err != nil {
		// HEAD has no response body, so S3 answers a missing object with a bare 404,
		// which the SDK reports as NotFound; NoSuchKey only comes with a body.
		if _, ok := errors.AsType[*types.NotFound](err); ok {
			return false, nil
		}
		if _, ok := errors.AsType[*types.NoSuchKey](err); ok {
			return false, nil
		}

		return false, err
	}

	return true, nil
}
