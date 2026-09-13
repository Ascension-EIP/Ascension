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
