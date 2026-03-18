package postgres

import (
	"context"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (r *PostgresRepository) CreateAnalysis(ctx context.Context, newAnalysis *model.NewAnalysis) (*model.Analysis, error) {
	if newAnalysis == nil {
		return nil, model.ErrUnknown
	}
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"INSERT INTO analysis (video_id) VALUES ($1) RETURNING *",
		newAnalysis.VideoID)
	if err != nil {
		return nil, err
	}

	analysis, err := pgx.CollectExactlyOneRow(rows, pgx.RowToAddrOfStructByName[dto.Analysis])
	if err != nil {
		return nil, err
	}

	return analysis.ToAnalysis(), nil

}

func (r *PostgresRepository) GetAnalysis(ctx context.Context, ID uuid.UUID) (*model.Analysis, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"SELECT * FROM analysis WHERE id = $1  LIMIT 1",
		ID)
	if err != nil {
		return nil, err
	}

	analysis, err := pgx.CollectExactlyOneRow(rows, pgx.RowToAddrOfStructByName[dto.Analysis])
	if err != nil {
		return nil, err
	}

	return analysis.ToAnalysis(), nil
}
