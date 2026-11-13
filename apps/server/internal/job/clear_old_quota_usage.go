// @date 2026-09-13
// @file clear_expired_session.go
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

func ClearOldQuotaUsage(c *cron.Cron, ctx context.Context, quotaUsage *service.QuotaUsageService) error {
	if _, err := c.AddFunc("0 3 1 * *", func() {
		if err := quotaUsage.CleanOldQuotaUsage(ctx); err != nil {
			slog.Error("failed to clear old quota usage", slog.String("err", err.Error()))
		}
	}); err != nil {
		return err
	}

	return nil
}
