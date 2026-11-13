// @date 2026-09-24
// @file quota_usage.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"fmt"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type QuotaUsageService struct {
	repo model.QuotaUsageRepository
}

func NewQuotaUsageService(repo model.QuotaUsageRepository) QuotaUsageService {
	return QuotaUsageService{
		repo: repo,
	}
}

func (s *QuotaUsageService) CleanOldQuotaUsage(ctx context.Context) error {
	if err := s.repo.DeleteOldQuotaUsage(ctx); err != nil {
		return fmt.Errorf("delete old quota usage from db: %w", err)
	}

	return nil
}
