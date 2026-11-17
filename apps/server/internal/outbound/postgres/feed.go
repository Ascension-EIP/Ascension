// @date 2026-11-13
// @file feed.go
// @brief Feed repository: the climbing sessions other users share with a viewer.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/jackc/pgx/v5"
	"uuid"
)

// feedOf selects the sessions of the active users other than $1 that $1 may see: those
// of a friend shared with friends or public and, when $2 is true, every public session.
// A blocked pair hides its sessions both ways, public ones included.
const feedOf = `FROM climbing_sessions cs
	JOIN users u ON u.id = cs.user_id AND u.status = 'active'
	LEFT JOIN friendships f
		ON LEAST(f.requester_id, f.addressee_id) = LEAST(cs.user_id, $1)
		AND GREATEST(f.requester_id, f.addressee_id) = GREATEST(cs.user_id, $1)
	WHERE cs.user_id <> $1
		AND f.status IS DISTINCT FROM 'blocked'
		AND (
			(f.status = 'accepted' AND cs.visibility IN ('friends', 'public'))
			OR ($2::boolean AND cs.visibility = 'public')
		)`

// ListFeed returns one page of the sessions visible to the viewer in the scope, most
// recent first, and the total count.
func (r *PostgresRepository) ListFeed(ctx context.Context, viewerID uuid.UUID, scope model.FeedScope, pagination model.Pagination) ([]model.FeedItem, int, error) {
	tx := r.getTx(ctx)
	everyonePublic := scope == model.FeedScopeAll

	var total int
	if err := tx.QueryRow(ctx, "SELECT COUNT(*) "+feedOf, viewerID, everyonePublic).Scan(&total); err != nil {
		return nil, 0, dto.Error(err)
	}

	rows, err := tx.Query(ctx,
		"SELECT cs.*, u.username AS author_username "+feedOf+" ORDER BY cs.started_at DESC, cs.id DESC LIMIT $3 OFFSET $4",
		viewerID, everyonePublic, pagination.Limit, pagination.Offset)
	if err != nil {
		return nil, 0, dto.Error(err)
	}

	dbItems, err := pgx.CollectRows(rows, pgx.RowToStructByName[dto.FeedItem])
	if err != nil {
		return nil, 0, dto.Error(err)
	}

	return dto.FeedItemsToFeedItems(dbItems), total, nil
}
