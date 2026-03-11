package db

import (
	"time"

	"github.com/DimitriLaPoudre/go-backend-base/pkg/logger"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func New(dsn string, migrationSrcURL string, l *logger.Logger) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.NewGormLogger(l),
	})
	if err != nil {
		return nil, err
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}
	sqlDB.SetMaxOpenConns(25)
	sqlDB.SetMaxIdleConns(25)
	sqlDB.SetConnMaxLifetime(time.Hour)

	if migrationSrcURL != "" {
		if err := Migrate(sqlDB, migrationSrcURL); err != nil {
			return nil, err
		}
	}

	return db, nil
}
