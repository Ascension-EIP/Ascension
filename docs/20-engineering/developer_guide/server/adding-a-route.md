> **Last updated:** 9th March 2026  
> **Version:** 1.1  
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
  - [Step 1 – Create the handler file](#step-1--create-the-handler-file)
  - [Step 2 – Write the handler function](#step-2--write-the-handler-function)
    - [Key points](#key-points)
  - [Step 3 – Register the handler as a module](#step-3--register-the-handler-as-a-module)
  - [Step 4 – Add the route to the router](#step-4--add-the-route-to-the-router)
    - [4a. Import your handler](#4a-import-your-handler)
    - [4b. Add the route](#4b-add-the-route)
  - [Testing your route](#testing-your-route)
  - [Route reference: HTTP methods in Axum](#route-reference-http-methods-in-axum)
    - [Path parameters](#path-parameters)
    - [Query parameters](#query-parameters)
    - [JSON request body](#json-request-body)

---

## Overview: what files are involved?

Adding a route always touches these files (at minimum):

| What               | Where                                                           |
|--------------------|-----------------------------------------------------------------|
| The handler logic  | `src/inbound/http/handlers/<your_file>.rs`                      |
| Module declaration | `src/inbound/http/handlers.rs` (or an existing sub-module file) |
| Route registration | `src/inbound/http.rs` inside `v1_routes()`                      |

If your route needs to call the domain (e.g., read/write users), you will also touch domain and outbound files — that is covered in the [CRUD guide](./implementing-a-crud.md).

---

## Step 1 – Create the handler file

Create a new `.rs` file inside `src/inbound/http/handlers/`.

For our example:

```
src/inbound/http/handlers/version.rs   ← new file
```

---

## Step 2 – Write the handler function

Open the newly created file and write your handler.

A handler is just an `async fn` that returns something Axum can convert to an HTTP response.

```rust
// src/inbound/http/handlers/version.rs

use axum::Json;
use serde::Serialize;

/// The JSON body returned by GET /v1/status/version
#[derive(Serialize)]
pub struct VersionResponse {
    pub version: String,
}

/// Handler for GET /v1/status/version
pub async fn get_version() -> Json<VersionResponse> {
    Json(VersionResponse {
        version: "1.0.0".to_string(),
    })
}
```

### Key points

- The function must be `async`.
- The return type must implement `IntoResponse`. `Json<T>` already does this as long as `T: Serialize`.
- If you want to return a specific HTTP status code alongside JSON, use `ApiSuccess<T>` (see the existing `create_user.rs` as a model).
- If you need access to the shared application state (e.g., to call a service), add `State(state): State<AppState>` as the first parameter. See [Step 4](#step-4--add-the-route-to-the-router) for more details.

---

## Step 3 – Register the handler as a module

Rust requires you to explicitly declare every module. Open `src/inbound/http/handlers.rs` and add a `pub mod` line for your new file:

```rust
// src/inbound/http/handlers.rs

pub mod status;
pub mod api;
pub mod user;
pub mod version;   // ← add this line
```

Now the rest of the codebase can import things from `version.rs` using:
```rust
use crate::inbound::http::handlers::version::get_version;
```

---

## Step 4 – Add the route to the router

Open `src/inbound/http.rs`. There are two things to do here:

### 4a. Import your handler

At the top of the file, add:

```rust
use crate::inbound::http::handlers::version::get_version;
```

### 4b. Add the route

Find the `v1_routes` function at the bottom of the file and add a new nested router, or extend an existing one:

```rust
fn v1_routes() -> Router<AppState> {
    Router::new()
        .nest("/users", v1_users_routes())
        .nest("/status", v1_status_routes())  // ← add a new sub-router
}

fn v1_status_routes() -> Router<AppState> {
    Router::new()
        .route("/version", get(get_version))  // ← add this line
}
```

The full URL will be `/v1/status/version` because all routes in `v1_routes()` are nested under `/v1` (see where `.nest("/v1", v1_routes())` is called in `HttpServer::new`).

> **Note:** If your handler is simple and does not belong to any sub-group, you can add it directly in
> `v1_routes()` without creating an extra function:
>
> ```rust
> fn v1_routes() -> Router<AppState> {
>     Router::new()
>         .nest("/users", v1_users_routes())
>         .route("/status/version", get(get_version))  // ← inline route
> }
> ```

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

## Route reference: HTTP methods in Axum

Axum provides one function per HTTP method. Import them from `axum::routing`:

```rust
use axum::routing::{get, post, put, patch, delete};
```

| Axum function     | HTTP method | Typical use                 |
|-------------------|-------------|-----------------------------|
| `get(handler)`    | `GET`       | Read / list a resource      |
| `post(handler)`   | `POST`      | Create a new resource       |
| `put(handler)`    | `PUT`       | Replace a resource entirely |
| `patch(handler)`  | `PATCH`     | Partially update a resource |
| `delete(handler)` | `DELETE`    | Delete a resource           |

### Path parameters

Use `{name}` in the route path to capture a segment as a variable:

```rust
.route("/users/{id}", get(get_user))
```

In the handler, extract it with `axum::extract::Path`:

```rust
use axum::extract::Path;
use uuid::Uuid;

pub async fn get_user(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,           // Axum will parse the "{id}" segment into a Uuid
) -> Result<ApiSuccess<...>, ApiError> {
    // ...
}
```

### Query parameters

Use `axum::extract::Query` to extract `?key=value` parameters:

```rust
use axum::extract::Query;
use serde::Deserialize;

#[derive(Deserialize)]
pub struct PaginationParams {
    pub page: Option<usize>,
    pub per_page: Option<usize>,
}

pub async fn list_users(
    State(state): State<AppState>,
    Query(params): Query<PaginationParams>,
) -> Result<ApiSuccess<...>, ApiError> {
    let page = params.page.unwrap_or(1);
    // ...
}
```

### JSON request body

Use `axum::extract::Json` to parse an incoming JSON body:

```rust
use axum::Json;
use serde::Deserialize;

#[derive(Deserialize)]
pub struct MyRequestBody {
    pub name: String,
}

pub async fn my_handler(
    Json(body): Json<MyRequestBody>,
) -> ... {
    // body.name is available here
}
```

> **Important:** The `Json` extractor must be the **last** parameter in the function signature.
> Axum processes extractors in order, and body extraction consumes the request body.
