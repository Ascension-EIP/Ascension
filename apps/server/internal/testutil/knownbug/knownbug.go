// @date 2026-11-13
// @file knownbug.go
// @brief Skip the tests that assert the correct behaviour of a known, not yet fixed bug.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done Package knownbug marks the tests written for a bug that is not fixed yet. They are skipped by default so the suite stays green, and run when RUN_KNOWN_BUGS is set: RUN_KNOWN_BUGS=1 go test ./... Once the bug is fixed, remove the Skip call so the test guards against a regression.
package knownbug

import (
	"os"
	"testing"
)

// EnvRun names the environment variable that runs the known bug tests instead of skipping them.
const EnvRun = "RUN_KNOWN_BUGS"

// Skip skips the test with the description of the bug, unless RUN_KNOWN_BUGS is set.
func Skip(t *testing.T, bug string) {
	t.Helper()

	if os.Getenv(EnvRun) == "" {
		t.Skip("known bug: " + bug)
	}
}
