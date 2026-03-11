package user

import (
	"context"
	"testing"

	"github.com/DimitriLaPoudre/go-backend-base/internal/entity"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type mockRepo struct {
	mock.Mock
}

func (m *mockRepo) CreateUser(ctx context.Context, user *entity.User) error {
	args := m.Called(ctx, user)
	return args.Error(0)
}
func (m *mockRepo) GetUserByID(ctx context.Context, id uint) (*entity.User, error) {
	args := m.Called(ctx, id)
	return args.Get(0).(*entity.User), args.Error(1)
}
func (m *mockRepo) ListAllUsers(ctx context.Context) ([]entity.User, error) {
	args := m.Called(ctx)
	return args.Get(0).([]entity.User), args.Error(1)
}
func (m *mockRepo) UpdateUser(ctx context.Context, user *entity.User) error {
	args := m.Called(ctx, user)
	return args.Error(0)
}
func (m *mockRepo) DeleteUser(ctx context.Context, id uint) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func TestService_CreateUser(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{r: repo}
	ctx := context.TODO()
	user := &entity.User{ID: 1, Username: "foo"}
	repo.On("CreateUser", ctx, user).Return(nil)
	err := s.CreateUser(ctx, user)
	assert.NoError(t, err)
	repo.AssertExpectations(t)
}

func TestService_GetUserByID(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{r: repo}
	ctx := context.TODO()
	user := &entity.User{ID: 1, Username: "foo"}
	repo.On("GetUserByID", ctx, uint(1)).Return(user, nil)
	u, err := s.GetUserByID(ctx, 1)
	assert.NoError(t, err)
	assert.Equal(t, user, u)
}

func TestService_IsAdmin(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{r: repo}
	ctx := context.TODO()
	admin := &entity.User{ID: 1, Type: entity.UserTypeAdmin}
	normal := &entity.User{ID: 2, Type: entity.UserTypeUser}
	repo.On("GetUserByID", ctx, uint(1)).Return(admin, nil)
	repo.On("GetUserByID", ctx, uint(2)).Return(normal, nil)
	assert.NoError(t, s.IsAdmin(ctx, 1))
	assert.ErrorIs(t, s.IsAdmin(ctx, 2), entity.ErrForbidden)
}

func TestService_IsUser(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{r: repo}
	ctx := context.TODO()
	user := &entity.User{ID: 1, Type: entity.UserTypeUser}
	admin := &entity.User{ID: 2, Type: entity.UserTypeAdmin}
	repo.On("GetUserByID", ctx, uint(1)).Return(user, nil)
	repo.On("GetUserByID", ctx, uint(2)).Return(admin, nil)
	assert.NoError(t, s.IsUser(ctx, 1))
	assert.ErrorIs(t, s.IsUser(ctx, 2), entity.ErrForbidden)
}

func TestService_ListAllUsers(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{r: repo}
	ctx := context.TODO()
	users := []entity.User{{ID: 1}, {ID: 2}}
	repo.On("ListAllUsers", ctx).Return(users, nil)
	result, err := s.ListAllUsers(ctx)
	assert.NoError(t, err)
	assert.Equal(t, users, result)
}

func TestService_UpdateUser(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{r: repo}
	ctx := context.TODO()
	user := &entity.User{ID: 1}
	repo.On("UpdateUser", ctx, user).Return(nil)
	err := s.UpdateUser(ctx, user)
	assert.NoError(t, err)
}

func TestService_DeleteUser(t *testing.T) {
	repo := new(mockRepo)
	s := &Service{r: repo}
	ctx := context.TODO()
	repo.On("DeleteUser", ctx, uint(1)).Return(nil)
	err := s.DeleteUser(ctx, 1)
	assert.NoError(t, err)
}
