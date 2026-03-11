package jobs

import (
	"context"

	"github.com/DimitriLaPoudre/go-backend-base/internal/service/auth"
	"github.com/DimitriLaPoudre/go-backend-base/pkg/logger"
	"github.com/robfig/cron/v3"
)

func ExpiredSession(c *cron.Cron, ctx context.Context, l *logger.Logger, s *auth.Service) (cron.EntryID, error) {
	return c.AddFunc("0 0 * * *", func() {
		if err := s.CleanExpiredSession(ctx); err != nil {
			l.Warn().Err(err).Msg("jobs.ExpiredSession")
		}
	})
}
