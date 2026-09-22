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

func ClearExpiredSessions(c *cron.Cron, ctx context.Context, session *service.SessionService) error {
	if _, err := c.AddFunc("0 0 * * *", func() {
		if err := session.ClearExpiredSessions(ctx); err != nil {
			slog.Error("failed to clear expired sessions", slog.String("err", err.Error()))
		}
	}); err != nil {
		return err
	}

	return nil
}
