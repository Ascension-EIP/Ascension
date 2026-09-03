---
id: a2a24827-1264-4a89-9fe1-94a1774f1b40
---

> **Last updated:** 15th July 2026
> **Version:** 2.0
> **Authors:** Nicolas
> **Status:** Done
> {.is-success}

---

# How to Implement a CRUD

This guide explains how to add full **Create / Read / Update / Delete** operations for a new resource, following the clean/hexagonal architecture used by the Ascension server.

We will use a hypothetical **Post** resource as our example.

---

## Table of Contents

1. [Big picture: what you will create](#big-picture-what-you-will-create)

2. [Step 1 – SQL migration](#step-1--sql-migration)

3. [Step 2 – Domain models](#step-2--domain-models)

4. [Step 3 – Service and Repository Port](#step-3--service-and-repository-port)

5. [Step 4 – Outbound adapter (PostgreSQL)](#step-4--outbound-adapter-postgresql)

6. [Step 5 – Inbound handlers (HTTP)](#step-5--inbound-handlers-http)

7. [Step 6 – Register routes and wire dependencies](#step-6--register-routes-and-wire-dependencies)

8. [Step 7 – Unit tests](#step-7--unit-tests)


---

## Big picture: what you will create

For a resource called `Post`, you will create or extend the following files:

```
internal/
├── model/
│   └── post.go            # Structs representing the database record and value rules
├── service/
│   └── post.go            # Business logic and repository port interface
├── outbound/
│   └── postgres/
│       └── post.go        # pgx database operations
└── inbound/
    └── http/
        ├── handler/
        │   └── post.go    # Gin handlers for HTTP routes
        └── router/
            └── router.go  # Register route endpoints
```

---

## Step 1 – SQL migration

Create a new file in `migrations/` named with the current timestamp and a descriptive name:

```
migrations/20260305000000_create_posts_table.sql
```

Write your `CREATE TABLE` statement:

```sql
CREATE TABLE posts (
    id          UUID        PRIMARY KEY,
    title       TEXT        NOT NULL,
    content     TEXT        NOT NULL,
    author_id   UUID        NOT NULL REFERENCES users(id),
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_posts_updated_at
BEFORE UPDATE ON posts
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
```

---

## Step 2 – Domain models

Create `internal/model/post.go`. Define the core entity struct and validation:

```go
package model

import (
	"fmt"
	"strings"
	"github.com/google/uuid"
)

type Post struct {
	ID       uuid.UUID `json:"id"`
	Title    string    `json:"title"`
	Content  string    `json:"content"`
	AuthorID uuid.UUID `json:"author_id"`
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

---

## Step 3 – Service and Repository Port

Create `internal/service/post.go`. The service contains the business logic. It declares what database operations it needs using a local repository interface (port):

```go
package service

import (
	"context"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type postRepository interface {
	CreatePost(context.Context, *model.NewPost) (*model.Post, error)
	GetPostByID(context.Context, uuid.UUID) (*model.Post, error)
}

type PostService struct {
	r postRepository
}

func NewPostService(r postRepository) PostService {
	return PostService{r: r}
}

func (s *PostService) Create(ctx context.Context, newPost *model.NewPost) (*model.Post, error) {
	if err := newPost.Validate(); err != nil {
		return nil, err
	}
	return s.r.CreatePost(ctx, newPost)
}

func (s *PostService) GetByID(ctx context.Context, id uuid.UUID) (*model.Post, error) {
	return s.r.GetPostByID(ctx, id)
}
```

---

## Step 4 – Outbound adapter (PostgreSQL)

Create `internal/outbound/postgres/post.go`. Implement the `postRepository` interface using `pgxpool`:

```go
package postgres

import (
	"context"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

func (r PostgresRepository) CreatePost(ctx context.Context, p *model.NewPost) (*model.Post, error) {
	id := uuid.New()
	query := `INSERT INTO posts (id, title, content, author_id) VALUES ($1, $2, $3, $4)`
	_, err := r.Pool.Exec(ctx, query, id, p.Title, p.Content, p.AuthorID)
	if err != nil {
		return nil, err
	}
	return &model.Post{
		ID:       id,
		Title:    p.Title,
		Content:  p.Content,
		AuthorID: p.AuthorID,
	}, nil
}

func (r PostgresRepository) GetPostByID(ctx context.Context, id uuid.UUID) (*model.Post, error) {
	query := `SELECT id, title, content, author_id FROM posts WHERE id = $1`
	var post model.Post
	err := r.Pool.QueryRow(ctx, query, id).Scan(&post.ID, &post.Title, &post.Content, &post.AuthorID)
	if err != nil {
		return nil, err
	}
	return &post, nil
}
```

---

## Step 5 – Inbound handlers (HTTP)

Create `internal/inbound/http/handler/post.go`. This controller binds requests, invokes the service, and formats responses:

```go
package handler

import (
	"net/http"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/request"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/utils"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/rs/zerolog"
)

type PostHandler struct {
	s *service.PostService
	l *zerolog.Logger
}

func NewPostHandler(l *zerolog.Logger, s *service.PostService) PostHandler {
	return PostHandler{s: s, l: l}
}

type CreatePostRequest struct {
	Title   string `json:"title" binding:"required"`
	Content string `json:"content" binding:"required"`
}

func (h *PostHandler) Create(c *gin.Context) {
	userID, err := utils.GetFromContext[uuid.UUID](c, "userID")
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	newPost := &model.NewPost{
		Title:    req.Title,
		Content:  req.Content,
		AuthorID: userID,
	}

	post, err := h.s.Create(c.Request.Context(), newPost)
	if err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
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
	// ... handlers ...
	postH *handler.PostHandler,
) {
	// ...
	postsGroup := v1.Group("/posts")
	{
		postsGroup.Use(authMW, userMW)
		postsGroup.POST("/", postH.Create)
	}
}
```

2. Wire the dependencies in `internal/app/app.go`:


```go
postService := service.NewPostService(repo)
postHandler := handler.NewPostHandler(l, &postService)

router.New(
	// ... handlers ...
	&postHandler,
)
```

---

## Step 7 – Unit tests

Write unit tests for the service using Go testing framework by mocking the repository layer or writing mock repository adapters. Run tests with:

```bash
go test ./internal/service/...
```