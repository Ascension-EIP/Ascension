package service

import (
	"context"
	"fmt"
	"net/url"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type videoStorage interface {
	PresignedUploadURL(context.Context, string) (*url.URL, time.Time, error)
	PresignedDownloadURL(context.Context, string) (*url.URL, time.Time, error)
	Delete(context.Context, string) error
	UploadExp() time.Duration
	DownloadExp() time.Duration
}

type videoRepository interface {
	CreateVideoInfo(context.Context, *model.VideoInfo) error
	WithTransaction(context.Context, func(context.Context) error) error
}

type VideoService struct {
	storage videoStorage
	repo    videoRepository
}

func NewVideoService(storage videoStorage, repo videoRepository) VideoService {
	return VideoService{storage: storage, repo: repo}
}

func (s *VideoService) GetUploadURL(ctx context.Context, fileInfo *model.FileInfo) (*model.UploadVideoURL, error) {
	videoID, err := uuid.NewV7()
	if err != nil {
		return nil, err
	}
	var url *url.URL
	var expiresAt time.Time

	objectKey := fmt.Sprintf("%s/%s.%s", fileInfo.UserID.String(), videoID.String(), fileInfo.Extension)

	if err := s.repo.WithTransaction(ctx, func(ctx context.Context) error {
		if err := s.repo.CreateVideoInfo(ctx, &model.VideoInfo{
			ID:        videoID,
			UserID:    fileInfo.UserID,
			ObjectKey: objectKey,
			State:     model.VideoStatePending,
			ExpiresAt: time.Now().Add(s.storage.UploadExp()),
		}); err != nil {
			return err
		}

		url, expiresAt, err = s.storage.PresignedUploadURL(ctx, objectKey)
		if err != nil {
			return err
		}
		return nil
	}); err != nil {
		return nil, err
	}

	return &model.UploadVideoURL{
		VideoID:   videoID,
		URL:       url,
		ExpiresAt: expiresAt,
	}, nil
}
