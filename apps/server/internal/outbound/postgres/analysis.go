// @date 2026-09-06
// @file analysis.go
// @brief PostgreSQL repository implementation for analyses.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
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

	analysisType := newAnalysis.Type
	if analysisType == "" {
		analysisType = model.AnalysisType2D
	}

	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"INSERT INTO analyses (video_id, type) VALUES ($1, $2) RETURNING *",
		newAnalysis.VideoID, string(analysisType))
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
		"SELECT * FROM analyses WHERE id = $1 LIMIT 1",
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

func (r *PostgresRepository) GetAnalysesByVideoID(ctx context.Context, videoID uuid.UUID) ([]*model.Analysis, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"SELECT * FROM analyses WHERE video_id = $1 ORDER BY created_at DESC",
		videoID)
	if err != nil {
		return nil, err
	}

	analysisDTOs, err := pgx.CollectRows(rows, pgx.RowToAddrOfStructByName[dto.Analysis])
	if err != nil {
		return nil, err
	}

	analyses := make([]*model.Analysis, 0, len(analysisDTOs))
	for _, a := range analysisDTOs {
		analyses = append(analyses, a.ToAnalysis())
	}
	return analyses, nil
}
