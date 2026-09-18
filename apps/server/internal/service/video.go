// @date 2026-09-18
// @file video.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
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
	FileExist(context.Context, string) error
	Delete(context.Context, string) error
	UploadExp() time.Duration
	DownloadExp() time.Duration
}

type videoRepository interface {
	CreateVideoInfo(context.Context, *model.VideoInfo) error
	GetVideoInfoByUserID(context.Context, uuid.UUID, uuid.UUID) (*model.VideoInfo, error)
	GetCompletedVideoInfoByUserID(context.Context, uuid.UUID, uuid.UUID) (*model.VideoInfo, error)
	UpdateVideoInfo(context.Context, *model.PartialVideoInfo) (*model.VideoInfo, error)
	WithTransaction(context.Context, func(context.Context) error) error
}

type VideoService struct {
	storage   videoStorage
	repo      videoRepository
	retention time.Duration
}

func NewVideoService(storage videoStorage, repo videoRepository, retention time.Duration) VideoService {
	return VideoService{storage: storage, repo: repo, retention: retention}
}

func (s *VideoService) GetDownloadURL(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) (*model.DownloadVideoURL, error) {
	videoInfo, err := s.repo.GetCompletedVideoInfoByUserID(ctx, videoID, userID)
	if err != nil {
		return nil, err
	}

	url, expiresAt, err := s.storage.PresignedDownloadURL(ctx, videoInfo.ObjectKey)
	if err != nil {
		return nil, err
	}

	return &model.DownloadVideoURL{
		URL:       url,
		ExpiresAt: expiresAt,
	}, nil
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
			ID:          videoID,
			UserID:      fileInfo.UserID,
			ObjectKey:   objectKey,
			ContentType: fileInfo.ContentType,
			Status:      model.VideoStatusPending,
			SizeBytes:   &fileInfo.Size,
			ExpiresAt:   time.Now().Add(s.storage.UploadExp()),
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

func (s *VideoService) UploadComplete(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) error {
	videoInfo, err := s.repo.GetVideoInfoByUserID(ctx, videoID, userID)
	if err != nil {
		return err
	}

	if err := s.storage.FileExist(ctx, videoInfo.ObjectKey); err != nil {
		return err
	}

	// A completed video is kept for the legal retention period, unless the user retains it.
	status := model.VideoStatusCompleted
	expiresAt := time.Now().Add(s.retention)
	if _, err := s.repo.UpdateVideoInfo(ctx, &model.PartialVideoInfo{ID: videoID, UserID: userID, Status: &status, ExpiresAt: &expiresAt}); err != nil {
		return err
	}
	return nil
}
