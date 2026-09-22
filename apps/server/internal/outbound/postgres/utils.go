// @date 2026-09-20
// @file utils.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import "fmt"

func setArg[T any](setParts *[]string, args *[]any, column string, value *T) {
	if value != nil {
		*args = append(*args, *value)
		*setParts = append(*setParts, fmt.Sprintf("%s = $%d", column, len(*args)))
	}
}
