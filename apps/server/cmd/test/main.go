package main

import (
	"os"

	"github.com/rs/zerolog"
)

func main() {

	logger := zerolog.New(zerolog.ConsoleWriter{Out: os.Stdout})

	logger.Info().Str("username", "bob").Int("age", 21).Bool("gay", false).Msg("ask for a book")
}
