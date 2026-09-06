// @date 2026-09-06
// @file source_driver.go
// @brief Custom migration source driver supporting directory-per-migration layout.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	"github.com/golang-migrate/migrate/v4/source"
)

var dirRegex = regexp.MustCompile(`^([0-9]+)_(.*)$`)

type DirSource struct {
	path       string
	migrations *source.Migrations
}

func NewDirSource(dirPath string) (*DirSource, error) {
	entries, err := os.ReadDir(dirPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read migrations directory %s: %w", dirPath, err)
	}

	ms := source.NewMigrations()

	for _, entry := range entries {
		if entry.IsDir() {
			matches := dirRegex.FindStringSubmatch(entry.Name())
			if len(matches) < 3 {
				continue
			}

			versionNum, err := strconv.ParseUint(matches[1], 10, 64)
			if err != nil {
				continue
			}
			identifier := matches[2]
			subPath := filepath.Join(dirPath, entry.Name())

			// Look for up file: up.sql or <folder_name>.up.sql
			upFile := findFile(subPath, "up.sql", entry.Name()+".up.sql")
			if upFile != "" {
				m := &source.Migration{
					Version:    uint(versionNum),
					Identifier: identifier,
					Direction:  source.Up,
					Raw:        filepath.Join(entry.Name(), upFile),
				}
				if !ms.Append(m) {
					return nil, fmt.Errorf("duplicate migration up for version %d in %s", versionNum, entry.Name())
				}
			}

			// Look for down file: down.sql or <folder_name>.down.sql
			downFile := findFile(subPath, "down.sql", entry.Name()+".down.sql")
			if downFile != "" {
				m := &source.Migration{
					Version:    uint(versionNum),
					Identifier: identifier,
					Direction:  source.Down,
					Raw:        filepath.Join(entry.Name(), downFile),
				}
				if !ms.Append(m) {
					return nil, fmt.Errorf("duplicate migration down for version %d in %s", versionNum, entry.Name())
				}
			}
		} else {
			// Support flat files as well
			m, err := source.DefaultParse(entry.Name())
			if err == nil {
				m.Raw = entry.Name()
				if !ms.Append(m) {
					return nil, fmt.Errorf("duplicate migration file %s", entry.Name())
				}
			}
		}
	}

	return &DirSource{
		path:       dirPath,
		migrations: ms,
	}, nil
}

func findFile(dir string, candidates ...string) string {
	for _, c := range candidates {
		p := filepath.Join(dir, c)
		if fi, err := os.Stat(p); err == nil && !fi.IsDir() {
			return c
		}
	}
	return ""
}

func (s *DirSource) Open(url string) (source.Driver, error) {
	cleanPath := strings.TrimPrefix(url, "file://")
	cleanPath = strings.TrimPrefix(cleanPath, "folder://")
	cleanPath = strings.TrimPrefix(cleanPath, "dir://")
	return NewDirSource(cleanPath)
}

func (s *DirSource) Close() error {
	return nil
}

func (s *DirSource) First() (uint, error) {
	if v, ok := s.migrations.First(); ok {
		return v, nil
	}
	return 0, os.ErrNotExist
}

func (s *DirSource) Prev(version uint) (uint, error) {
	if v, ok := s.migrations.Prev(version); ok {
		return v, nil
	}
	return 0, os.ErrNotExist
}

func (s *DirSource) Next(version uint) (uint, error) {
	if v, ok := s.migrations.Next(version); ok {
		return v, nil
	}
	return 0, os.ErrNotExist
}

func (s *DirSource) ReadUp(version uint) (io.ReadCloser, string, error) {
	if m, ok := s.migrations.Up(version); ok {
		f, err := os.Open(filepath.Join(s.path, m.Raw))
		if err != nil {
			return nil, "", err
		}
		return f, m.Identifier, nil
	}
	return nil, "", os.ErrNotExist
}

func (s *DirSource) ReadDown(version uint) (io.ReadCloser, string, error) {
	if m, ok := s.migrations.Down(version); ok {
		f, err := os.Open(filepath.Join(s.path, m.Raw))
		if err != nil {
			return nil, "", err
		}
		return f, m.Identifier, nil
	}
	return nil, "", os.ErrNotExist
}
