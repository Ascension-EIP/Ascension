package model

type Pagination struct {
	Offset int
	Limit  int // 0 mean infinity for repo
}
