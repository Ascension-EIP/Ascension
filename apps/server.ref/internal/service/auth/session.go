package auth

import (
	"crypto/rand"
	"encoding/hex"
)

func newSessionID() (string, error) {
	buf := make([]byte, 16)
	_, err := rand.Read(buf)
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(buf), nil
}
