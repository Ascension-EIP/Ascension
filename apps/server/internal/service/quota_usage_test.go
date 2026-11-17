// @date 2026-11-13
// @file quota_usage_test.go
// @brief Unit tests of the quota usage service.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"errors"
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

// failingQuotaUsageRepo fails to delete the old quota usage.
type failingQuotaUsageRepo struct{}

func (failingQuotaUsageRepo) DeleteOldQuotaUsage(context.Context) error { return errRepo }

func TestCleanOldQuotaUsage(t *testing.T) {
	repo := memrepo.New()
	s := NewQuotaUsageService(repo)

	if err := s.CleanOldQuotaUsage(context.Background()); err != nil {
		t.Fatalf("CleanOldQuotaUsage() error = %v", err)
	}
	if repo.QuotaCleanups() != 1 {
		t.Errorf("cleanups = %d, want 1", repo.QuotaCleanups())
	}

	failing := NewQuotaUsageService(failingQuotaUsageRepo{})
	if err := failing.CleanOldQuotaUsage(context.Background()); !errors.Is(err, errRepo) {
		t.Errorf("CleanOldQuotaUsage() error = %v, want %v", err, errRepo)
	}
}
