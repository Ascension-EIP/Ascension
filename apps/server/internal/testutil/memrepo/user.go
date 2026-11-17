// @date 2026-11-13
// @file user.go
// @brief In-memory users, user profiles, refresh sessions and quota usage, with the rules of the PostgreSQL queries.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package memrepo

import (
	"context"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

// -- Users -- //

// CreateUser stores the user with its password hashed, like the PostgreSQL query. The
// username and the email are unique: a duplicate returns model.ErrConflict.
func (r *Repo) CreateUser(_ context.Context, user model.User) (model.User, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, stored := range r.users {
		if stored.Username == user.Username || (user.Email != "" && stored.Email == user.Email) {
			return model.User{}, model.ErrConflict
		}
	}

	hash, err := user.Password.Hash()
	if err != nil {
		return model.User{}, err
	}
	user.Password = hash
	user.ID = uuid.NewV7()
	user.CreatedAt = r.now()
	user.UpdatedAt = user.CreatedAt
	r.users[user.ID] = user

	return user, nil
}

func (r *Repo) GetUserByFilter(_ context.Context, filter model.UserFilter) (model.User, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, user := range r.users {
		if matchUser(user, filter) {
			return user, nil
		}
	}

	return model.User{}, model.ErrNotFound
}

func (r *Repo) ListUsersByFilter(_ context.Context, filter model.UserFilter) ([]model.User, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	users := []model.User{}
	for _, user := range r.users {
		if matchUser(user, filter) {
			users = append(users, user)
		}
	}

	return users, nil
}

// UpdateUser changes the given fields. Like the PostgreSQL query, an empty partial
// returns model.ErrUserNotFound and the password is hashed.
func (r *Repo) UpdateUser(_ context.Context, partial model.UserPartial) (model.User, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if partial.Username == nil && partial.FirstName == nil && partial.LastName == nil && partial.Email == nil &&
		partial.Role == nil && partial.Status == nil && partial.Password == nil {
		return model.User{}, model.ErrUserNotFound
	}

	user, ok := r.users[partial.ID]
	if !ok {
		return model.User{}, model.ErrNotFound
	}

	if partial.Username != nil {
		user.Username = *partial.Username
	}
	if partial.FirstName != nil {
		user.FirstName = *partial.FirstName
	}
	if partial.LastName != nil {
		user.LastName = *partial.LastName
	}
	if partial.Email != nil {
		user.Email = *partial.Email
	}
	if partial.Role != nil {
		user.Role = *partial.Role
	}
	if partial.Status != nil {
		user.Status = *partial.Status
	}
	if partial.Password != nil {
		hash, err := partial.Password.Hash()
		if err != nil {
			return model.User{}, err
		}
		user.Password = hash
	}
	user.UpdatedAt = r.now()
	r.users[user.ID] = user

	return user, nil
}

// DeleteUser deletes the user and, like the ON DELETE CASCADE foreign keys, its profile
// and sessions. Deleting a missing user is not an error.
func (r *Repo) DeleteUser(_ context.Context, userID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	delete(r.users, userID)
	delete(r.profiles, userID)
	for id, session := range r.refreshSessions {
		if session.UserID == userID {
			delete(r.refreshSessions, id)
		}
	}

	return nil
}

func matchUser(user model.User, filter model.UserFilter) bool {
	switch {
	case filter.ID != nil && user.ID != *filter.ID:
		return false
	case filter.Username != nil && user.Username != *filter.Username:
		return false
	case filter.FirstName != nil && user.FirstName != *filter.FirstName:
		return false
	case filter.LastName != nil && user.LastName != *filter.LastName:
		return false
	case filter.Email != nil && user.Email != *filter.Email:
		return false
	case filter.Role != nil && user.Role != *filter.Role:
		return false
	case filter.Status != nil && user.Status != *filter.Status:
		return false
	}

	return true
}

// -- User profiles -- //

// CreateUserProfile stores the profile of an existing user: an unknown user returns
// model.ErrInvalidInput (foreign key) and a second profile model.ErrConflict.
func (r *Repo) CreateUserProfile(_ context.Context, profile model.UserProfile) (model.UserProfile, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, ok := r.users[profile.UserID]; !ok {
		return model.UserProfile{}, model.ErrInvalidInput
	}
	if _, ok := r.profiles[profile.UserID]; ok {
		return model.UserProfile{}, model.ErrConflict
	}

	now := r.now()
	profile.CreatedAt = &now
	profile.UpdatedAt = &now
	r.profiles[profile.UserID] = profile

	return profile, nil
}

// GetUserProfileByFilter only filters on the user ID, the one filter the services use.
func (r *Repo) GetUserProfileByFilter(_ context.Context, filter model.UserProfileFilter) (model.UserProfile, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	for userID, profile := range r.profiles {
		if filter.UserID != nil && userID != *filter.UserID {
			continue
		}
		return profile, nil
	}

	return model.UserProfile{}, model.ErrNotFound
}

// UpdateUserProfile changes the given fields. Like the PostgreSQL query, an empty partial
// or a missing profile returns model.ErrNotFound.
func (r *Repo) UpdateUserProfile(_ context.Context, partial model.UserProfilePartial) (model.UserProfile, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	profile, ok := r.profiles[partial.UserID]
	if !ok {
		return model.UserProfile{}, model.ErrNotFound
	}

	changed := false
	if partial.BirthDate != nil {
		profile.BirthDate, changed = *partial.BirthDate, true
	}
	if partial.HeightCM != nil {
		profile.HeightCM, changed = *partial.HeightCM, true
	}
	if partial.WeightKG != nil {
		profile.WeightKG, changed = *partial.WeightKG, true
	}
	if partial.ArmSpanCM != nil {
		profile.ArmSpanCM, changed = *partial.ArmSpanCM, true
	}
	if partial.DominantHand != nil {
		profile.DominantHand, changed = *partial.DominantHand, true
	}
	if partial.ClimbingLevel != nil {
		profile.ClimbingLevel, changed = *partial.ClimbingLevel, true
	}
	if partial.GradingSystem != nil {
		profile.GradingSystem, changed = *partial.GradingSystem, true
	}
	if partial.YearsOfPratice != nil {
		profile.YearsOfPratice, changed = *partial.YearsOfPratice, true
	}
	if partial.Bio != nil {
		profile.Bio, changed = *partial.Bio, true
	}
	if partial.AvatarObjectKey != nil {
		profile.AvatarObjectKey, changed = *partial.AvatarObjectKey, true
	}
	if !changed {
		return model.UserProfile{}, model.ErrNotFound
	}
	now := r.now()
	profile.UpdatedAt = &now
	r.profiles[profile.UserID] = profile

	return profile, nil
}

// DeleteUserProfile deletes the user's profile. Deleting a missing profile is not an error.
func (r *Repo) DeleteUserProfile(_ context.Context, userID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	delete(r.profiles, userID)
	return nil
}

// -- Refresh sessions -- //

// CreateSession stores a refresh session of an existing user, or returns
// model.ErrInvalidInput (foreign key).
func (r *Repo) CreateSession(_ context.Context, session model.Session) (model.Session, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, ok := r.users[session.UserID]; !ok {
		return model.Session{}, model.ErrInvalidInput
	}
	session.ID = uuid.NewV7()
	session.CreatedAt = r.now()
	session.LastUsedAt = session.CreatedAt
	r.refreshSessions[session.ID] = session

	return session, nil
}

// GetUserByValidToken returns the owner of the session with the token hash that has not
// expired, or model.ErrNotFound.
func (r *Repo) GetUserByValidToken(_ context.Context, tokenHash string) (model.User, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := r.now()
	for _, session := range r.refreshSessions {
		if session.TokenHash != tokenHash || !session.ExpiresAt.After(now) {
			continue
		}
		if user, ok := r.users[session.UserID]; ok {
			return user, nil
		}
	}

	return model.User{}, model.ErrNotFound
}

// DeleteSessionByTokenAndUserID deletes the user's session with the token hash. Deleting
// a missing session is not an error.
func (r *Repo) DeleteSessionByTokenAndUserID(_ context.Context, tokenHash string, userID uuid.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	for id, session := range r.refreshSessions {
		if session.TokenHash == tokenHash && session.UserID == userID {
			delete(r.refreshSessions, id)
		}
	}

	return nil
}

// DeleteSessionsExpired deletes the expired sessions and the ones revoked more than 7 days ago.
func (r *Repo) DeleteSessionsExpired(_ context.Context) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := r.now()
	for id, session := range r.refreshSessions {
		if session.ExpiresAt.Before(now) || (session.RevokedAt != nil && session.RevokedAt.Before(now.Add(-7*24*time.Hour))) {
			delete(r.refreshSessions, id)
		}
	}

	return nil
}

// -- Quota usage -- //

// DeleteOldQuotaUsage counts its calls: the in-memory store keeps no quota usage.
func (r *Repo) DeleteOldQuotaUsage(context.Context) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.quotaCleanups++
	return nil
}

// -- Test helpers -- //

// User returns a stored user.
func (r *Repo) User(id uuid.UUID) (model.User, bool) {
	r.mu.Lock()
	defer r.mu.Unlock()

	user, ok := r.users[id]
	return user, ok
}

// Profile returns a stored user profile.
func (r *Repo) Profile(userID uuid.UUID) (model.UserProfile, bool) {
	r.mu.Lock()
	defer r.mu.Unlock()

	profile, ok := r.profiles[userID]
	return profile, ok
}

// Sessions returns a copy of the stored refresh sessions.
func (r *Repo) Sessions() []model.Session {
	r.mu.Lock()
	defer r.mu.Unlock()

	sessions := make([]model.Session, 0, len(r.refreshSessions))
	for _, session := range r.refreshSessions {
		sessions = append(sessions, session)
	}

	return sessions
}

// PutSession stores a refresh session as is, bypassing the checks of CreateSession.
func (r *Repo) PutSession(session model.Session) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if session.ID == (uuid.UUID{}) {
		session.ID = uuid.NewV7()
	}
	r.refreshSessions[session.ID] = session
}

// QuotaCleanups returns how many times DeleteOldQuotaUsage ran.
func (r *Repo) QuotaCleanups() int {
	r.mu.Lock()
	defer r.mu.Unlock()

	return r.quotaCleanups
}

// SetNow replaces the clock used for the creation, update and expiry times.
func (r *Repo) SetNow(now func() time.Time) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.now = now
}
