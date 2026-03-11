package app

import (
	"context"
	"net/http"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/DimitriLaPoudre/go-backend-base/internal/infra/config"
	"github.com/DimitriLaPoudre/go-backend-base/internal/infra/db"
	"github.com/DimitriLaPoudre/go-backend-base/internal/infra/jobs"
	"github.com/DimitriLaPoudre/go-backend-base/internal/repo"
	"github.com/DimitriLaPoudre/go-backend-base/internal/service/auth"
	"github.com/DimitriLaPoudre/go-backend-base/internal/service/user"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/handler"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/middleware"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/router"
	"github.com/DimitriLaPoudre/go-backend-base/pkg/logger"
	"github.com/gin-gonic/gin"
	"github.com/robfig/cron/v3"
)

func Run(cfg *config.Config, l *logger.Logger) {
	db, err := db.New(cfg.DB.DSN(), cfg.DB.Migration, l)
	if err != nil {
		l.Fatal().Err(err).Msg("failed to connect to database")
	}
	repo := repo.New(db)

	authS := auth.New(cfg, repo)
	userS := user.New(cfg, repo)

	authH := handler.NewAuthHandler(cfg, authS)
	userH := handler.NewUserHandler(userS)

	guestMw := middleware.Guest(cfg, authS)
	authMw := middleware.Auth(cfg, authS)
	adminMw := middleware.Admin(userS)
	userMw := middleware.User(userS)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	c := cron.New()
	if _, err := jobs.ExpiredSession(c, ctx, l, authS); err != nil {
		l.Fatal().Err(err).Msg("failed to connect to database")
	}
	c.Start()

	gin.SetMode(gin.ReleaseMode)
	app := gin.New()
	router.New(app, cfg, l, repo,
		guestMw, authMw, adminMw, userMw,
		authH, userH,
	)
	httpServ := &http.Server{
		Addr:    ":" + strconv.Itoa(cfg.HTTP.Port),
		Handler: app,
	}
	go func() {
		l.Info().Msg("server starting on " + httpServ.Addr)
		if err := httpServ.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			l.Error().Err(err).Msg("failed to start server")
		}
	}()

	<-ctx.Done()
	stop()
	l.Info().Msg("CTRL-C successfully handle")

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := httpServ.Shutdown(ctx); err != nil {
		l.Error().Err(err).Msg("server forced to shutdown")
	}
	c.Stop().Done()
}
