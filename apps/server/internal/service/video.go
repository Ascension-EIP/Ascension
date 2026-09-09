// @date 2026-03-20
// @file video.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"fmt"
	"net/url"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

type VideoService struct {
	storage model.VideoStorage
	repo    model.VideoRepository
}

func NewVideoService(storage model.VideoStorage, repo model.VideoRepository) VideoService {
	return VideoService{storage: storage, repo: repo}
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
	videoID := uuid.NewV7()
	var url *url.URL
	var expiresAt time.Time

	objectKey := fmt.Sprintf("%s/%s.%s", fileInfo.UserID.String(), videoID.String(), fileInfo.Extension)

	if err := s.repo.WithTransaction(ctx, func(ctx context.Context) error {
		if err := s.repo.CreateVideoInfo(ctx, &model.VideoInfo{
			ID:        videoID,
			UserID:    fileInfo.UserID,
			Bucket:    s.storage.VideoBucket(),
			ObjectKey: objectKey,
			Status:    model.VideoStatusPending,
			ExpiresAt: time.Now().Add(s.storage.UploadExp()),
		}); err != nil {
			return err
		}

		var err error
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

	status := model.VideoStatusCompleted
	if _, err := s.repo.UpdateVideoInfo(ctx, &model.PartialVideoInfo{ID: videoID, UserID: userID, Status: &status}); err != nil {
		return err
	}
	return nil
}
