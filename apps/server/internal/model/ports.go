package model

type Migrator interface {
	Migrate(dsn string) error
}
