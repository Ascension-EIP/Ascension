// @date 2026-11-13
// @file friendship.go
// @brief Friendship repository: friend requests, friends and the user search on the friendships table.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
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

const (
	// friendsOf selects the friendships of $1 with the status $2, joined with the active
	// user on the other side.
	friendsOf = `FROM friendships f
		JOIN users u ON u.id = CASE WHEN f.requester_id = $1 THEN f.addressee_id ELSE f.requester_id END
		WHERE $1 IN (f.requester_id, f.addressee_id) AND f.status = $2 AND u.status = 'active'`

	// usersMatching selects the active users other than $1 whose username is LIKE $2, with
	// the friendship of the pair if any, blocked pairs left out.
	usersMatching = `FROM users u
		LEFT JOIN friendships f
			ON LEAST(f.requester_id, f.addressee_id) = LEAST(u.id, $1)
			AND GREATEST(f.requester_id, f.addressee_id) = GREATEST(u.id, $1)
		WHERE u.status = 'active' AND u.id <> $1 AND u.username LIKE $2
			AND f.status IS DISTINCT FROM 'blocked'`
)

// CreateFriendRequest inserts a pending request, in one statement so that two concurrent
// requests of the same pair cannot both succeed. Nothing is inserted, and model.ErrNotFound
// returned, when the addressee is not an active user or the pair already has a friendship.
func (r *PostgresRepository) CreateFriendRequest(ctx context.Context, requesterID uuid.UUID, addresseeID uuid.UUID) (model.Friendship, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		`INSERT INTO friendships (requester_id, addressee_id)
		SELECT $1, id FROM users WHERE id = $2 AND status = 'active'
		ON CONFLICT ((LEAST(requester_id, addressee_id)), (GREATEST(requester_id, addressee_id))) DO NOTHING
		RETURNING *`,
		requesterID, addresseeID)
	if err != nil {
		return model.Friendship{}, dto.Error(err)
	}

	friendship, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Friendship])
	if err != nil {
		return model.Friendship{}, dto.Error(err)
	}

	return friendship.ToFriendship(), nil
}

// GetFriendshipBetween returns the friendship of the pair, whichever side requested.
func (r *PostgresRepository) GetFriendshipBetween(ctx context.Context, userID uuid.UUID, otherID uuid.UUID) (model.Friendship, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"SELECT * FROM friendships WHERE LEAST(requester_id, addressee_id) = LEAST($1::uuid, $2::uuid) AND GREATEST(requester_id, addressee_id) = GREATEST($1::uuid, $2::uuid)",
		userID, otherID)
	if err != nil {
		return model.Friendship{}, dto.Error(err)
	}

	friendship, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Friendship])
	if err != nil {
		return model.Friendship{}, dto.Error(err)
	}

	return friendship.ToFriendship(), nil
}

// ListFriendRequests returns the pending requests the user received and sent, newest first.
func (r *PostgresRepository) ListFriendRequests(ctx context.Context, userID uuid.UUID) (model.FriendRequests, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"SELECT f.id, f.requester_id, f.created_at, u.id AS user_id, u.username "+friendsOf+" ORDER BY f.created_at DESC, f.id DESC",
		userID, model.FriendshipPending)
	if err != nil {
		return model.FriendRequests{}, dto.Error(err)
	}

	dbRequests, err := pgx.CollectRows(rows, pgx.RowToStructByName[dto.FriendRequest])
	if err != nil {
		return model.FriendRequests{}, dto.Error(err)
	}

	requests := model.FriendRequests{Incoming: []model.FriendRequest{}, Outgoing: []model.FriendRequest{}}
	for _, dbRequest := range dbRequests {
		if dbRequest.RequesterID == userID {
			requests.Outgoing = append(requests.Outgoing, dbRequest.ToFriendRequest())
		} else {
			requests.Incoming = append(requests.Incoming, dbRequest.ToFriendRequest())
		}
	}

	return requests, nil
}

// AcceptFriendRequest accepts a pending request addressed to addresseeID.
func (r *PostgresRepository) AcceptFriendRequest(ctx context.Context, id uuid.UUID, addresseeID uuid.UUID) (model.Friendship, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"UPDATE friendships SET status = 'accepted', responded_at = NOW() WHERE id = $1 AND addressee_id = $2 AND status = 'pending' RETURNING *",
		id, addresseeID)
	if err != nil {
		return model.Friendship{}, dto.Error(err)
	}

	friendship, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.Friendship])
	if err != nil {
		return model.Friendship{}, dto.Error(err)
	}

	return friendship.ToFriendship(), nil
}

// DeleteFriendRequest deletes a pending request addressed to addresseeID: a declined
// request leaves no row, so the requester can ask again later.
func (r *PostgresRepository) DeleteFriendRequest(ctx context.Context, id uuid.UUID, addresseeID uuid.UUID) error {
	tx := r.getTx(ctx)

	tag, err := tx.Exec(ctx,
		"DELETE FROM friendships WHERE id = $1 AND addressee_id = $2 AND status = 'pending'",
		id, addresseeID)
	if err != nil {
		return dto.Error(err)
	}

	if tag.RowsAffected() == 0 {
		return model.ErrNotFound
	}

	return nil
}

// ListFriends returns one page of the user's friends by username, and the total count.
func (r *PostgresRepository) ListFriends(ctx context.Context, userID uuid.UUID, pagination model.Pagination) ([]model.Friend, int, error) {
	tx := r.getTx(ctx)

	var total int
	if err := tx.QueryRow(ctx, "SELECT COUNT(*) "+friendsOf, userID, model.FriendshipAccepted).Scan(&total); err != nil {
		return nil, 0, dto.Error(err)
	}

	rows, err := tx.Query(ctx,
		"SELECT f.id AS friendship_id, f.responded_at AS since, u.id AS user_id, u.username, u.first_name, u.last_name "+
			friendsOf+" ORDER BY u.username COLLATE \"C\" LIMIT $3 OFFSET $4",
		userID, model.FriendshipAccepted, pagination.Limit, pagination.Offset)
	if err != nil {
		return nil, 0, dto.Error(err)
	}

	dbFriends, err := pgx.CollectRows(rows, pgx.RowToStructByName[dto.Friend])
	if err != nil {
		return nil, 0, dto.Error(err)
	}

	return dto.FriendsToFriends(dbFriends), total, nil
}

// SearchUsers returns one page of the users whose username contains query, the exact
// match first, then the prefixes, then by username, and the total count.
func (r *PostgresRepository) SearchUsers(ctx context.Context, viewerID uuid.UUID, query string, pagination model.Pagination) ([]model.UserSearchResult, int, error) {
	tx := r.getTx(ctx)
	escaped := likeEscape(query)

	var total int
	if err := tx.QueryRow(ctx, "SELECT COUNT(*) "+usersMatching, viewerID, "%"+escaped+"%").Scan(&total); err != nil {
		return nil, 0, dto.Error(err)
	}

	rows, err := tx.Query(ctx,
		"SELECT u.id AS user_id, u.username, f.id AS friendship_id, f.status AS friendship_status, f.requester_id "+
			usersMatching+" ORDER BY u.username = $3 DESC, u.username LIKE $4 DESC, u.username COLLATE \"C\" LIMIT $5 OFFSET $6",
		viewerID, "%"+escaped+"%", query, escaped+"%", pagination.Limit, pagination.Offset)
	if err != nil {
		return nil, 0, dto.Error(err)
	}

	dbResults, err := pgx.CollectRows(rows, pgx.RowToStructByName[dto.UserSearchResult])
	if err != nil {
		return nil, 0, dto.Error(err)
	}

	return dto.UserSearchResultsToUserSearchResults(dbResults, viewerID), total, nil
}

// likeEscape escapes the LIKE wildcards of s, with the default backslash escape character.
func likeEscape(s string) string {
	return strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(s)
}
