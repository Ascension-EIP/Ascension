// @date 2026-11-12
// @file pagination.go
// @brief Offset pagination shared by list endpoints.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import "fmt"

const (
	PaginationDefaultLimit = 20
	PaginationMaxLimit     = 100
)

// Pagination selects a page of results: Limit items after skipping Offset items.
type Pagination struct {
	Limit  int
	Offset int
}

// NewPagination builds a pagination from optional client values, applying the defaults.
func NewPagination(limit *int, offset *int) (Pagination, error) {
	p := Pagination{Limit: PaginationDefaultLimit}

	if limit != nil {
		if err := validateRange(int64(*limit), 1, PaginationMaxLimit); err != nil {
			return Pagination{}, fmt.Errorf("%w: limit: %w", ErrInvalidInput, err)
		}
		p.Limit = *limit
	}

	if offset != nil {
		if *offset < 0 {
			return Pagination{}, fmt.Errorf("%w: offset: below minimum", ErrInvalidInput)
		}
		p.Offset = *offset
	}

	return p, nil
}
