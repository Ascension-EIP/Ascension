> **Last updated:** 12th March 2026  
> **Version:** 1.0  
> **Authors:** Nicolas  
> **Status:** Done  

---

# Swagger / OpenAPI

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

## How it works

The project uses [`utoipa`](https://docs.rs/utoipa) to generate the OpenAPI spec directly from the Rust source code — no separate YAML/JSON file to maintain.

Two crates are involved:

| Crate               | Role                                                                                       |
|---------------------|--------------------------------------------------------------------------------------------|
| `utoipa`            | Derives OpenAPI schemas (`ToSchema`) and path metadata (`#[utoipa::path]`) from Rust types |
| `utoipa-swagger-ui` | Serves the Swagger UI React app at `/swagger-ui`                                           |

The central API struct lives in `apps/server/src/inbound/http.rs`:

```rust
#[derive(OpenApi)]
#[openapi(paths(...), components(schemas(...)), tags(...))]
pub struct ApiDoc;
```

It is mounted into the Axum router alongside the rest of the app:

```rust
Router::new()
    .merge(SwaggerUi::new("/swagger-ui").url("/api-docs/openapi.json", ApiDoc::openapi()))
    // … the rest of the routes
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
