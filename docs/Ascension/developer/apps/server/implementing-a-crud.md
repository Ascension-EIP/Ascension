---
id: 9dc0698f-5c49-4b7f-b42e-bef9c9b4e7c8
---

:::success
**Version:** 2.1
:::

---

# How to Implement a CRUD

This guide explains how to add full **Create / Read / Update / Delete** operations for a new resource, following the clean/hexagonal architecture used by the Ascension server.

We will use a hypothetical **Post** resource as our example.

---

## Big picture: what you will create

For a resource called `Post`, you will create or extend the following files:

```
migrations/
├── <timestamp>_create_posts_table.up.sql     # PostgreSQL up migration
└── <timestamp>_create_posts_table.down.sql   # PostgreSQL down migration

internal/
├── model/
│   ├── post.go             # Entity structs, validation methods, and DTO conversion
│   └── ports.go            # PostRepository interface definition
├── service/
│   └── post.go             # Business logic orchestration
├── outbound/
│   └── postgres/
│       └── post.go         # pgxpool SQL queries and scanning
└── inbound/
    └── http/
        ├── dto/
        │   ├── request/post.go   # JSON request binding models
        │   └── response/post.go  # JSON response serializing models
        ├── handler/
        │   └── post.go     # Gin HTTP handler methods
        └── router/
            └── router.go   # Route registration and middleware attachment
```

---

## Step 1 – SQL migration

Create a migration pair in `apps/server/migrations/` (or run `moon run server:migrate` to verify):

**`migrations/20260922000000_create_posts_table.up.sql`**:

```sql
CREATE TABLE posts (
    id          UUID        PRIMARY KEY DEFAULT uuidv7(),
    title       TEXT        NOT NULL,
    content     TEXT        NOT NULL,
    author_id   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_posts_updated_at
BEFORE UPDATE ON posts
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

**`migrations/20260922000000_create_posts_table.down.sql`**:

```sql
DROP TABLE IF EXISTS posts;
```

---

## Step 2 – Domain model & Port

### 1. Create `internal/model/post.go`

```go
package model

import (
	"fmt"
	"strings"
	"time"
	"uuid"
)

type Post struct {
	ID        uuid.UUID `json:"id"`
	Title     string    `json:"title"`
	Content   string    `json:"content"`
	AuthorID  uuid.UUID `json:"author_id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type NewPost struct {
	Title    string    `json:"title"`
	Content  string    `json:"content"`
	AuthorID uuid.UUID `json:"author_id"`
}

func (p *NewPost) Validate() error {
	p.Title = strings.TrimSpace(p.Title)
	if p.Title == "" || len(p.Title) > 200 {
		return fmt.Errorf("title must be between 1 and 200 characters")
	}
	return nil
}
```

### 2. Add the repository port to `internal/model/ports.go`

```go
type PostRepository interface {
	CreatePost(ctx context.Context, p *NewPost) (*Post, error)
	GetPostByID(ctx context.Context, id uuid.UUID) (*Post, error)
}
```

---

## Step 3 – Service layer

Create `internal/service/post.go`:

```go
package service

import (
	"context"
	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type PostService struct {
	repo model.PostRepository
}

func NewPostService(repo model.PostRepository) PostService {
	return PostService{repo: repo}
}

func (s *PostService) Create(ctx context.Context, newPost *model.NewPost) (*model.Post, error) {
	if err := newPost.Validate(); err != nil {
		return nil, fmt.Errorf("%w: %s", model.ErrInvalidInput, err.Error())
	}
	return s.repo.CreatePost(ctx, newPost)
}

func (s *PostService) GetByID(ctx context.Context, id uuid.UUID) (*model.Post, error) {
	return s.repo.GetPostByID(ctx, id)
}
```

---

## Step 4 – Outbound adapter (PostgreSQL)

Create `internal/outbound/postgres/post.go` implementing `model.PostRepository`:

```go
package postgres

import (
	"context"
	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

func (r *PostgresRepository) CreatePost(ctx context.Context, p *model.NewPost) (*model.Post, error) {
	query := `
		INSERT INTO posts (title, content, author_id)
		VALUES ($1, $2, $3)
		RETURNING id, title, content, author_id, created_at, updated_at
	`
	var post model.Post
	err := r.Pool.QueryRow(ctx, query, p.Title, p.Content, p.AuthorID).Scan(
		&post.ID,
		&post.Title,
		&post.Content,
		&post.AuthorID,
		&post.CreatedAt,
		&post.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &post, nil
}

func (r *PostgresRepository) GetPostByID(ctx context.Context, id uuid.UUID) (*model.Post, error) {
	query := `
		SELECT id, title, content, author_id, created_at, updated_at
		FROM posts
		WHERE id = $1
	`
	var post model.Post
	err := r.Pool.QueryRow(ctx, query, id).Scan(
		&post.ID,
		&post.Title,
		&post.Content,
		&post.AuthorID,
		&post.CreatedAt,
		&post.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &post, nil
}
```

---

## Step 5 – Inbound handlers (HTTP)

Create `internal/inbound/http/handler/post.go`:

```go
package handler

import (
	"net/http"
	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/macro"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/utils"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
)

type PostHandler struct {
	s *service.PostService
}

func NewPostHandler(s *service.PostService) PostHandler {
	return PostHandler{s: s}
}

type CreatePostRequest struct {
	Title   string `json:"title" binding:"required"`
	Content string `json:"content" binding:"required"`
}

func (h *PostHandler) Create(c *gin.Context) {
	user, err := utils.GetFromContext[model.User](c, macro.Me)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, response.NewError(err))
		return
	}

	newPost := &model.NewPost{
		Title:    req.Title,
		Content:  req.Content,
		AuthorID: user.ID,
	}

	post, err := h.s.Create(c.Request.Context(), newPost)
	if err != nil {
		utils.Error(c, err)
		return
	}

	c.JSON(http.StatusCreated, post)
}
```

---

## Step 6 – Register routes and wire dependencies

1. Register your routes in `internal/inbound/http/router/router.go`:

```go
func New(
	app *gin.Engine,
	cfg config.Config,
	authMW middleware.AuthHandler,
	// ... handlers ...
	postH *handler.PostHandler,
) {
	// ...
	postsGroup := v1.Group("/posts", middleware.RateLimiter(time.Minute, 60), authMW(model.UserRoleUser, model.UserRoleAdmin))
	{
		postsGroup.POST("/", postH.Create)
	}
}
```

2. Wire the dependencies in `internal/app/app.go`:

```go
postService := service.NewPostService(&repo)
postHandler := handler.NewPostHandler(&postService)

router.New(
	app,
	cfg,
	authMW,
	&userH,
	&authH,
	&videoH,
	&analysisH,
	&postHandler,
)
```

---

## Step 7 – Unit tests

```bash
moon run server:test
# or
go test ./internal/service/...
```
