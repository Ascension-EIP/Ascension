package auth

import (
	"context"
	"testing"
	"time"

	"github.com/DimitriLaPoudre/go-backend-base/internal/entity"
	"github.com/DimitriLaPoudre/go-backend-base/internal/infra/config"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"golang.org/x/crypto/bcrypt"
)

type mockRepo struct {
	mock.Mock
}

func (m *mockRepo) CreateUser(ctx context.Context, user *entity.User) error {
	args := m.Called(ctx, user)
	return args.Error(0)
}
func (m *mockRepo) GetUserByUsername(ctx context.Context, username string) (*entity.User, error) {
	args := m.Called(ctx, username)
	return args.Get(0).(*entity.User), args.Error(1)
}
func (m *mockRepo) GetUnexpiredSession(ctx context.Context, sessionID string) (*entity.Session, error) {
	args := m.Called(ctx, sessionID)
	return args.Get(0).(*entity.Session), args.Error(1)
}
func (m *mockRepo) CreateSession(ctx context.Context, session *entity.Session) error {
	args := m.Called(ctx, session)
	return args.Error(0)
}
func (m *mockRepo) UpdateSession(ctx context.Context, session *entity.Session) error {
	args := m.Called(ctx, session)
	return args.Error(0)
}
func (m *mockRepo) DeleteSessionByUserID(ctx context.Context, userID uint, id string) error {
	args := m.Called(ctx, userID, id)
	return args.Error(0)
}
func (m *mockRepo) DeleteExpiredSessions(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func TestService_Signup(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{repo: repo}
	ctx := context.TODO()
	form := &entity.AuthForm{Username: "foo", Password: "BarBar123"}
	repo.On("CreateUser", ctx, mock.AnythingOfType("*entity.User")).Return(nil)
	err := s.Signup(ctx, form)
	assert.NoError(t, err)
}

func TestService_Login(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{repo: repo, cfg: config.AuthConfig{CookieExp: time.Hour}}
	ctx := context.TODO()
	user := &entity.User{ID: 1, Username: "foo"}
	form := &entity.AuthForm{Username: "foo", Password: "BarBar123"}
	// Hash password for test
	hash, _ := bcrypt.GenerateFromPassword([]byte(form.Password), bcrypt.DefaultCost)
	user.Password = string(hash)
	repo.On("GetUserByUsername", ctx, form.Username).Return(user, nil)
	repo.On("CreateSession", ctx, mock.AnythingOfType("*entity.Session")).Return(nil)
	_, err := s.Login(ctx, form)
	assert.NoError(t, err)
}

func TestService_Logout(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{repo: repo}
	ctx := context.TODO()
	repo.On("DeleteSessionByUserID", ctx, uint(1), "sess").Return(nil)
	err := s.Logout(ctx, 1, "sess")
	assert.NoError(t, err)
}

func TestService_ValidateSession(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{repo: repo}
	ctx := context.TODO()
	sess := &entity.Session{UserID: 1}
	repo.On("GetUnexpiredSession", ctx, "sess").Return(sess, nil)
	userID, err := s.ValidateSession(ctx, "sess")
	assert.NoError(t, err)
	assert.Equal(t, uint(1), userID)
}

func TestService_RefreshSession(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{repo: repo, cfg: config.AuthConfig{CookieExp: time.Hour}}
	ctx := context.TODO()
	repo.On("UpdateSession", ctx, mock.AnythingOfType("*entity.Session")).Return(nil)
	err := s.RefreshSession(ctx, "sess")
	assert.NoError(t, err)
}

func TestService_CleanExpiredSession(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{repo: repo}
	ctx := context.TODO()
	repo.On("DeleteExpiredSessions", ctx).Return(nil)
	err := s.CleanExpiredSession(ctx)
	assert.NoError(t, err)
}
