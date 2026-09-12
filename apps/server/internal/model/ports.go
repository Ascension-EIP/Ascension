package model

import (
	"context"
	"net/url"
	"time"
	"uuid"
)

// -- Repository -- //

type UserRepository interface {
	TransactionRepository
	CreateUser(ctx context.Context, user User) (User, error)
	GetUserByFilter(ctx context.Context, filter UserFilter) (User, error)
	ListUsersByFilter(ctx context.Context, filter UserFilter) ([]User, error)
	UpdateUser(ctx context.Context, partial UserPartial) (User, error)
	DeleteUser(ctx context.Context, userID uuid.UUID) error
}

type SessionRepository interface {
	TransactionRepository
	CreateSession(ctx context.Context, session Session) (Session, error)
	GetUserByValidToken(ctx context.Context, token string) (User, error)
	DeleteSessionByTokenAndUserID(ctx context.Context, token string, userID uuid.UUID) error
	DeleteExpiredSessions(ctx context.Context) error
}

type AnalysisRepository interface {
	TransactionRepository
	CreateAnalysis(ctx context.Context, analysis *NewAnalysis) (*Analysis, error)
	GetAnalysis(ctx context.Context, analysisID uuid.UUID) (*Analysis, error)
}

type VideoRepository interface {
	TransactionRepository
	CreateVideoInfo(ctx context.Context, video *VideoInfo) error
	GetVideoInfoByUserID(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) (*VideoInfo, error)
	GetCompletedVideoInfoByUserID(ctx context.Context, videoID uuid.UUID, userID uuid.UUID) (*VideoInfo, error)
	UpdateVideoInfo(ctx context.Context, video *PartialVideoInfo) (*VideoInfo, error)
	WithTransaction(ctx context.Context, fn func(context.Context) error) error
}

type TransactionRepository interface {
	WithTransaction(ctx context.Context, fn func(context.Context) error) error
}

type Migrator interface {
	Migrate(dsn string) error
}

// -- //

// -- Storage -- //
type VideoStorage interface {
	PresignedUploadURL(context.Context, string) (*url.URL, time.Time, error)
	PresignedDownloadURL(context.Context, string) (*url.URL, time.Time, error)
	FileExist(context.Context, string) error
	Delete(context.Context, string) error
	UploadExp() time.Duration
	DownloadExp() time.Duration
	VideoBucket() string
}

// -- //

// -- Queue -- //

type AnalysisQueue interface {
	PublishJSONIntoQueueAI(ctx context.Context, body []byte) error
}

// -- //
