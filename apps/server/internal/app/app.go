package app

import (
	"context"
	"net/http"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/handler"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/middleware"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/router"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/gin-gonic/gin"

	// "github.com/robfig/cron"
	"github.com/rs/zerolog"
)

func Run(cfg *config.Config, l *zerolog.Logger) {
	repo, err := postgres.New(l, cfg.DB.DSN(), cfg.DB.Migration)
	if err != nil {
		l.Fatal().Msg(err.Error())
	}

	jwtS := service.NewJWTService(cfg.Auth.JWT)
	sessionS := service.NewSessionService(cfg.Auth.Session, &repo)
	userS := service.NewUserService(&repo)
	authS := service.NewAuthService(&jwtS, &sessionS, &repo)
	videoS := service.NewVideoService()

	authMW := middleware.Auth(&jwtS)
	guestMW := middleware.Guest(&jwtS)
	adminMW := middleware.Admin()
	userMW := middleware.User()

	userH := handler.NewUserHandler(l, &userS)
	authH := handler.NewAuthHandler(l, &authS)
	videoH := handler.NewVideoHandler(l, &videoS)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	// c := cron.New()
	// if _, err := jobs.ExpiredSession(c, ctx, l, authS); err != nil {
	// 	l.Fatal().Err(err).Msg("failed to connect to database")
	// }
	// c.Start()

	app := gin.New()
	router.New(app, cfg, l,
		authMW,
		guestMW,
		adminMW,
		userMW,

		&userH,
		&authH,
		&videoH,
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
	// c.Stop().Done()
}
