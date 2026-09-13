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

func (s *VideoService) GetDownloadURL(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) (model.VideoDownloadURL, error) {
	video, err := s.repo.GetVideoByFilter(ctx, model.VideoFilter{ID: &videoID, UserID: &userID})
	if err != nil {
		return model.VideoDownloadURL{}, err
	}

	if video.Status != model.VideoStatusCompleted {
		return model.VideoDownloadURL{}, model.ErrVideoUploading
	}

	url, expiresAt, err := s.storage.PresignedDownloadURL(ctx, video.ObjectKey)
	if err != nil {
		return model.VideoDownloadURL{}, err
	}

	return model.VideoDownloadURL{
		URL:       url,
		ExpiresAt: expiresAt,
	}, nil
}

func (s *VideoService) GetUploadURL(ctx context.Context, fileInfo model.FileInfo) (model.VideoUploadURL, error) {
	var url *url.URL
	var expiresAt time.Time

	videoID := uuid.NewV7() // can't rely on repo for this one since we need the id for the objectKey

	objectKey := fmt.Sprintf("%s/%s.%s", fileInfo.UserID.String(), videoID.String(), fileInfo.Extension)

	if err := s.repo.WithTransaction(ctx, func(ctx context.Context) error {
		if err := s.repo.CreateVideo(ctx, model.Video{
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
		return model.VideoUploadURL{}, err
	}

	return model.VideoUploadURL{
		VideoID:   videoID,
		URL:       url,
		ExpiresAt: expiresAt,
	}, nil
}

func (s *VideoService) UploadComplete(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) error {
	video, err := s.repo.GetVideoByFilter(ctx, model.VideoFilter{ID: &videoID, UserID: &userID})
	if err != nil {
		return err
	}

	if err := s.storage.FileExist(ctx, video.ObjectKey); err != nil {
		return err
	}

	if _, err := s.repo.UpdateVideo(ctx, model.VideoPartial{ID: videoID, UserID: userID, Status: new(model.VideoStatusCompleted)}); err != nil {
		return err
	}
	return nil
}

func (s *VideoService) ClearExpiredVideos(ctx context.Context) error {
	return s.repo.DeleteVideosExpired(ctx)
}
