package postgres

import (
	"context"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

func (r *PostgresRepository) CreateAnalysis(ctx context.Context, analysis *model.NewAnalysis) (*model.Analysis, error) {
	return nil, nil
}

func (r *PostgresRepository) GetAnalysis(ctx context.Context, ID uuid.UUID, userID uuid.UUID) (*model.Analysis, error) {
	return nil, nil
}
