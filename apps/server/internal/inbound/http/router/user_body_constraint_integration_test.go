// @date 2026-11-13
// @file user_body_constraint_integration_test.go
// @brief Endpoint tests of /v1/profile/constraints against PostgreSQL.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/pgtest"
)

func TestBodyConstraintEndpointsWithPostgres(t *testing.T) {
	db := pgtest.Open(t)
	testBodyConstraintEndpoints(t, db.Repo, db.CreateUser(t), db.CreateUser(t))
}
