// @date 2026-11-13
// @file friendship_integration_test.go
// @brief Endpoint tests of /v1/friends, /v1/users/search and /v1/feed against PostgreSQL.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/pgtest"
)

func TestSocialEndpointsWithPostgres(t *testing.T) {
	db := pgtest.Open(t)
	testSocialEndpoints(t, socialFixture{
		repo:       db.Repo,
		createUser: db.CreateUserNamed,
		deactivate: db.DeactivateUser,
		block:      db.BlockPair,
	})
}
