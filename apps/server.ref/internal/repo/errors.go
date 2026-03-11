package repo

import "errors"

var (
	ErrNotFound           = errors.New("record not found")
	ErrDuplicatedKey      = errors.New("duplicated key")
	ErrForeignKeyViolated = errors.New("foreign key violated")
	ErrModelNil           = errors.New("model provide is nil")
)
