// @date 2026-11-12
// @file analysis.go
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/jackc/pgx/v5"
	"uuid"
)

func (r *PostgresRepository) CreateAnalysis(ctx context.Context, analysis model.Analysis) (model.Analysis, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"INSERT INTO analyses (video_id, type, visibility) VALUES ($1, $2, $3) RETURNING *",
		analysis.VideoID, analysis.Type, analysis.Visibility)
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

	setArg(&setParts, &args, "id", filter.ID)
	setArg(&setParts, &args, "video_id", filter.VideoID)
	setArg(&setParts, &args, "type", filter.Type)
	setArg(&setParts, &args, "status", filter.Status)

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

// analysisSummaryColumns are the columns of dto.AnalysisSummary, read from analyses a joined with videos v.
const analysisSummaryColumns = "a.id, a.video_id, v.climbing_session_id, a.type, a.status, a.visibility, a.progress, a.started_at, a.completed_at, a.created_at"

// ListAnalysisSummariesByClimbingSessionID lists the analyses of the session's videos, newest first.
// The result, advice, hints and error payloads are not read.
func (r *PostgresRepository) ListAnalysisSummariesByClimbingSessionID(ctx context.Context, climbingSessionID uuid.UUID) ([]model.AnalysisSummary, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"SELECT "+analysisSummaryColumns+" FROM analyses a JOIN videos v ON v.id = a.video_id WHERE v.climbing_session_id = $1 ORDER BY a.created_at DESC, a.id DESC",
		climbingSessionID)
	if err != nil {
		return nil, dto.Error(err)
	}

	dbSummaries, err := pgx.CollectRows(rows, pgx.RowToStructByName[dto.AnalysisSummary])
	if err != nil {
		return nil, dto.Error(err)
	}

	return dto.AnalysisSummariesToAnalysisSummaries(dbSummaries), nil
}

// ListAnalysisSummariesByUserID returns one page of the analyses of the user's videos, newest
// first, and the total number of analyses the user has.
func (r *PostgresRepository) ListAnalysisSummariesByUserID(ctx context.Context, userID uuid.UUID, pagination model.Pagination) ([]model.AnalysisSummary, int, error) {
	tx := r.getTx(ctx)

	var total int
	if err := tx.QueryRow(ctx,
		"SELECT COUNT(*) FROM analyses a JOIN videos v ON v.id = a.video_id WHERE v.user_id = $1",
		userID,
	).Scan(&total); err != nil {
		return nil, 0, dto.Error(err)
	}

	rows, err := tx.Query(ctx,
		"SELECT "+analysisSummaryColumns+" FROM analyses a JOIN videos v ON v.id = a.video_id WHERE v.user_id = $1 ORDER BY a.created_at DESC, a.id DESC LIMIT $2 OFFSET $3",
		userID, pagination.Limit, pagination.Offset)
	if err != nil {
		return nil, 0, dto.Error(err)
	}

	dbSummaries, err := pgx.CollectRows(rows, pgx.RowToStructByName[dto.AnalysisSummary])
	if err != nil {
		return nil, 0, dto.Error(err)
	}

	return dto.AnalysisSummariesToAnalysisSummaries(dbSummaries), total, nil
}
