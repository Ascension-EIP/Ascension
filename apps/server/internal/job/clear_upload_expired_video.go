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
			slog.Error("failed to clear expired videos", slog.String("err", err.Error()))
		}
	}); err != nil {
		return err
	}

	return nil
}
