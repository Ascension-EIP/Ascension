> **Last updated:** 15th July 2026  
> **Version:** 2.0  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# How to Add a Route

This guide walks you through adding a new HTTP route to the server from scratch.
It assumes you have read the [architecture overview](./architecture.md) first.

We will use a concrete example: adding a `GET /v1/status/version` endpoint that returns the current API version.

---

## Table of Contents

- [How to Add a Route](#how-to-add-a-route)
  - [Table of Contents](#table-of-contents)
  - [Overview: what files are involved?](#overview-what-files-are-involved)
  - [Step 1 – Create the handler struct and method](#step-1--create-the-handler-struct-and-method)
  - [Step 2 – Register the handler and route in the Router](#step-2--register-the-handler-and-route-in-the-router)
  - [Testing your route](#testing-your-route)
  - [Route reference: HTTP methods in Gin](#route-reference-http-methods-in-gin)
    - [Path parameters](#path-parameters)
    - [Query parameters](#query-parameters)
    - [JSON request body](#json-request-body)

---

## Overview: what files are involved?

Adding a route always touches these files (at minimum):

| What               | Where                                                           |
|--------------------|-----------------------------------------------------------------|
| The handler logic  | `internal/inbound/http/handler/<your_file>.go`                  |
| Route registration | `internal/inbound/http/router/router.go`                        |

---

## Step 1 – Create the handler struct and method

Create a new Go file under `internal/inbound/http/handler/` or add a method to an existing handler.

For our version check example, we can create `internal/inbound/http/handler/status.go`:

```go
package handler

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

type StatusHandler struct{}

func NewStatusHandler() StatusHandler {
	return StatusHandler{}
}

type VersionResponse struct {
	Version string `json:"version"`
}

// GetVersion handles GET /v1/status/version
func (h *StatusHandler) GetVersion(c *gin.Context) {
	c.JSON(http.StatusOK, VersionResponse{
		Version: "1.0.0",
	})
}
```

---

## Step 2 – Register the handler and route in the Router

Open `internal/inbound/http/router/router.go`. 

1. Add your handler as a parameter to the `New` function:

```go
func New(
	app *gin.Engine,
	cfg *config.Config,
	l *zerolog.Logger,
	// ... middlewares ...
	userH *handler.UserHandler,
	statusH *handler.StatusHandler, // ← Add this handler
)
```

2. Register the route under the `/v1` group:

```go
	v1 := app.Group("/v1")
	{
		statusGroup := v1.Group("/status")
		{
			statusGroup.GET("/version", statusH.GetVersion) // ← Add this line
		}
	}
```

Make sure the main wiring in `internal/app/app.go` instantiates your handler and passes it to the `router.New` function.

---

## Testing your route

Start the server, then use `curl` or any HTTP client:

```bash
curl http://localhost:8080/v1/status/version
```

Expected response:

```json
{
  "version": "1.0.0"
}
```

---

## Route reference: HTTP methods in Gin

Gin router groups expose methods matching HTTP verbs:

| Gin method | HTTP method | Typical use |
|---|---|---|
| `group.GET(path, handler)` | `GET` | Read / list a resource |
| `group.POST(path, handler)` | `POST` | Create a new resource |
| `group.PUT(path, handler)` | `PUT` | Replace a resource entirely |
| `group.PATCH(path, handler)` | `PATCH` | Partially update a resource |
| `group.DELETE(path, handler)` | `DELETE` | Delete a resource |

### Path parameters

Use `:param` in the route path to capture a segment as a variable:

```go
usersGroup.GET("/:id", userH.GetByID)
```

In the handler, extract it with `c.Param("id")`:

```go
idStr := c.Param("id")
```

### Query parameters

Use `c.Query("name")` to extract `?key=value` parameters:

```go
// GET /v1/videos/upload-url?content_type=video/mp4
contentType := c.Query("content_type")
```

### JSON request body

Use `c.ShouldBindJSON(&struct)` to bind and validate an incoming JSON body:

```go
type CreateAnalyseRequest struct {
	VideoID uuid.UUID `json:"video_id" binding:"required"`
}

func (h *AnalyseHandler) Create(c *gin.Context) {
	var req CreateAnalyseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}
	// req.VideoID is now available
}
```
