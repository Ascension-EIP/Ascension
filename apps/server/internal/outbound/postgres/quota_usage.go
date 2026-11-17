// @date 2026-09-24
// @file quota_usage.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
)

func (r *PostgresRepository) DeleteOldQuotaUsage(ctx context.Context) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"DELETE FROM quota_usages WHERE period_start < DATE_TRUNC('month', NOW()) - INTERVAL '24 months'")
	if err != nil {
		return dto.Error(err)
	}

	return nil
}
