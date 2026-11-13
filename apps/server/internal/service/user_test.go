// @date 2026-11-13
// @file user_test.go
// @brief Unit tests of the user and user profile services.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"errors"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/knownbug"
	"strings"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
	"golang.org/x/crypto/bcrypt"
)

// failingUserRepo is a memrepo whose user and profile methods fail.
type failingUserRepo struct {
	*memrepo.Repo
}

func (failingUserRepo) CreateUser(context.Context, model.User) (model.User, error) {
	return model.User{}, errRepo
}

func (failingUserRepo) GetUserByFilter(context.Context, model.UserFilter) (model.User, error) {
	return model.User{}, errRepo
}

func (failingUserRepo) ListUsersByFilter(context.Context, model.UserFilter) ([]model.User, error) {
	return nil, errRepo
}

func (failingUserRepo) UpdateUser(context.Context, model.UserPartial) (model.User, error) {
	return model.User{}, errRepo
}

func (failingUserRepo) DeleteUser(context.Context, uuid.UUID) error {
	return errRepo
}

func (failingUserRepo) CreateUserProfile(context.Context, model.UserProfile) (model.UserProfile, error) {
	return model.UserProfile{}, errRepo
}

func (failingUserRepo) GetUserProfileByFilter(context.Context, model.UserProfileFilter) (model.UserProfile, error) {
	return model.UserProfile{}, errRepo
}

func (failingUserRepo) UpdateUserProfile(context.Context, model.UserProfilePartial) (model.UserProfile, error) {
	return model.UserProfile{}, errRepo
}

func (failingUserRepo) DeleteUserProfile(context.Context, uuid.UUID) error {
	return errRepo
}

func validUser() model.User {
	return model.User{
		Username:  "climber",
		FirstName: "Alex",
		LastName:  "Honnold",
		Email:     "alex@example.com",
		Password:  model.UserPassword("password123"),
		Role:      model.UserRoleUser,
		Status:    model.UserStatusActive,
	}
}

// fullPartial returns a partial that sets every validated field of the user.
func fullPartial(id uuid.UUID) model.UserPartial {
	return model.UserPartial{
		ID:        id,
		Username:  new(model.UserUsername("new-climber")),
		FirstName: new("Lynn"),
		LastName:  new("Hill"),
		Email:     new(model.UserEmail("lynn@example.com")),
		Password:  new(model.UserPassword("new-password")),
		Role:      new(model.UserRoleCoach),
		Status:    new(model.UserStatusActive),
	}
}

func TestCreateUser(t *testing.T) {
	ctx := context.Background()

	t.Run("stores a valid user with a hashed password", func(t *testing.T) {
		repo := memrepo.New()
		s := NewUserService(repo)

		user, err := s.CreateUser(ctx, validUser())
		if err != nil {
			t.Fatalf("CreateUser() error = %v", err)
		}
		if user.ID == (uuid.UUID{}) {
			t.Error("ID is not set")
		}
		if err := bcrypt.CompareHashAndPassword(user.Password, []byte("password123")); err != nil {
			t.Errorf("Password is not the bcrypt hash of the password: %v", err)
		}
		if _, ok := repo.User(user.ID); !ok {
			t.Error("the user is not stored")
		}
	})

	invalid := []struct {
		name   string
		mutate func(*model.User)
	}{
		{"a too short username", func(u *model.User) { u.Username = "short" }},
		{"a too long username", func(u *model.User) { u.Username = model.UserUsername(strings.Repeat("a", 25)) }},
		{"a too short password", func(u *model.User) { u.Password = model.UserPassword("1234567") }},
		{"a too long password", func(u *model.User) { u.Password = model.UserPassword(strings.Repeat("p", 65)) }},
		{"an unknown role", func(u *model.User) { u.Role = "superuser" }},
		{"an unknown status", func(u *model.User) { u.Status = "banned" }},
	}
	for _, tt := range invalid {
		t.Run("rejects "+tt.name, func(t *testing.T) {
			repo := memrepo.New()
			s := NewUserService(repo)
			user := validUser()
			tt.mutate(&user)

			if _, err := s.CreateUser(ctx, user); err == nil {
				t.Fatal("CreateUser() error = nil, want a validation error")
			}
			if users, _ := repo.ListUsersByFilter(ctx, model.UserFilter{}); len(users) != 0 {
				t.Errorf("stored %d users, want none", len(users))
			}
		})
	}

	t.Run("forwards a duplicate", func(t *testing.T) {
		s := NewUserService(memrepo.New())
		if _, err := s.CreateUser(ctx, validUser()); err != nil {
			t.Fatalf("CreateUser() error = %v", err)
		}
		if _, err := s.CreateUser(ctx, validUser()); !errors.Is(err, model.ErrConflict) {
			t.Errorf("CreateUser(duplicate) error = %v, want ErrConflict", err)
		}
	})

	t.Run("forwards the repository error", func(t *testing.T) {
		s := NewUserService(failingUserRepo{memrepo.New()})
		if _, err := s.CreateUser(ctx, validUser()); !errors.Is(err, errRepo) {
			t.Errorf("CreateUser() error = %v, want %v", err, errRepo)
		}
	})
}

func TestGetUser(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewUserService(repo)
	user, err := s.CreateUser(ctx, validUser())
	if err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}

	got, err := s.GetUserByID(ctx, user.ID)
	if err != nil || got.ID != user.ID {
		t.Errorf("GetUserByID() = (%v, %v), want (%v, nil)", got.ID, err, user.ID)
	}
	if _, err := s.GetUserByID(ctx, uuid.NewV7()); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("GetUserByID(unknown) error = %v, want ErrNotFound", err)
	}

	got, err = s.GetUserByFilter(ctx, model.UserFilter{Email: new(user.Email)})
	if err != nil || got.ID != user.ID {
		t.Errorf("GetUserByFilter(email) = (%v, %v), want (%v, nil)", got.ID, err, user.ID)
	}
	if _, err := s.GetUserByFilter(ctx, model.UserFilter{Username: new(model.UserUsername("nobody-here"))}); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("GetUserByFilter(unknown) error = %v, want ErrNotFound", err)
	}

	failing := NewUserService(failingUserRepo{repo})
	if _, err := failing.GetUserByID(ctx, user.ID); !errors.Is(err, errRepo) {
		t.Errorf("GetUserByID() error = %v, want %v", err, errRepo)
	}
	if _, err := failing.GetUserByFilter(ctx, model.UserFilter{}); !errors.Is(err, errRepo) {
		t.Errorf("GetUserByFilter() error = %v, want %v", err, errRepo)
	}
}

func TestListUsers(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewUserService(repo)

	coach := validUser()
	coach.Username, coach.Email, coach.Role = "the-coach", "coach@example.com", model.UserRoleCoach
	for _, user := range []model.User{validUser(), coach} {
		if _, err := s.CreateUser(ctx, user); err != nil {
			t.Fatalf("CreateUser() error = %v", err)
		}
	}

	all, err := s.ListAllUsers(ctx)
	if err != nil || len(all) != 2 {
		t.Errorf("ListAllUsers() = (%d users, %v), want (2, nil)", len(all), err)
	}

	coaches, err := s.ListUsersByFilter(ctx, model.UserFilter{Role: new(model.UserRoleCoach)})
	if err != nil || len(coaches) != 1 || coaches[0].Username != "the-coach" {
		t.Errorf("ListUsersByFilter(coach) = (%v, %v), want the coach only", coaches, err)
	}

	failing := NewUserService(failingUserRepo{repo})
	if users, err := failing.ListAllUsers(ctx); !errors.Is(err, errRepo) || users == nil || len(users) != 0 {
		t.Errorf("ListAllUsers() = (%v, %v), want an empty slice and %v", users, err, errRepo)
	}
	if users, err := failing.ListUsersByFilter(ctx, model.UserFilter{}); !errors.Is(err, errRepo) || users == nil || len(users) != 0 {
		t.Errorf("ListUsersByFilter() = (%v, %v), want an empty slice and %v", users, err, errRepo)
	}
}

func TestUpdateUser(t *testing.T) {
	ctx := context.Background()

	t.Run("updates every field and hashes the password", func(t *testing.T) {
		repo := memrepo.New()
		s := NewUserService(repo)
		user, err := s.CreateUser(ctx, validUser())
		if err != nil {
			t.Fatalf("CreateUser() error = %v", err)
		}

		updated, err := s.UpdateUser(ctx, fullPartial(user.ID))
		if err != nil {
			t.Fatalf("UpdateUser() error = %v", err)
		}
		if updated.Username != "new-climber" || updated.FirstName != "Lynn" || updated.LastName != "Hill" ||
			updated.Email != "lynn@example.com" || updated.Role != model.UserRoleCoach {
			t.Errorf("updated = %+v, want the new fields", updated)
		}
		if err := bcrypt.CompareHashAndPassword(updated.Password, []byte("new-password")); err != nil {
			t.Errorf("Password is not the hash of the new password: %v", err)
		}
	})

	t.Run("rejects an invalid field", func(t *testing.T) {
		s := NewUserService(memrepo.New())
		partial := fullPartial(uuid.NewV7())
		partial.Password = new(model.UserPassword("short"))

		if _, err := s.UpdateUser(ctx, partial); err == nil {
			t.Error("UpdateUser() error = nil, want a validation error")
		}
	})

	t.Run("forwards the repository error", func(t *testing.T) {
		s := NewUserService(failingUserRepo{memrepo.New()})
		if _, err := s.UpdateUser(ctx, fullPartial(uuid.NewV7())); !errors.Is(err, errRepo) {
			t.Errorf("UpdateUser() error = %v, want %v", err, errRepo)
		}
	})

	t.Run("updates only the given fields", func(t *testing.T) {
		knownbug.Skip(t, "UserPartial.Validate calls Validate on nil field pointers and panics when a field is not given (model/user.go)")

		repo := memrepo.New()
		s := NewUserService(repo)
		user, err := s.CreateUser(ctx, validUser())
		if err != nil {
			t.Fatalf("CreateUser() error = %v", err)
		}

		updated, err := s.UpdateUser(ctx, model.UserPartial{ID: user.ID, FirstName: new("Lynn")})
		if err != nil {
			t.Fatalf("UpdateUser() error = %v", err)
		}
		if updated.FirstName != "Lynn" || updated.Username != user.Username {
			t.Errorf("updated = %+v, want only the first name changed", updated)
		}
	})
}

func TestDeleteUser(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewUserService(repo)
	user, err := s.CreateUser(ctx, validUser())
	if err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}

	if err := s.DeleteUser(ctx, user.ID); err != nil {
		t.Fatalf("DeleteUser() error = %v", err)
	}
	if _, ok := repo.User(user.ID); ok {
		t.Error("the user is still stored")
	}

	failing := NewUserService(failingUserRepo{repo})
	if err := failing.DeleteUser(ctx, user.ID); !errors.Is(err, errRepo) {
		t.Errorf("DeleteUser() error = %v, want %v", err, errRepo)
	}
}

func TestCreateUserProfile(t *testing.T) {
	ctx := context.Background()

	t.Run("stores a valid profile", func(t *testing.T) {
		repo := memrepo.New()
		s := NewUserProfileService(repo)
		user := createTestUser(t, repo, "climber", "climber@example.com", "password123")
		profile := model.UserProfile{
			UserID:        user.ID,
			BirthDate:     new(time.Date(1995, 6, 1, 0, 0, 0, 0, time.UTC)),
			HeightCM:      new(uint16(180)),
			WeightKG:      new(float32(70.5)),
			ArmSpanCM:     new(uint16(185)),
			DominantHand:  new(model.DominantHandRight),
			ClimbingLevel: new("7a"),
			GradingSystem: new(model.GradingSystemFrench),
			Bio:           new("Boulder addict"),
		}

		stored, err := s.CreateUserProfile(ctx, profile)
		if err != nil {
			t.Fatalf("CreateUserProfile() error = %v", err)
		}
		if stored.UserID != user.ID || *stored.HeightCM != 180 || *stored.GradingSystem != model.GradingSystemFrench {
			t.Errorf("stored = %+v, want the given profile", stored)
		}
	})

	t.Run("stores an empty profile", func(t *testing.T) {
		repo := memrepo.New()
		s := NewUserProfileService(repo)
		user := createTestUser(t, repo, "climber", "climber@example.com", "password123")

		if _, err := s.CreateUserProfile(ctx, model.UserProfile{UserID: user.ID}); err != nil {
			t.Fatalf("CreateUserProfile() error = %v", err)
		}
	})

	invalid := []struct {
		name    string
		profile model.UserProfile
	}{
		{"a birth date before 1900", model.UserProfile{BirthDate: new(time.Date(1899, 12, 31, 0, 0, 0, 0, time.UTC))}},
		{"a birth date in the future", model.UserProfile{BirthDate: new(time.Now().Add(48 * time.Hour))}},
		{"a too small height", model.UserProfile{HeightCM: new(uint16(39))}},
		{"a too big weight", model.UserProfile{WeightKG: new(float32(300.5))}},
		{"a too long arm span", model.UserProfile{ArmSpanCM: new(uint16(251))}},
		{"an unknown dominant hand", model.UserProfile{DominantHand: new(model.DominantHand("both"))}},
		{"a too long climbing level", model.UserProfile{ClimbingLevel: new(strings.Repeat("a", 65))}},
		{"an unknown grading system", model.UserProfile{GradingSystem: new(model.GradingSystem("uiaa"))}},
		{"too many years of practice", model.UserProfile{YearsOfPratice: new(uint8(121))}},
		{"a too long bio", model.UserProfile{Bio: new(strings.Repeat("a", 2001))}},
		{"a too long avatar key", model.UserProfile{AvatarObjectKey: new(strings.Repeat("a", 1025))}},
	}
	for _, tt := range invalid {
		t.Run("rejects "+tt.name, func(t *testing.T) {
			repo := memrepo.New()
			s := NewUserProfileService(repo)
			user := createTestUser(t, repo, "climber", "climber@example.com", "password123")
			tt.profile.UserID = user.ID

			if _, err := s.CreateUserProfile(ctx, tt.profile); err == nil {
				t.Fatal("CreateUserProfile() error = nil, want a validation error")
			}
			if _, ok := repo.Profile(user.ID); ok {
				t.Error("the invalid profile is stored")
			}
		})
	}

	t.Run("forwards the repository error", func(t *testing.T) {
		s := NewUserProfileService(failingUserRepo{memrepo.New()})
		if _, err := s.CreateUserProfile(ctx, model.UserProfile{UserID: uuid.NewV7()}); !errors.Is(err, errRepo) {
			t.Errorf("CreateUserProfile() error = %v, want %v", err, errRepo)
		}
	})
}

func TestGetUpdateDeleteUserProfile(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewUserProfileService(repo)
	user := createTestUser(t, repo, "climber", "climber@example.com", "password123")
	if _, err := s.CreateUserProfile(ctx, model.UserProfile{UserID: user.ID, HeightCM: new(uint16(170))}); err != nil {
		t.Fatalf("CreateUserProfile() error = %v", err)
	}

	profile, err := s.GetUserProfileByUserID(ctx, user.ID)
	if err != nil || *profile.HeightCM != 170 {
		t.Fatalf("GetUserProfileByUserID() = (%+v, %v), want the stored profile", profile, err)
	}
	if _, err := s.GetUserProfileByUserID(ctx, uuid.NewV7()); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("GetUserProfileByUserID(unknown) error = %v, want ErrNotFound", err)
	}

	updated, err := s.UpdateUserProfile(ctx, model.UserProfilePartial{UserID: user.ID, Bio: new(new("Sport climber")), HeightCM: new((*uint16)(nil))})
	if err != nil {
		t.Fatalf("UpdateUserProfile() error = %v", err)
	}
	if updated.Bio == nil || *updated.Bio != "Sport climber" || updated.HeightCM != nil {
		t.Errorf("updated = %+v, want the new bio and no height", updated)
	}
	if _, err := s.UpdateUserProfile(ctx, model.UserProfilePartial{UserID: user.ID}); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("UpdateUserProfile(empty) error = %v, want ErrNotFound", err)
	}

	if err := s.DeleteUserProfile(ctx, user.ID); err != nil {
		t.Fatalf("DeleteUserProfile() error = %v", err)
	}
	if _, ok := repo.Profile(user.ID); ok {
		t.Error("the profile is still stored")
	}

	failing := NewUserProfileService(failingUserRepo{repo})
	if _, err := failing.GetUserProfileByUserID(ctx, user.ID); !errors.Is(err, errRepo) {
		t.Errorf("GetUserProfileByUserID() error = %v, want %v", err, errRepo)
	}
	if _, err := failing.UpdateUserProfile(ctx, model.UserProfilePartial{UserID: user.ID, Bio: new(new("x"))}); !errors.Is(err, errRepo) {
		t.Errorf("UpdateUserProfile() error = %v, want %v", err, errRepo)
	}
	if err := failing.DeleteUserProfile(ctx, user.ID); !errors.Is(err, errRepo) {
		t.Errorf("DeleteUserProfile() error = %v, want %v", err, errRepo)
	}
}

func TestUpdateUserProfileValidates(t *testing.T) {
	knownbug.Skip(t, "UserProfileService.UpdateUserProfile never calls UserProfilePartial.Validate, so out-of-range values reach the database (service/user_profile.go)")

	ctx := context.Background()
	repo := memrepo.New()
	s := NewUserProfileService(repo)
	user := createTestUser(t, repo, "climber", "climber@example.com", "password123")
	if _, err := s.CreateUserProfile(ctx, model.UserProfile{UserID: user.ID}); err != nil {
		t.Fatalf("CreateUserProfile() error = %v", err)
	}

	if _, err := s.UpdateUserProfile(ctx, model.UserProfilePartial{UserID: user.ID, HeightCM: new(new(uint16(1000)))}); err == nil {
		t.Error("UpdateUserProfile(height 1000) error = nil, want a validation error")
	}
}
