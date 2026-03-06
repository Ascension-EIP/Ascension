# How to Implement a CRUD

This guide explains how to add full **Create / Read / Update / Delete** operations for a new resource,
following the hexagonal architecture used by the Ascension server.

We will use the existing **User** resource as the reference implementation.
Because `create_user` is the most complete example, every section uses it as the primary reference.

> Before reading this guide, make sure you have read:
> - [Architecture overview](./architecture.md)
> - [How to add a route](./adding-a-route.md)

---

## Table of Contents

1. [Big picture: what you will create](#big-picture-what-you-will-create)
2. [Step 1 – SQL migration](#step-1--sql-migration)
3. [Step 2 – Domain models](#step-2--domain-models)
   - [The entity struct](#the-entity-struct)
   - [Value types and validation](#value-types-and-validation)
   - [Input / Output / Error types for each operation](#input--output--error-types-for-each-operation)
4. [Step 3 – Ports (traits)](#step-3--ports-traits)
   - [The Service trait](#the-service-trait)
   - [The Repository trait](#the-repository-trait)
   - [Repository data structs](#repository-data-structs)
5. [Step 4 – Domain service](#step-4--domain-service)
6. [Step 5 – Outbound adapter (PostgreSQL)](#step-5--outbound-adapter-postgresql)
7. [Step 6 – Inbound handlers (HTTP)](#step-6--inbound-handlers-http)
   - [The create handler (full example)](#the-create-handler-full-example)
8. [Step 7 – Register routes](#step-7--register-routes)
9. [Step 8 – Wire everything in `main.rs`](#step-8--wire-everything-in-mainrs)
10. [Step 9 – Unit tests](#step-9--unit-tests)
    - [Model tests](#model-tests)
    - [Service tests](#service-tests)
11. [Checklist summary](#checklist-summary)

---

## Big picture: what you will create

For a resource called `Post`, you will create the following files:

```
src/
├── domain/
│   └── post/
│       ├── models/
│       │   └── post.rs       ← structs, value types, Input/Output/Error
│       ├── ports.rs           ← PostService trait + PostRepository trait
│       └── service.rs         ← Service<R> that implements PostService
├── outbound/
│   └── postgresql.rs          ← (extended) Postgres implements PostRepository
└── inbound/
    └── http/
        └── handlers/
            └── post/
                ├── create_post.rs
                ├── list_posts.rs
                ├── get_post.rs
                ├── update_post.rs
                └── delete_post.rs
```

Plus the module declaration files (`post.rs`, `handlers/post.rs`) and changes to `http.rs` for routing.

---

## Step 1 – SQL migration

Create a new file in `migrations/` named with the current timestamp and a descriptive name:

```
migrations/20260305000000_create_posts_table.sql
```

Write your `CREATE TABLE` statement:

```sql
CREATE TABLE posts (
    id          TEXT        PRIMARY KEY,
    title       TEXT        NOT NULL,
    content     TEXT        NOT NULL,
    author_id   TEXT        NOT NULL REFERENCES users(id),
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at on every UPDATE
CREATE TRIGGER update_posts_updated_at
BEFORE UPDATE ON posts
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();  -- this function already exists from the users migration
```

> The `set_updated_at` trigger function was created in the users migration, so you can reuse it directly.

---

## Step 2 – Domain models

### The entity struct

Create `src/domain/post/models/post.rs`.

The entity is a plain Rust struct. It holds the data as validated value types (not raw `String`s):

```rust
// src/domain/post/models/post.rs

use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Post {
    pub id: Uuid,
    pub title: PostTitle,
    pub content: PostContent,
    pub author_id: Uuid,
}

impl Post {
    pub fn new(id: Uuid, title: PostTitle, content: PostContent, author_id: Uuid) -> Self {
        Self { id, title, content, author_id }
    }
}
```

### Value types and validation

Instead of storing a raw `String` for `title`, we create a `PostTitle` newtype.
This means validation runs **once, at the edge**, and the rest of the code can trust the value is valid.

```rust
use thiserror::Error;

// A validated title wrapper
#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct PostTitle(String);

#[derive(Clone, Debug, Error)]
#[error("'{title}' is not a valid post title")]
pub struct PostTitleInvalidError {
    pub title: String,
}

impl PostTitle {
    pub fn new(raw: &str) -> Result<Self, PostTitleInvalidError> {
        let trimmed = raw.trim();
        if trimmed.is_empty() || trimmed.len() > 200 {
            Err(PostTitleInvalidError { title: trimmed.to_string() })
        } else {
            Ok(Self(trimmed.to_string()))
        }
    }
}

impl std::fmt::Display for PostTitle {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}
```

> **Tip:** look at how `Username`, `EmailAddress`, and `Password` are implemented in
> `src/domain/user/models/user.rs` — they follow the exact same pattern.

### Input / Output / Error types for each operation

For **each CRUD operation**, define three types in the same file:

- `XxxInput` — what the service receives from the handler
- `XxxOutput` — what the service returns to the handler on success
- `XxxError` — what can go wrong

#### Create

```rust
use crate::domain::post::ports::PostRepositoryError;
use derive_more::From;

// --- CreatePost ---

#[derive(Clone, Debug, From)]
pub struct CreatePostInput {
    pub title: PostTitle,
    pub content: PostContent,
    pub author_id: Uuid,
}

pub struct CreatePostOutput {
    pub id: Uuid,
}

impl CreatePostOutput {
    pub fn new(id: Uuid) -> Self { Self { id } }
}

#[derive(Debug, Error)]
pub enum CreatePostError {
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}

// Map from repository errors to service errors
impl From<PostRepositoryError> for CreatePostError {
    fn from(err: PostRepositoryError) -> Self {
        match err {
            PostRepositoryError::Unknown(cause) => Self::Unknown(cause),
            _ => Self::Unknown(anyhow::Error::from(err)),
        }
    }
}
```

Repeat this pattern for `GetPost`, `ListPosts`, `UpdatePost`, and `DeletePost`, adding specific variants
(e.g., `CreatePostError::NotFound`) when the operation can fail for a known reason.

---

## Step 3 – Ports (traits)

Create `src/domain/post/ports.rs`.

### The Service trait

The service trait defines what the HTTP layer is allowed to call.
Every method is async and returns a `Result`.

```rust
// src/domain/post/ports.rs

use std::future::Future;
use thiserror::Error;
use uuid::Uuid;

use crate::domain::post::models::post::{
    CreatePostError, CreatePostInput, CreatePostOutput,
    // ... import all Input/Output/Error types
};

/// Public API of the Post domain. The HTTP layer depends on this trait.
pub trait PostService: Clone + Send + Sync + 'static {
    fn create_post(
        &self,
        req: &CreatePostInput,
    ) -> impl Future<Output = Result<CreatePostOutput, CreatePostError>> + Send;

    // fn list_posts(...)
    // fn get_post(...)
    // fn update_post(...)
    // fn delete_post(...)
}
```

### The Repository trait

The repository trait defines what the domain is allowed to ask of the database.

```rust
/// Contract that the database adapter must implement.
pub trait PostRepository: Clone + Send + Sync + 'static {
    fn create_post(
        &self,
        req: &CreatePostData,
    ) -> impl Future<Output = Result<Post, PostRepositoryError>> + Send;

    // fn list_posts(...)
    // fn get_post(...)
    // fn update_post(...)
    // fn delete_post(...)
}
```

### Repository data structs

These are the structs the service uses to pass data to the repository.
They live in `ports.rs` next to the traits.

```rust
// Data passed from the service to the repository
pub struct CreatePostData {
    pub title: PostTitle,
    pub content: PostContent,
    pub author_id: Uuid,
}

// Repository-level errors (database layer errors)
#[derive(Debug, Error)]
pub enum PostRepositoryError {
    #[error("post with id {id} not found")]
    NotFoundId { id: Uuid },
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}
```

> **Why two separate data structs (`CreatePostInput` and `CreatePostData`)?**
>
> `CreatePostInput` lives in the domain and is what the *service* accepts from the handler.
> `CreatePostData` is what the *service* passes down to the *repository*.
> They look similar but keeping them separate means the domain service can transform the data
> (e.g., hash a password) before hitting the database, without the handler knowing about it.

---

## Step 4 – Domain service

Create `src/domain/post/service.rs`.

The service is a generic struct `Service<R>` where `R` must implement `PostRepository`.
It simply translates between the service's Input types and the repository's Data types.

```rust
// src/domain/post/service.rs

use crate::domain::post::models::post::{CreatePostError, CreatePostInput, CreatePostOutput};
use crate::domain::post::ports::{CreatePostData, PostRepository, PostService};

#[derive(Debug, Clone)]
pub struct Service<R: PostRepository> {
    repo: R,
}

impl<R: PostRepository> Service<R> {
    pub fn new(repo: R) -> Self {
        Self { repo }
    }
}

impl<R: PostRepository> PostService for Service<R> {
    async fn create_post(
        &self,
        input: &CreatePostInput,
    ) -> Result<CreatePostOutput, CreatePostError> {
        // 1. Build the repository data struct from the input
        let data = CreatePostData {
            title: input.title.clone(),
            content: input.content.clone(),
            author_id: input.author_id,
        };

        // 2. Call the repository
        let post = self.repo.create_post(&data).await?;

        // 3. Map the result to the output type
        Ok(CreatePostOutput::new(post.id))
    }
}
```

> The `?` operator at the end of `.await?` automatically converts `PostRepositoryError`
> into `CreatePostError` because we implemented `From<PostRepositoryError> for CreatePostError`
> in the models file.

---

## Step 5 – Outbound adapter (PostgreSQL)

Open `src/outbound/postgresql.rs` and implement `PostRepository` for the existing `Postgres` struct.

```rust
// src/outbound/postgresql.rs  (add to the existing impl block)

use crate::domain::post::models::post::Post;
use crate::domain::post::ports::{CreatePostData, PostRepository, PostRepositoryError};

impl PostRepository for Postgres {
    async fn create_post(&self, req: &CreatePostData) -> Result<Post, PostRepositoryError> {
        // Open a transaction for safety
        let mut tx = self
            .pool
            .begin()
            .await
            .context("failed to start Postgres transaction")?;

        let id = Uuid::new_v4();

        // Execute the INSERT query
        // sqlx::query! checks the SQL at compile time if DATABASE_URL is set
        sqlx::query!(
            "INSERT INTO posts (id, title, content, author_id) VALUES ($1, $2, $3, $4)",
            id.to_string(),
            req.title.to_string(),
            req.content.to_string(),
            req.author_id.to_string(),
        )
        .execute(&mut *tx)
        .await
        .map_err(|e| anyhow::anyhow!(e).context("failed to insert post"))?;

        tx.commit()
            .await
            .context("failed to commit transaction")?;

        Ok(Post::new(id, req.title.clone(), req.content.clone(), req.author_id))
    }
}
```

### Handling unique constraint violations

If inserting a row violates a `UNIQUE` constraint in the database, SQLx returns a specific error.
Use the helper already in the file to detect it:

```rust
.map_err(|e| {
    if is_unique_constraint_violation(&e) {
        PostRepositoryError::DuplicateTitle { title: req.title.clone() }
    } else {
        anyhow::anyhow!(e).context("failed to insert post").into()
    }
})?;
```

### Handling "not found"

When doing a `SELECT` and no row matches, SQLx returns `sqlx::Error::RowNotFound`:

```rust
.map_err(|e| {
    if matches!(e, sqlx::Error::RowNotFound) {
        PostRepositoryError::NotFoundId { id }
    } else {
        anyhow::anyhow!(e).context(format!("failed to fetch post {}", id)).into()
    }
})?;
```

---

## Step 6 – Inbound handlers (HTTP)

Create `src/inbound/http/handlers/post/create_post.rs`.

### The create handler (full example)

This is the most complete example to follow. It mirrors `create_user.rs` exactly.

```rust
// src/inbound/http/handlers/post/create_post.rs

use axum::Json;
use axum::extract::State;
use axum::http::StatusCode;
use serde::{Deserialize, Serialize};
use thiserror::Error;

use crate::domain::post::models::post::{
    CreatePostError, CreatePostInput, CreatePostOutput,
    PostTitle, PostTitleInvalidError,
    PostContent, PostContentInvalidError,
};
use crate::domain::post::ports::PostService;
use crate::inbound::http::AppState;
use crate::inbound::http::handlers::api::{ApiError, ApiSuccess};

// ── 1. Map domain errors to HTTP errors ──────────────────────────────────────

impl From<CreatePostError> for ApiError {
    fn from(e: CreatePostError) -> Self {
        match e {
            CreatePostError::Unknown(_) => {
                Self::InternalServerError("Internal server error".to_string())
            }
        }
    }
}

// ── 2. Map parse/validation errors to HTTP errors ────────────────────────────

#[derive(Debug, Clone, Error)]
enum ParseCreatePostHttpRequestError {
    #[error(transparent)]
    Title(#[from] PostTitleInvalidError),
    #[error(transparent)]
    Content(#[from] PostContentInvalidError),
}

impl From<ParseCreatePostHttpRequestError> for ApiError {
    fn from(e: ParseCreatePostHttpRequestError) -> Self {
        let message = match e {
            ParseCreatePostHttpRequestError::Title(cause) => {
                format!("title '{}' is invalid", cause.title)
            }
            ParseCreatePostHttpRequestError::Content(_) => {
                "content is invalid".to_string()
            }
        };
        Self::UnprocessableEntity(message)
    }
}

// ── 3. HTTP request body ──────────────────────────────────────────────────────

/// JSON body expected for POST /api/posts
#[derive(Debug, Clone, Deserialize)]
pub struct CreatePostHttpRequestBody {
    title: String,
    content: String,
    author_id: String,
}

impl CreatePostHttpRequestBody {
    /// Parse & validate the raw strings into domain types.
    fn try_into_domain(self) -> Result<CreatePostInput, ParseCreatePostHttpRequestError> {
        let title   = PostTitle::new(&self.title)?;
        let content = PostContent::new(&self.content)?;
        let author_id = uuid::Uuid::parse_str(&self.author_id)
            .map_err(|_| /* handle uuid parse error */)?;
        Ok(CreatePostInput::new(title, content, author_id))
    }
}

// ── 4. HTTP response body ─────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize)]
pub struct CreatePostResponse {
    id: String,
}

impl From<&CreatePostOutput> for CreatePostResponse {
    fn from(output: &CreatePostOutput) -> Self {
        Self { id: output.id.to_string() }
    }
}

// ── 5. The handler function ───────────────────────────────────────────────────

pub async fn create_post<PS: PostService>(
    State(state): State<AppState<PS>>,
    Json(body): Json<CreatePostHttpRequestBody>,
) -> Result<ApiSuccess<CreatePostResponse>, ApiError> {
    let domain_req = body.try_into_domain()?;
    state
        .user_service           // ← rename this field in AppState when you add PostService
        .create_post(&domain_req)
        .await
        .map_err(ApiError::from)
        .map(|ref output| ApiSuccess::new(StatusCode::CREATED, output.into()))
}
```

> **Important note about `AppState`:**
> Currently `AppState` only holds a `user_service`. When you add a new resource that has its own service,
> you will need to add a new field to `AppState` in `src/inbound/http.rs`:
>
> ```rust
> #[derive(Debug, Clone)]
> struct AppState<US: UserService, PS: PostService> {
>     user_service: Arc<US>,
>     post_service: Arc<PS>,   // ← add this
> }
> ```
>
> This will require updating all generic bounds throughout `http.rs` to include `PS: PostService`.

---

## Step 7 – Register routes

Open `src/inbound/http/handlers/post.rs` (create it) and declare the sub-modules:

```rust
// src/inbound/http/handlers/post.rs
pub mod create_post;
pub mod list_posts;
pub mod get_post;
pub mod update_post;
pub mod delete_post;
```

Then open `src/inbound/http/handlers.rs` and add:

```rust
// src/inbound/http/handlers.rs
pub mod status;
pub mod api;
pub mod user;
pub mod post;   // ← add this
```

Finally, open `src/inbound/http.rs`, import your handlers, and add routes:

```rust
// imports at the top
use crate::inbound::http::handlers::post::create_post::create_post;
// ... other post handlers

// inside api_routes()
fn api_routes<US: UserService, PS: PostService>() -> Router<AppState<US, PS>> {
    Router::new()
        // existing user routes
        .route("/users",        post(create_user::<US, PS>))
        // ...
        // new post routes
        .route("/posts",        post(create_post::<US, PS>))
        .route("/posts",        get(list_posts::<US, PS>))
        .route("/posts/:id",    get(get_post::<US, PS>))
        .route("/posts/:id",    put(update_post::<US, PS>))
        .route("/posts/:id",    delete(delete_post::<US, PS>))
}
```

---

## Step 8 – Wire everything in `main.rs`

Open `src/main.rs` and create the new service, passing it to the HTTP server:

```rust
// src/main.rs

use crate::domain::post::service::Service as PostService;

// ...

let post_service = PostService::new(db.clone());

let http_server = HttpServer::new(user_service, post_service, server_config).await?;
```

Update `HttpServer::new` signature accordingly to accept the new service.

---

## Step 9 – Unit tests

Unit tests for the server live in `src/tests/` and are compiled only in test mode (`#[cfg(test)]`).
They do **not** require a running database — a lightweight mock repository is used instead.

Create two files:

```
src/tests/domain/<resource>/model_tests.rs
src/tests/domain/<resource>/service_tests.rs
```

And declare them in the module hierarchy:

```rust
// src/tests/domain/<resource>/mod.rs
pub mod model_tests;
pub mod service_tests;
```

```rust
// src/tests/domain/mod.rs  (add the new resource)
pub mod user;
pub mod <resource>;   // ← add this
```

### Model tests

Test every value type constructor with valid and invalid inputs.
Focus on boundary conditions (minimum/maximum length, forbidden characters, etc.).

```rust
// src/tests/domain/post/model_tests.rs

#[cfg(test)]
mod tests {
    use crate::domain::post::models::post::PostTitle;

    #[test]
    fn post_title_valid() {
        assert!(PostTitle::new("Hello World").is_ok());
    }

    #[test]
    fn post_title_empty_is_invalid() {
        assert!(PostTitle::new("").is_err());
    }

    #[test]
    fn post_title_too_long_is_invalid() {
        assert!(PostTitle::new(&"a".repeat(201)).is_err());
    }
}
```

### Service tests

Test every operation of the service (`create`, `list`, `get`, `update`, `delete`).
For each operation, test at minimum:

- **Success path** — the service returns the expected output.
- **Known error** — e.g. `NotFound`, `DuplicateEmail` are correctly mapped.
- **Unknown error** — a generic repository failure is propagated as `Unknown`.

Because the output types (e.g. `CreatePostOutput`) do not implement `Clone`,
stored results must be wrapped in `Arc<Mutex<Option<...>>>`:

```rust
// src/tests/domain/post/service_tests.rs

#[cfg(test)]
mod tests {
    use std::future::Future;
    use std::sync::{Arc, Mutex};
    use uuid::Uuid;

    use crate::domain::post::models::post::{CreatePostInput, CreatePostOutput, PostTitle, PostContent};
    use crate::domain::post::ports::{CreatePostData, PostRepository, PostRepositoryError};
    use crate::domain::post::service::Service;
    use crate::domain::post::ports::PostService;

    type ArcResult<T> = Arc<Mutex<Option<Result<T, PostRepositoryError>>>>;

    fn arc<T>(v: Result<T, PostRepositoryError>) -> ArcResult<T> {
        Arc::new(Mutex::new(Some(v)))
    }

    #[derive(Clone)]
    struct MockPostRepository {
        create_result: Option<ArcResult<CreatePostOutput>>,
    }

    impl MockPostRepository {
        fn new() -> Self { Self { create_result: None } }

        fn with_create(mut self, r: Result<CreatePostOutput, PostRepositoryError>) -> Self {
            self.create_result = Some(arc(r));
            self
        }
    }

    impl PostRepository for MockPostRepository {
        fn create_post(
            &self,
            _req: &CreatePostData,
        ) -> impl Future<Output = Result<CreatePostOutput, PostRepositoryError>> + Send {
            let result = self
                .create_result.as_ref().unwrap()
                .lock().unwrap().take().unwrap();
            async move { result }
        }
    }

    #[tokio::test]
    async fn create_post_returns_id_on_success() {
        let id = Uuid::new_v4();
        let repo = MockPostRepository::new().with_create(Ok(CreatePostOutput::new(id)));
        let service = Service::new(repo);

        let input = CreatePostInput::new(
            PostTitle::new("Hello").unwrap(),
            PostContent::new("World").unwrap(),
            Uuid::new_v4(),
        );
        let result = service.create_post(&input).await;

        assert!(result.is_ok());
        assert_eq!(result.unwrap().id, id);
    }

    #[tokio::test]
    async fn create_post_propagates_unknown_error() {
        let repo = MockPostRepository::new()
            .with_create(Err(PostRepositoryError::Unknown(anyhow::anyhow!("db down"))));
        let service = Service::new(repo);

        let input = CreatePostInput::new(
            PostTitle::new("Hello").unwrap(),
            PostContent::new("World").unwrap(),
            Uuid::new_v4(),
        );
        let result = service.create_post(&input).await;

        assert!(result.is_err());
    }
}
```

### Running the tests

The `SQLX_OFFLINE=true` flag is required because `sqlx::query!` macros verify queries against
the database at compile time; the flag uses the cached metadata in `.sqlx/` instead.

```sh
SQLX_OFFLINE=true cargo test
```

To run only the tests for a specific resource:

```sh
SQLX_OFFLINE=true cargo test domain::post
```

---

## Checklist summary

Use this checklist every time you add a new CRUD resource:

### Domain layer
- [ ] `src/domain/<resource>/models/<resource>.rs` — entity struct + value types + Input/Output/Error for each operation
- [ ] `src/domain/<resource>/ports.rs` — `<Resource>Service` trait + `<Resource>Repository` trait + `<Resource>Data` structs + `<Resource>RepositoryError`
- [ ] `src/domain/<resource>/service.rs` — `Service<R>` that implements `<Resource>Service`
- [ ] `src/domain/<resource>.rs` — `pub mod models; pub mod ports; pub mod service;`
- [ ] `src/domain.rs` — add `pub mod <resource>;`

### Outbound layer
- [ ] `src/outbound/postgresql.rs` — `impl <Resource>Repository for Postgres`
- [ ] SQL migration in `migrations/`
- [ ] Add query metadata to `.sqlx/` (run `cargo sqlx prepare` with a live database)

### Tests
- [ ] `src/tests/domain/<resource>/model_tests.rs` — value type validation tests
- [ ] `src/tests/domain/<resource>/service_tests.rs` — service CRUD tests with mock repository
- [ ] `src/tests/domain/<resource>/mod.rs` — declare the two test modules
- [ ] `src/tests/domain/mod.rs` — add `pub mod <resource>;`

### Inbound layer
- [ ] `src/inbound/http/handlers/<resource>/create_<resource>.rs`
- [ ] `src/inbound/http/handlers/<resource>/list_<resource>s.rs`
- [ ] `src/inbound/http/handlers/<resource>/get_<resource>.rs`
- [ ] `src/inbound/http/handlers/<resource>/update_<resource>.rs`
- [ ] `src/inbound/http/handlers/<resource>/delete_<resource>.rs`
- [ ] `src/inbound/http/handlers/<resource>.rs` — declare the five modules above
- [ ] `src/inbound/http/handlers.rs` — add `pub mod <resource>;`
- [ ] `src/inbound/http.rs` — import handlers + add routes in `api_routes()` + extend `AppState` if needed
- [ ] `src/main.rs` — instantiate the new service + pass it to `HttpServer::new`
