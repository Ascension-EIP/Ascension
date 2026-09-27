// @date 2026-09-20
// @file clear_upload_expired_video.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package job

import (
	"context"
	"log/slog"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/robfig/cron/v3"
)

func ClearUploadExpiredVideos(c *cron.Cron, ctx context.Context, video *service.VideoService) error {
	if _, err := c.AddFunc("0 0 * * *", func() {
		if err := video.ClearUploadExpiredVideos(ctx); err != nil {
			slog.Error("failed to clear expired video uploads", slog.String("err", err.Error()))
		}
	}); err != nil {
		return err
	}

	return nil
}
