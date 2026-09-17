// @date 2026-09-17
// @file analysis.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"fmt"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/jackc/pgx/v5"
)

func (r *PostgresRepository) CreateAnalysis(ctx context.Context, analysis model.Analysis) (model.Analysis, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"INSERT INTO analyses (video_id) VALUES ($1) RETURNING *",
		analysis.VideoID)
	if err != nil {
		return model.Analysis{}, dto.Error(err)
	}

	dbAnalysis, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Analysis])
	if err != nil {
		return model.Analysis{}, dto.Error(err)
	}

	return dbAnalysis.ToAnalysis(), nil

}

func (r *PostgresRepository) GetAnalysisByFilter(ctx context.Context, filter model.AnalysisFilter) (model.Analysis, error) {
	setParts := []string{}
	args := []any{}

	if filter.ID != nil {
		args = append(args, *filter.ID)
		setParts = append(setParts, fmt.Sprintf("id = $%d", len(args)))
	}
	if filter.VideoID != nil {
		args = append(args, *filter.VideoID)
		setParts = append(setParts, fmt.Sprintf("video_id = $%d", len(args)))
	}
	if filter.Status != nil {
		args = append(args, *filter.Status)
		setParts = append(setParts, fmt.Sprintf("status = $%d", len(args)))
	}

	query := "SELECT * FROM analyses"

	if len(setParts) > 0 {
		query += " WHERE " + strings.Join(setParts, " AND ")
	}

	query += " LIMIT 1"

	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.Analysis{}, dto.Error(err)
	}

	analysis, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Analysis])
	if err != nil {
		return model.Analysis{}, dto.Error(err)
	}

	return analysis.ToAnalysis(), nil
}
