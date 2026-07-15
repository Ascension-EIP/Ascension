> **Last updated:** 12th March 2026  
> **Version:** 1.0  
> **Authors:** Nicolas  
> **Status:** Done  

---

# Swagger / OpenAPI

> [!NOTE]
> **Migration Status:** The Ascension backend was migrated from Rust to Go. The automatic OpenAPI documentation via `utoipa` is a feature of the legacy Rust backend and is currently **planned but not yet active** on the Go/Gin backend server. This document serves as a reference of the previous Rust implementation and the planned Go swagger documentation.

This document explains how to access the interactive API documentation (Swagger UI) for the Ascension backend, and how to keep the spec up-to-date when adding new routes.

---

## Table of Contents

- [Swagger / OpenAPI](#swagger--openapi)
  - [Table of Contents](#table-of-contents)
  - [Accessing Swagger UI](#accessing-swagger-ui)
  - [OpenAPI JSON endpoint](#openapi-json-endpoint)
  - [Route groups (tags)](#route-groups-tags)
  - [How it works](#how-it-works)
  - [Adding a new route to the spec](#adding-a-new-route-to-the-spec)
    - [1. Annotate request/response structs](#1-annotate-requestresponse-structs)
    - [2. Annotate the handler function](#2-annotate-the-handler-function)
    - [3. Register in `ApiDoc`](#3-register-in-apidoc)
    - [4. Verify](#4-verify)

---

## Accessing Swagger UI

| Environment | URL                                 |
|-------------|-------------------------------------|
| Local dev   | <http://localhost:3000/swagger-ui>  |
| Staging     | `https://<staging-host>/swagger-ui` |

Start the server normally (`cargo run` or `docker compose up server`) and open the URL above in your browser.

---

## OpenAPI JSON endpoint

The raw OpenAPI v3 JSON spec is served at:

```
GET /api-docs/openapi.json
```

You can import this URL directly into Postman, Insomnia, or any other tool that supports OpenAPI.

---

## Route groups (tags)

| Tag      | Base path      | Description             |
|----------|----------------|-------------------------|
| Auth     | `/v1/auth`     | Register, login, logout |
| Users    | `/v1/users`    | User CRUD               |
| Videos   | `/v1/videos`   | Pre-signed upload URL   |
| Analyses | `/v1/analyses` | AI pose-analysis jobs   |

---

## How it worked (Rust Legacy)

In the Rust codebase, we used [`utoipa`](https://docs.rs/utoipa) to generate the OpenAPI spec directly from Rust source annotations, mounting it in Axum:

```rust
#[derive(OpenApi)]
#[openapi(paths(...), components(schemas(...)), tags(...))]
pub struct ApiDoc;
```

## Planned Go Implementation

For the Go/Gin backend, Swagger UI will be integrated using **swaggo/swag**. Once implemented, routes will be documented using Go comments above handler functions:

```go
// @Summary Create a user
// @Description Creates a new user record
// @Tags Users
// @Accept json
// @Produce json
// @Param request body request.SignupLoginForm true "User signup details"
// @Success 201 {object} response.LoginResponse
// @Router /v1/auth/signup [post]
```

---

## Adding a new route to the spec

Follow these four steps every time you add a handler.

### 1. Annotate request/response structs

Derive `ToSchema` on every struct that appears in the request body or response body:

```rust
use utoipa::ToSchema;

#[derive(Deserialize, ToSchema)]
pub struct MyRequest {
    pub field: String,
}

#[derive(Serialize, ToSchema)]
pub struct MyResponse {
    pub id: uuid::Uuid,
}
```

### 2. Annotate the handler function

Place `#[utoipa::path]` directly above the handler:

```rust
#[utoipa::path(
    post,                              // HTTP method
    path = "/v1/my-resource",
    request_body = MyRequest,          // omit for GET
    responses(
        (status = 201, description = "Created", body = MyResponse),
        (status = 422, description = "Validation error"),
    ),
    tag = "MyTag"                      // matches a tag name in ApiDoc
)]
pub async fn my_handler(…) -> … { … }
```

For path parameters, use the `params` key:

```rust
#[utoipa::path(
    get,
    path = "/v1/my-resource/{id}",
    params(
        ("id" = Uuid, Path, description = "Resource UUID"),
    ),
    …
)]
```

### 3. Register in `ApiDoc`

Open `apps/server/src/inbound/http.rs` and add the handler and schemas to the `#[openapi(…)]` attribute:

```rust
#[openapi(
    paths(
        // … existing paths …
        handlers::my_module::my_handler::my_handler,   // ← add this
    ),
    components(schemas(
        // … existing schemas …
        MyRequest, MyResponse,                          // ← add these
    )),
)]
pub struct ApiDoc;
```

### 4. Verify

Run the server and open `/swagger-ui`. Your new endpoint should appear under the correct tag group. If it is missing, check that the module path in `paths(…)` matches the actual Rust module hierarchy.
