// @date 2026-11-13
// @file analysis_stale_detection.go
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

func AnalysisStaleDetection(c *cron.Cron, ctx context.Context, analysis *service.AnalysisService) error {
	if _, err := c.AddFunc("* * * * *", func() {
		if err := analysis.AnalysisStaleDetection(ctx); err != nil {
			slog.Error("failed to detect stale analysis", slog.String("err", err.Error()))
		}
	}); err != nil {
		return err
	}

	return nil
}
