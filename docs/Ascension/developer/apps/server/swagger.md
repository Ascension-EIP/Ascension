---
id: ff864812-b4c3-4506-bb44-acefe8422a84
---

:::success
**Version:** 1.1
:::

---

# Swagger / OpenAPI

:::info
**Migration Status:** The Ascension backend was migrated from Rust to Go. OpenAPI / Swagger documentation will be integrated using **swaggo/swag** and **gin-swagger**. This document details the planned integration steps, annotations, and commands for the Go/Gin server.
:::

This document explains how to annotate routes and generate interactive API documentation (Swagger UI) for the Ascension Go backend.

---

## Target Swagger UI Endpoint

Once enabled in the Gin router, Swagger UI will be accessible at:

| Environment | URL |
| --- | --- |
| Local dev | [http://localhost:8080/swagger/index.html](http://localhost:8080/swagger/index.html) |
| Staging | `https://<staging-host>/swagger/index.html` |
| OpenAPI JSON | `http://localhost:8080/swagger/doc.json` |

---

## Route Groups (Tags)

| Tag | Base Path | Description |
| --- | --- | --- |
| **Auth** | `/v1/auth` | User registration, authentication, token refresh, and logout |
| **Users** | `/v1/users` | Administrative user CRUD management |
| **Videos** | `/v1/videos` | Presigned upload/download URLs and upload confirmation |
| **Analysis** | `/v1/analysis` | Triggering and polling asynchronous AI pose extraction jobs |
| **Health** | `/healthz` | Unauthenticated liveness probe |

---

## Go / Gin Implementation with Swag

The Go ecosystem uses [swaggo/swag](https://github.com/swaggo/swag) to parse declarative comments on handlers and structs, and [gin-swagger](https://github.com/swaggo/gin-swagger) to serve the UI.

### Step 1 – General API Annotations (`cmd/server/main.go`)

Add the root documentation annotations above the `main` package or function:

```go
// @title Ascension API
// @version 1.0
// @description High-level climbing coach AI backend API.
// @host localhost:8080
// @BasePath /v1

// @securityDefinitions.apikey Bearer
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.
```

---

### Step 2 – Annotate Handler Functions

Place declarative `@Summary`, `@Tags`, `@Param`, and `@Success`/`@Failure` annotations directly above each handler method in `internal/inbound/http/handler/`:

```go
// Create handles analysis creation
// @Summary Trigger a video analysis
// @Description Queues a new video for 2D/3D skeleton and hold analysis
// @Tags Analysis
// @Accept json
// @Produce json
// @Security Bearer
// @Param request body request.CreateAnalyseRequest true "Analysis parameters"
// @Success 202 {object} response.AnalysisResponse
// @Failure 400 {object} response.Error
// @Failure 401 {object} response.Error
// @Failure 404 {object} response.Error
// @Router /analysis [post]
func (h *AnalysisHandler) Create(c *gin.Context) {
    // ...
}
```

---

### Step 3 – Document Request & Response DTO Structs

All structs in `internal/inbound/http/dto/request/` and `dto/response/` should define explicit `json` and `binding` tags. Swag infers the OpenAPI schema directly from them:

```go
type CreateAnalyseRequest struct {
    VideoID    uuid.UUID `json:"video_id" binding:"required" example:"018e6e5a-1234-7abc-8def-0123456789ab"`
    Type       string    `json:"type" binding:"required" example:"2d" enums:"2d,3d"`
    Visibility string    `json:"visibility" binding:"required" example:"private" enums:"private,friends,public"`
}
```

---

### Step 4 – Generate Docs and Serve Swagger UI

1. Install `swag` CLI:

```bash
go install github.com/swaggo/swag/cmd/swag@latest
```

2. Generate documentation files (`docs/swagger/`):

```bash
swag init -g cmd/server/main.go -o ./docs/swagger
```

3. Mount the handler in `internal/inbound/http/router/router.go`:

```go
import (
    swaggerFiles "github.com/swaggo/files"
    ginSwagger "github.com/swaggo/gin-swagger"
    _ "github.com/Ascension-EIP/Ascension/apps/server/docs/swagger"
)

// Inside router.New:
app.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
```

4. Verify by navigating to `http://localhost:8080/swagger/index.html`.
