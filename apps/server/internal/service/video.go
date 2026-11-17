// @date 2026-11-12
// @file video.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
)

type VideoService struct {
	cfgVideo   config.VideoConfig
	cfgStorage config.StorageConfig
	storage    model.VideoStorage
	videoR     model.VideoRepository
	sessionR   model.ClimbingSessionRepository
}

func NewVideoService(cfgVideo config.VideoConfig, cfgStorage config.StorageConfig, storage model.VideoStorage, videoR model.VideoRepository, sessionR model.ClimbingSessionRepository) VideoService {
	return VideoService{cfgVideo: cfgVideo, cfgStorage: cfgStorage, storage: storage, videoR: videoR, sessionR: sessionR}
}

func (s *VideoService) GetDownloadURL(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) (model.VideoDownloadURL, error) {
	video, err := s.videoR.GetVideoByFilter(ctx, model.VideoFilter{ID: &videoID, UserID: &userID})
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

	if videoConfig.ClimbingSessionID != nil {
		if _, err := s.sessionR.GetClimbingSessionByFilter(ctx, model.ClimbingSessionFilter{ID: videoConfig.ClimbingSessionID, UserID: &userID}); err != nil {
			if errors.Is(err, model.ErrNotFound) {
				return model.VideoUploadURL{}, fmt.Errorf("%w: climbing_session_id: not found", model.ErrInvalidInput)
			}
			return model.VideoUploadURL{}, err
		}
	}

	var url *url.URL
	var expiresAt time.Time

	videoID := uuid.NewV7() // can't rely on repo for this one since we need the id for the objectKey

	objectKey := fmt.Sprintf("%s/%s.%s", userID.String(), videoID.String(), videoMetadata.Extension)

	if err := s.videoR.WithTransaction(ctx, func(ctx context.Context) error {
		if err := s.videoR.CreateVideo(ctx, model.Video{
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
			UploadURLExpiresAt: new(time.Now().Add(s.cfgStorage.UploadExp)),
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
	video, err := s.videoR.GetVideoByFilter(ctx, model.VideoFilter{ID: &videoID, UserID: &userID})
	if err != nil {
		return err
	}

	if ok, err := s.storage.FileExist(ctx, video.ObjectKey); !ok {
		if err == nil {
			return model.ErrVideoNotFound
		} else {
			return err
		}
	}

	// collect missing value for video row
	//TODO faut installer ffprobe pour cette merde

	if _, err := s.videoR.UpdateVideo(ctx, model.VideoPartial{ID: videoID, UserID: userID, Status: new(model.VideoStatusCompleted), UploadURLExpiresAt: new((*time.Time)(nil))}); err != nil {
		return err
	}
	return nil
}

func (s *VideoService) ClearUploadExpiredVideos(ctx context.Context) error {
	return s.videoR.DeleteVideosUploadExpired(ctx)
}

func (s *VideoService) ClearExpiredVideos(ctx context.Context) error {
	return s.videoR.DeleteVideosExpired(ctx, s.cfgVideo.Retention)
}

func (s *VideoService) GetVideoByUserID(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) (model.Video, error) {
	video, err := s.videoR.GetVideoByFilter(ctx, model.VideoFilter{ID: &videoID, UserID: &userID})
	if err != nil {
		return model.Video{}, fmt.Errorf("get video by filter from db: %w", err)
	}

	return video, nil
}

func (s *VideoService) ListVideosByUserID(ctx context.Context, userID uuid.UUID, pagination model.Pagination) ([]model.Video, error) {
	videos, err := s.videoR.ListVideosByFilter(ctx, model.VideoFilter{UserID: &userID}, pagination)
	if err != nil {
		return nil, fmt.Errorf("list videos by filter from db: %w", err)
	}

	return videos, nil
}
