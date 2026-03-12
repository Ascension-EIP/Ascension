> **Last updated:** 12th March 2026  
> **Version:** 1.1  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Server API Routes Reference

This document lists every HTTP route exposed by the Ascension backend server,
with request/response examples and notes on authentication requirements.
No prior Rust knowledge is needed to use this reference.

---

## Table of Contents

- [Server API Routes Reference](#server-api-routes-reference)
  - [Table of Contents](#table-of-contents)
  - [Base URL](#base-url)
  - [Response Format](#response-format)
  - [Authentication](#authentication)
  - [Rate Limiting](#rate-limiting)
  - [Auth](#auth)
    - [POST /v1/auth/register — Register a new account](#post-v1authregister--register-a-new-account)
    - [POST /v1/auth/login — Log in](#post-v1authlogin--log-in)
    - [POST /v1/auth/logout — Log out](#post-v1authlogout--log-out)
  - [Users](#users)
    - [POST /v1/users — Create a user](#post-v1users--create-a-user)
    - [GET /v1/users — List all users](#get-v1users--list-all-users)
    - [GET /v1/users/{id} — Get a user](#get-v1usersid--get-a-user)
    - [PUT /v1/users/{id} — Update a user](#put-v1usersid--update-a-user)
    - [DELETE /v1/users/{id} — Delete a user](#delete-v1usersid--delete-a-user)
  - [Videos](#videos)
    - [POST /v1/videos/upload-url — Get a presigned upload URL](#post-v1videosupload-url--get-a-presigned-upload-url)
  - [Analyses](#analyses)
    - [POST /v1/analyses — Trigger an analysis](#post-v1analyses--trigger-an-analysis)
    - [GET /v1/analyses/{id} — Get an analysis](#get-v1analysesid--get-an-analysis)
  - [Health](#health)
    - [GET /healthz — Health check](#get-healthz--health-check)
  - [Error Codes Reference](#error-codes-reference)

---

## Base URL

| Environment               | URL                                  |
|---------------------------|--------------------------------------|
| Local development         | `http://localhost:8080`              |
| Docker (Android emulator) | `http://10.0.2.2:8080`               |
| Production                | Configured via `SERVER_PORT` env var |

All routes are prefixed with `/v1` except `/healthz`.

---

## Response Format

Successful responses return the data directly as a JSON object (no wrapper envelope
for most routes). Errors return a plain text message with the relevant HTTP status code.

Some routes use the `ApiSuccess<T>` envelope:

```json
{ "field_1": "...", "field_2": "..." }
```

Error responses are plain strings, e.g.:

```
"email already exists"
```

---

## Authentication

> **Authentication is partially implemented.** JWT middleware exists for `/healthz`
> but is not yet applied to the `/v1/*` routes. All `/v1/*` routes are currently
> accessible without a token.

When authentication is enabled, the expected header is:

```
Authorization: Bearer <jwt_token>
```

Two middleware functions exist in `src/inbound/http/middleware/auth.rs`:

| Middleware | What it does                                                                             |
|------------|------------------------------------------------------------------------------------------|
| `auth`     | Validates the `Authorization: Bearer` header; injects the `User` into request extensions |
| `admin`    | Requires `auth` to have run first; rejects non-admin users with `403 Forbidden`          |

---

## Rate Limiting

A global rate limiter is applied to **all routes**:

- **Limit:** 10 requests per second per IP address.
- **Excess requests:** receive `429 Too Many Requests`.
- The limiter state is cleaned up every 60 seconds.

---

## Auth

All auth endpoints live under `/v1/auth`. They do **not** require an `Authorization` header —
they are the entry points that produce tokens.

On successful login or registration, the server:

1. Returns a JSON body with `access_token` and `user_id`.
2. Sets an **`HttpOnly; SameSite=Strict`** session cookie named `session_token` so browsers carry the token automatically.

### POST /v1/auth/register — Register a new account

Creates a new user account with the `user` role, hashes the password with bcrypt,
and returns a JWT token.

**Request body:**

```json
{
  "username": "climber42",
  "email": "climber@example.com",
  "password": "securepassword"
}
```

| Field      | Type   | Rules                                |
|------------|--------|--------------------------------------|
| `username` | string | 8–24 characters, `[a-zA-Z0-9_]` only |
| `email`    | string | Must be a valid email address        |
| `password` | string | Minimum 8 characters                 |

**Responses:**

| Status                     | Meaning                       | Body                                              |
|----------------------------|-------------------------------|---------------------------------------------------|
| `201 Created`              | Account created, token issued | `{ "access_token": "<jwt>", "user_id": "<uuid>" }` |
| `409 Conflict`             | Email already registered      | Plain text error                                  |
| `422 Unprocessable Entity` | Validation failed             | Plain text error                                  |

**Example response (201):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

### POST /v1/auth/login — Log in

Authenticates a user with email and password. Returns a JWT token in both the body
and as an `HttpOnly` cookie.

**Request body:**

```json
{
  "email": "climber@example.com",
  "password": "securepassword"
}
```

| Field      | Type   | Rules                         |
|------------|--------|-------------------------------|
| `email`    | string | Must be a valid email address |
| `password` | string | Minimum 8 characters          |

**Responses:**

| Status                     | Meaning                          | Body                                              |
|----------------------------|----------------------------------|---------------------------------------------------|
| `200 OK`                   | Valid credentials, token returned | `{ "access_token": "<jwt>", "user_id": "<uuid>" }` |
| `401 Unauthorized`         | Wrong email or password          | Plain text error                                  |
| `422 Unprocessable Entity` | Malformed request fields         | Plain text error                                  |

**Example response (200):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

### POST /v1/auth/logout — Log out

Clears the `session_token` cookie. Safe to call even when not logged in.

**No request body.**

**Responses:**

| Status           | Meaning        | Body |
|------------------|----------------|------|
| `204 No Content` | Cookie cleared | —    |

---

## Users

### POST /v1/users — Create a user

Creates a new user account.

**Request body:**

```json
{
  "username": "climber42",
  "email": "climber@example.com",
  "password": "securepassword",
  "role": "user"
}
```

| Field      | Type   | Rules                                |
|------------|--------|--------------------------------------|
| `username` | string | 8–24 characters, `[a-zA-Z0-9_]` only |
| `email`    | string | Must be a valid email address        |
| `password` | string | Minimum 8 characters                 |
| `role`     | string | `"user"` or `"admin"`                |

**Responses:**

| Status                     | Meaning                                   | Body                 |
|----------------------------|-------------------------------------------|----------------------|
| `201 Created`              | User created successfully                 | `{ "id": "<uuid>" }` |
| `422 Unprocessable Entity` | Validation failed or email already exists | Plain text error     |

**Example response (201):**

```json
{ "id": "550e8400-e29b-41d4-a716-446655440000" }
```

---

### GET /v1/users — List all users

Returns a list of all registered users.

**No request body.**

**Responses:**

| Status   | Meaning | Body                       |
|----------|---------|----------------------------|
| `200 OK` | Success | JSON array of user objects |

**Example response (200):**

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "climber42",
    "email": "climber@example.com",
    "role": "user"
  }
]
```

---

### GET /v1/users/{id} — Get a user

Returns a single user by their UUID.

**Path parameter:**

| Parameter | Type        | Description                  |
|-----------|-------------|------------------------------|
| `id`      | UUID string | The user's unique identifier |

**Responses:**

| Status                     | Meaning                  | Body             |
|----------------------------|--------------------------|------------------|
| `200 OK`                   | User found               | User object      |
| `404 Not Found`            | No user with this ID     | Plain text error |
| `422 Unprocessable Entity` | `id` is not a valid UUID | Plain text error |

**Example response (200):**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "climber42",
  "email": "climber@example.com",
  "role": "user"
}
```

---

### PUT /v1/users/{id} — Update a user

Replaces all fields of an existing user. All fields are required.

**Path parameter:**

| Parameter | Type        | Description                  |
|-----------|-------------|------------------------------|
| `id`      | UUID string | The user's unique identifier |

**Request body:**

```json
{
  "username": "newname",
  "email": "new@example.com",
  "password": "newpassword",
  "role": "user"
}
```

**Responses:**

| Status                     | Meaning                   | Body                 |
|----------------------------|---------------------------|----------------------|
| `200 OK`                   | User updated successfully | `{ "id": "<uuid>" }` |
| `404 Not Found`            | No user with this ID      | Plain text error     |
| `422 Unprocessable Entity` | Validation failed         | Plain text error     |

---

### DELETE /v1/users/{id} — Delete a user

Permanently deletes a user.

**Path parameter:**

| Parameter | Type        | Description                  |
|-----------|-------------|------------------------------|
| `id`      | UUID string | The user's unique identifier |

**Responses:**

| Status          | Meaning              | Body                  |
|-----------------|----------------------|-----------------------|
| `200 OK`        | User deleted         | Empty or confirmation |
| `404 Not Found` | No user with this ID | Plain text error      |

---

## Videos

### POST /v1/videos/upload-url — Get a presigned upload URL

Registers a new video record in the database and returns a presigned PUT URL
that the client uses to upload the video file **directly to MinIO** (no proxying
through the server).

**Request body:**

```json
{
  "filename": "my-climb.mp4",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

| Field      | Type        | Description                                             |
|------------|-------------|---------------------------------------------------------|
| `filename` | string      | Original filename; used to infer the `Content-Type`     |
| `user_id`  | UUID string | Temporary field — will come from JWT once auth is wired |

**Responses:**

| Status                      | Meaning              | Body                                                        |
|-----------------------------|----------------------|-------------------------------------------------------------|
| `201 Created`               | URL generated        | `{ "video_id": "<uuid>", "upload_url": "<presigned-url>" }` |
| `500 Internal Server Error` | MinIO presign failed | Plain text error                                            |

**Example response (201):**

```json
{
  "video_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "upload_url": "http://minio:9000/videos/a1b2c3d4-...?X-Amz-Signature=..."
}
```

**Upload flow:**

```
1. Client → POST /v1/videos/upload-url  → gets { video_id, upload_url }
2. Client → PUT <upload_url>            → uploads bytes directly to MinIO
3. Client → POST /v1/analyses           → triggers AI processing
```

---

## Analyses

### POST /v1/analyses — Trigger an analysis

Creates an analysis record and publishes a job message to the `vision.skeleton`
RabbitMQ queue. The AI worker picks up the job asynchronously.

**Request body:**

```json
{ "video_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890" }
```

| Field      | Type        | Description                                       |
|------------|-------------|---------------------------------------------------|
| `video_id` | UUID string | The video to analyse (must exist in the database) |

**Responses:**

| Status                      | Meaning                   | Body                                                                   |
|-----------------------------|---------------------------|------------------------------------------------------------------------|
| `202 Accepted`              | Job queued                | `{ "analysis_id": "<uuid>", "job_id": "<uuid>", "status": "pending" }` |
| `404 Not Found`             | `video_id` does not exist | Plain text error                                                       |
| `500 Internal Server Error` | RabbitMQ publish failed   | Plain text error                                                       |

**Example response (202):**

```json
{
  "analysis_id": "bbbb0000-0000-0000-0000-000000000001",
  "job_id":      "cccc0000-0000-0000-0000-000000000001",
  "status":      "pending"
}
```

> `202 Accepted` means the job was queued — it does **not** mean the analysis is
> finished. Poll `GET /v1/analyses/{id}` to check completion.

---

### GET /v1/analyses/{id} — Get an analysis

Returns the current state of an analysis, including the result once completed.

**Path parameter:**

| Parameter | Type        | Description                                     |
|-----------|-------------|-------------------------------------------------|
| `id`      | UUID string | The analysis ID returned by `POST /v1/analyses` |

**Responses:**

| Status          | Meaning                  | Body             |
|-----------------|--------------------------|------------------|
| `200 OK`        | Analysis found           | Analysis object  |
| `404 Not Found` | No analysis with this ID | Plain text error |

**Example response (200) — still processing:**

```json
{
  "id":                  "bbbb0000-0000-0000-0000-000000000001",
  "video_id":            "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "job_id":              "cccc0000-0000-0000-0000-000000000001",
  "status":              "processing",
  "result_json":         null,
  "processing_time_ms":  null
}
```

**Example response (200) — completed:**

```json
{
  "id":                  "bbbb0000-0000-0000-0000-000000000001",
  "video_id":            "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "job_id":              "cccc0000-0000-0000-0000-000000000001",
  "status":              "completed",
  "result_json":         "{\"frames\": [...]}",
  "processing_time_ms":  4230
}
```

**Analysis status lifecycle:**

```
pending → processing → completed
                    ↘ failed
```

| Status       | Meaning                                                          |
|--------------|------------------------------------------------------------------|
| `pending`    | Job published to RabbitMQ, worker has not started yet            |
| `processing` | Worker has picked up the job and is running                      |
| `completed`  | `result_json` is populated with pose data                        |
| `failed`     | Worker encountered an error; job will be re-queued automatically |

---

## Health

### GET /healthz — Health check

A simple liveness probe. **Requires a valid JWT token + admin role.**

**Headers required:**

```
Authorization: Bearer <admin_jwt_token>
```

**Responses:**

| Status             | Meaning                             |
|--------------------|-------------------------------------|
| `204 No Content`   | Server is healthy                   |
| `401 Unauthorized` | Missing or invalid token            |
| `403 Forbidden`    | Token valid but role is not `admin` |

---

## Error Codes Reference

| HTTP Status                 | Meaning in Ascension                             |
|-----------------------------|--------------------------------------------------|
| `201 Created`               | Resource successfully created                    |
| `202 Accepted`              | Async job successfully queued                    |
| `204 No Content`            | Success with no body                             |
| `400 Bad Request`           | Malformed request                                |
| `401 Unauthorized`          | Missing or invalid JWT token                     |
| `403 Forbidden`             | Valid token but insufficient role                |
| `404 Not Found`             | Resource does not exist                          |
| `422 Unprocessable Entity`  | Validation error (bad UUID, invalid field, etc.) |
| `429 Too Many Requests`     | Rate limit exceeded (10 req/s per IP)            |
| `500 Internal Server Error` | Unexpected server-side failure                   |
