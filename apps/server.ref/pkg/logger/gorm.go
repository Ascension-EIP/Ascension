package logger

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"
)

type GormLogger struct {
	log                   zerolog.Logger
	LogLevel              gormlogger.LogLevel
	SlowThreshold         time.Duration
	SkipErrRecordNotFound bool
}

func NewGormLogger(l *Logger) *GormLogger {
	return &GormLogger{
		log:                   l.log,
		LogLevel:              gormlogger.Info,
		SlowThreshold:         200 * time.Millisecond,
		SkipErrRecordNotFound: true,
	}
}

func (g *GormLogger) LogMode(level gormlogger.LogLevel) gormlogger.Interface {
	newLogger := *g
	newLogger.LogLevel = level
	return &newLogger
}

func (g *GormLogger) Info(ctx context.Context, msg string, data ...any) {
	if g.LogLevel >= gormlogger.Info {
		g.log.Info().Msgf(msg, data...)
	}
}

func (g *GormLogger) Warn(ctx context.Context, msg string, data ...any) {
	if g.LogLevel >= gormlogger.Warn {
		g.log.Warn().Msgf(msg, data...)
	}
}

func (g *GormLogger) Error(ctx context.Context, msg string, data ...any) {
	if g.LogLevel >= gormlogger.Error {
		g.log.Error().Msgf(msg, data...)
	}
}

func (g *GormLogger) Trace(ctx context.Context, begin time.Time, fc func() (sql string, rowsAffected int64), err error) {
	if g.LogLevel <= gormlogger.Silent {
		return
	}

	elapsed := time.Since(begin)
	sql, rows := fc()

	switch {
	case err != nil && g.LogLevel >= gormlogger.Error && (!g.SkipErrRecordNotFound || !errors.Is(err, gorm.ErrRecordNotFound)):
		g.log.Error().
			Err(err).
			Dur("elapsed", elapsed).
			Int64("rows", rows).
			Str("sql", sql).
			Msg("query error")
	case elapsed > g.SlowThreshold && g.SlowThreshold != 0 && g.LogLevel >= gormlogger.Warn:
		g.log.Warn().
			Dur("elapsed", elapsed).
			Int64("rows", rows).
			Str("sql", sql).
			Msg("slow query")
	case g.LogLevel >= gormlogger.Info:
		g.log.Debug().
			Dur("elapsed", elapsed).
			Int64("rows", rows).
			Str("sql", sql).
			Msg("query")
	}
}
