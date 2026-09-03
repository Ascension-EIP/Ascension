// @date 2026-03-11
// @file main.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package main

import (
	"os"

	"github.com/rs/zerolog"
)

func main() {

	logger := zerolog.New(zerolog.ConsoleWriter{Out: os.Stdout})

	logger.Info().Str("username", "bob").Int("age", 21).Bool("gay", false).Msg("ask for a book")
}
