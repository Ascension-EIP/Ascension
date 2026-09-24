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
