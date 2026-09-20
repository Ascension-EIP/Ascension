package postgres

import "fmt"

func setArg[T any](setParts *[]string, args *[]any, column string, value *T) {
	if value != nil {
		*args = append(*args, *value)
		*setParts = append(*setParts, fmt.Sprintf("%s = $%d", column, len(*args)))
	}
}
