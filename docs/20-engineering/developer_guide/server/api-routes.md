> **Last updated:** 12th March 2026  
> **Version:** 1.1  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Server API Routes Reference

This document lists every HTTP route exposed by the Ascension backend server,
with request/response examples and notes on authentication requirements.
No prior Go knowledge is needed to use this reference.

---

## Table of Contents

- [Server API Routes Reference](#server-api-routes-reference)
  - [Table of Contents](#table-of-contents)
  - [Base URL](#base-url)
  - [Response Format](#response-format)
  - [Authentication](#authentication)
  - [Rate Limiting](#rate-limiting)
  - [Auth](#auth)
    - [POST /v1/auth/signup — Register a new account](#post-v1authsignup--register-a-new-account)
    - [POST /v1/auth/login — Log in](#post-v1authlogin--log-in)
    - [DELETE /v1/auth/logout — Log out](#delete-v1authlogout--log-out)
    - [PUT /v1/auth/refresh — Refresh token](#put-v1authrefresh--refresh-token)
  - [Users](#users)
    - [POST /v1/users — Create a user](#post-v1users--create-a-user)
    - [GET /v1/users — List all users](#get-v1users--list-all-users)
    - [GET /v1/users/{id} — Get a user](#get-v1usersid--get-a-user)
    - [PUT /v1/users/{id} — Update a user](#put-v1usersid--update-a-user)
    - [DELETE /v1/users/{id} — Delete a user](#delete-v1usersid--delete-a-user)
  - [Videos](#videos)
    - [GET /v1/videos/upload-url — Get a presigned upload URL](#get-v1videosupload-url--get-a-presigned-upload-url)
    - [PUT /v1/videos/upload-done/{id} — Complete upload](#put-v1videosupload-doneid--complete-upload)
    - [GET /v1/videos/download-url/{id} — Get download URL](#get-v1videosdownload-urlid--get-download-url)
  - [Analyses](#analyses)
    - [POST /v1/analysis — Trigger an analysis](#post-v1analysis--trigger-an-analysis)
    - [GET /v1/analysis/{id} — Get an analysis](#get-v1analysisid--get-an-analysis)
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

All auth endpoints live under `/v1/auth`. They do **not** require an `Authorization` header.

On successful login or registration, the server returns the user info, an access token, and a refresh token.

### POST /v1/auth/signup — Register a new account

Creates a new user account with the `user` role, hashes the password with bcrypt, and logs the user in.

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
| `username` | string | Required                             |
| `email`    | string | Required, valid email format         |
| `password` | string | Required, minimum 8 characters       |

**Responses:**

| Status                     | Meaning                       | Body                                              |
|----------------------------|-------------------------------|---------------------------------------------------|
| `200 OK`                   | Account created, token issued | Login Response JSON                               |
| `400 Bad Request`          | Validation failed             | Plain text error                                  |
| `409 Conflict`             | Email/Username already exists | Plain text error                                  |

**Example response (200):**

```json
{
  "refresh_token": "a1b2c3d4...",
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 900,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "climber42",
    "email": "climber@example.com",
    "role": "user"
  }
}
```

---

### POST /v1/auth/login — Log in

Authenticates a user with email and password.

**Request body:**

```json
{
  "email": "climber@example.com",
  "password": "securepassword"
}
```

**Responses:**

| Status                     | Meaning                          | Body                                              |
|----------------------------|----------------------------------|---------------------------------------------------|
| `200 OK`                   | Authenticated                    | Login Response JSON                               |
| `400 Bad Request`          | Validation failed             | Plain text error                                  |
| `401 Unauthorized`          | Incorrect credentials            | Plain text error                                  |

---

### DELETE /v1/auth/logout — Log out

Logs out the user and invalidates the session token.

**Responses:**

| Status          | Meaning          |
|-----------------|------------------|
| `200 OK`        | Logged out       |

---

### PUT /v1/auth/refresh — Refresh token

Refreshes the access token using the refresh token.

**Request body:**

```json
{
  "token": "refresh_token_string"
}
```

**Responses:**

| Status          | Meaning          | Body                |
|-----------------|------------------|---------------------|
| `200 OK`        | Token refreshed  | Access Token Response|
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

### GET /v1/videos/upload-url — Get a presigned upload URL

Generates a presigned URL that the client uses to upload the video file **directly to MinIO** (no proxying through the server).

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `content_type`| string| Allowed: `video/mp4`, `video/webm`, `video/quicktime`, `video/x-msvideo` |
| `size` | int | Size in bytes (max 1GB) |

**Responses:**

| Status                      | Meaning              | Body                                                                        |
|-----------------------------|----------------------|-----------------------------------------------------------------------------|
| `200 OK`                    | URL generated        | `{ "video_id": "<uuid>", "upload_url": "<presigned-url>", "expires_at": "<time>" }` |
| `400 Bad Request`           | Missing or invalid params | Plain text error                                                       |
| `500 Internal Server Error` | MinIO presign failed | Plain text error                                                            |

---

### PUT /v1/videos/upload-done/{id} — Complete upload

Signals that the video upload has been completed by the client.

**Responses:**

| Status                      | Meaning              |
|-----------------------------|----------------------|
| `204 No Content`            | Upload completed     |

---

### GET /v1/videos/download-url/{id} — Get download URL

Generates a presigned GET URL to watch or download the video.

**Responses:**

| Status                      | Meaning              | Body |
|-----------------------------|----------------------|------|
| `200 OK`                    | Download URL ready   | `{ "download_url": "<url>", "expires_at": "<time>" }` |

**Upload flow:**

```
1. Client → GET /v1/videos/upload-url?content_type=...&size=... → gets { video_id, upload_url }
2. Client → PUT <upload_url>            → uploads bytes directly to MinIO
3. Client → PUT /v1/videos/upload-done/{video_id} → completes upload
4. Client → POST /v1/analysis           → triggers AI processing
```

---

## Analyses

### POST /v1/analysis — Trigger an analysis

Creates an analysis record and publishes a job message to the `vision.skeleton` RabbitMQ queue.

**Request body:**

```json
{ "video_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890" }
```

**Responses:**

| Status                      | Meaning                   | Body                                                                   |
|-----------------------------|---------------------------|------------------------------------------------------------------------|
| `202 Accepted`              | Job queued                | `{ "id": "<uuid>", "status": "pending" }` |
| `404 Not Found`             | `video_id` does not exist | Plain text error                                                       |

---

### GET /v1/analysis/{id} — Get an analysis

Returns the current state of an analysis.

**Responses:**

| Status          | Meaning                  | Body             |
|-----------------|--------------------------|------------------|
| `200 OK`        | Analysis found           | `{ "id": "<uuid>", "status": "<status>" }` |

**Analysis status lifecycle:**

```
pending → processing → completed
                    ↘ failed
```

---

## Health

### GET /healthz — Health check

A simple public liveness probe.

**Responses:**

| Status             | Meaning                             |
|--------------------|-------------------------------------|
| `204 No Content`   | Server is healthy                   |

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
