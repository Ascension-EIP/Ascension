// @date 2026-09-20
// @file video.go
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"fmt"
	"net/url"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
)

type VideoService struct {
	cfgVideo config.VideoConfig
	cfgMinIO config.MinIOConfig
	storage  model.VideoStorage
	repo     model.VideoRepository
}

func NewVideoService(cfgVideo config.VideoConfig, cfgMinIO config.MinIOConfig, storage model.VideoStorage, repo model.VideoRepository) VideoService {
	return VideoService{cfgVideo: cfgVideo, cfgMinIO: cfgMinIO, storage: storage, repo: repo}
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

func (s *VideoService) GetUploadURL(ctx context.Context, userID uuid.UUID, videoMetadata model.VideoMetadata, videoConfig model.VideoConfig) (model.VideoUploadURL, error) {
	if err := videoConfig.Validate(); err != nil {
		return model.VideoUploadURL{}, fmt.Errorf("validate video info: %w", err)
	}

	var url *url.URL
	var expiresAt time.Time

	videoID := uuid.NewV7() // can't rely on repo for this one since we need the id for the objectKey

	objectKey := fmt.Sprintf("%s/%s.%s", userID.String(), videoID.String(), videoMetadata.Extension)

	if err := s.repo.WithTransaction(ctx, func(ctx context.Context) error {
		if err := s.repo.CreateVideo(ctx, model.Video{
			ID:                 videoID,
			UserID:             userID,
			ClimbingSessionID:  videoConfig.ClimbingSessionID,
			Title:              videoConfig.Title,
			ObjectKey:          objectKey,
			Status:             model.VideoStatusPending,
			Visibility:         videoConfig.Visibility,
			ContentType:        videoMetadata.ContentType,
			SizeBytes:          new(videoMetadata.Size),
			Retained:           videoConfig.Retained,
			UploadURLExpiresAt: new(time.Now().Add(s.cfgMinIO.UploadExp)),
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

	// collect missing value for video row
	//TODO faut installer ffprobe pour cette merde

	if _, err := s.repo.UpdateVideo(ctx, model.VideoPartial{ID: videoID, UserID: userID, Status: new(model.VideoStatusCompleted), UploadURLExpiresAt: new((*time.Time)(nil))}); err != nil {
		return err
	}
	return nil
}

func (s *VideoService) ClearUploadExpiredVideos(ctx context.Context) error {
	return s.repo.DeleteVideosUploadExpired(ctx)
}

func (s *VideoService) ClearExpiredVideos(ctx context.Context) error {
	return s.repo.DeleteVideosExpired(ctx, s.cfgVideo.Retention)
}
