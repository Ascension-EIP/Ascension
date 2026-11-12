// @date 2026-11-13
// @file ports.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
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

	CreateUserProfile(ctx context.Context, userProfile UserProfile) (UserProfile, error)
	GetUserProfileByFilter(ctx context.Context, filter UserProfileFilter) (UserProfile, error)
	UpdateUserProfile(ctx context.Context, partial UserProfilePartial) (UserProfile, error)
	DeleteUserProfile(ctx context.Context, userID uuid.UUID) error
}

type SessionRepository interface {
	TransactionRepository
	CreateSession(ctx context.Context, session Session) (Session, error)
	GetUserByValidToken(ctx context.Context, token string) (User, error)
	DeleteSessionByTokenAndUserID(ctx context.Context, token string, userID uuid.UUID) error
	DeleteSessionsExpired(ctx context.Context) error
}

// UserBodyConstraintRepository stores the missing or injured body zones of the users.
type UserBodyConstraintRepository interface {
	// UpsertActiveUserBodyConstraint creates the active constraint of the user on its zone, or
	// replaces the type, note and start date of the one already active. created is false on a
	// replacement. A zero StartedAt means today on creation and unchanged on replacement.
	UpsertActiveUserBodyConstraint(ctx context.Context, constraint UserBodyConstraint) (stored UserBodyConstraint, created bool, err error)
	// ListActiveUserBodyConstraints returns the user's constraints that have not ended, by zone.
	ListActiveUserBodyConstraints(ctx context.Context, userID uuid.UUID) ([]UserBodyConstraint, error)
	// GetActiveUserBodyConstraint returns one of the user's active constraints, or ErrNotFound.
	GetActiveUserBodyConstraint(ctx context.Context, id uuid.UUID, userID uuid.UUID) (UserBodyConstraint, error)
	// EndUserBodyConstraint sets ended_at to today on one of the user's active constraints.
	EndUserBodyConstraint(ctx context.Context, id uuid.UUID, userID uuid.UUID) (UserBodyConstraint, error)
	// DeleteUserBodyConstraint deletes one of the user's constraints, or returns ErrNotFound.
	DeleteUserBodyConstraint(ctx context.Context, id uuid.UUID, userID uuid.UUID) error
}

// FriendshipRepository stores the friendships and finds users. Users who are not active,
// and pairs that are blocked, never appear in what it returns.
type FriendshipRepository interface {
	// CreateFriendRequest inserts a pending request from requesterID to addresseeID. It
	// returns ErrNotFound when the addressee is not an active user or when the pair already
	// has a friendship, whatever its status.
	CreateFriendRequest(ctx context.Context, requesterID uuid.UUID, addresseeID uuid.UUID) (Friendship, error)
	// GetFriendshipBetween returns the friendship of the pair, whichever side requested, or ErrNotFound.
	GetFriendshipBetween(ctx context.Context, userID uuid.UUID, otherID uuid.UUID) (Friendship, error)
	// ListFriendRequests returns the pending requests the user received and sent, newest first.
	ListFriendRequests(ctx context.Context, userID uuid.UUID) (FriendRequests, error)
	// AcceptFriendRequest accepts a pending request addressed to addresseeID, or returns ErrNotFound.
	AcceptFriendRequest(ctx context.Context, id uuid.UUID, addresseeID uuid.UUID) (Friendship, error)
	// DeleteFriendRequest deletes a pending request addressed to addresseeID, or returns ErrNotFound.
	DeleteFriendRequest(ctx context.Context, id uuid.UUID, addresseeID uuid.UUID) error
	// ListFriends returns one page of the user's friends by username, and the total count.
	ListFriends(ctx context.Context, userID uuid.UUID, pagination Pagination) ([]Friend, int, error)
	// SearchUsers returns one page of the users whose username contains query, the exact
	// match first, then the prefixes, then by username, and the total count. The viewer is
	// left out.
	SearchUsers(ctx context.Context, viewerID uuid.UUID, query string, pagination Pagination) ([]UserSearchResult, int, error)
}

// FeedRepository reads the climbing sessions other users share with a viewer.
type FeedRepository interface {
	// ListFeed returns one page of the sessions visible to the viewer in the scope, most
	// recent first, and the total count. The viewer's own sessions are left out.
	ListFeed(ctx context.Context, viewerID uuid.UUID, scope FeedScope, pagination Pagination) ([]FeedItem, int, error)
}

type AnalysisRepository interface {
	TransactionRepository
	CreateAnalysis(ctx context.Context, analysis Analysis) (Analysis, error)
	GetAnalysisByFilter(ctx context.Context, filter AnalysisFilter) (Analysis, error)
	// ListAnalysisSummariesByClimbingSessionID lists the analyses of the session's videos, newest first.
	ListAnalysisSummariesByClimbingSessionID(ctx context.Context, climbingSessionID uuid.UUID) ([]AnalysisSummary, error)
	// ListAnalysisSummariesByUserID returns one page of the analyses of the user's videos, newest first, and the total count.
	ListAnalysisSummariesByUserID(ctx context.Context, userID uuid.UUID, pagination Pagination) ([]AnalysisSummary, int, error)
}

type ClimbingSessionRepository interface {
	TransactionRepository
	CreateClimbingSession(ctx context.Context, climbingSession ClimbingSession) (ClimbingSession, error)
	GetClimbingSessionByFilter(ctx context.Context, filter ClimbingSessionFilter) (ClimbingSession, error)
	// GetActiveClimbingSessionByUserID returns the user's most recently started session that has not ended.
	GetActiveClimbingSessionByUserID(ctx context.Context, userID uuid.UUID) (ClimbingSession, error)
	// ListClimbingSessionsByUserID returns one page of the user's sessions, most recent first, and the total count.
	ListClimbingSessionsByUserID(ctx context.Context, userID uuid.UUID, pagination Pagination) ([]ClimbingSession, int, error)
	UpdateClimbingSession(ctx context.Context, partial ClimbingSessionPartial) (ClimbingSession, error)
	DeleteClimbingSession(ctx context.Context, id uuid.UUID, userID uuid.UUID) error
}

type VideoRepository interface {
	TransactionRepository
	CreateVideo(ctx context.Context, video Video) error
	GetVideoByFilter(ctx context.Context, filter VideoFilter) (Video, error)
	ListVideosByFilter(ctx context.Context, filter VideoFilter) ([]Video, error)
	UpdateVideo(ctx context.Context, partial VideoPartial) (Video, error)
	DeleteVideosUploadExpired(ctx context.Context) error
	DeleteVideosExpired(ctx context.Context, retainPeriod time.Duration) error
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
}

// -- //

// -- Queue -- //

type AnalysisQueue interface {
	// PublishPoseDetectRequested publishes a pose detection job for the AI worker.
	PublishPoseDetectRequested(ctx context.Context, body []byte) error
}

// -- //
