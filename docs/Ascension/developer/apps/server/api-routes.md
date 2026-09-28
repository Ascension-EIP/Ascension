---
id: bfb575e1-a621-48a9-8452-4d113ee0e10e
---

:::success
**Version:** 1.3
:::

---

# Server API Routes Reference

This document lists every HTTP route exposed by the Ascension backend server, with request/response examples, rate limits, and authentication requirements.

---

## Base URL

| Environment | URL |
| --- | --- |
| Local development | `http://localhost:8080` |
| Docker (Android emulator) | `http://10.0.2.2:8080` |
| Production | Configured via `PORT` environment variable |

All routes are prefixed with `/v1` except `/healthz`.

---

## Response Format

- **Successful responses** return the payload directly as a JSON object or array.
- **Error responses** always return a JSON object with an `error` key matching the `response.Error` struct:

```json
{
  "error": "email already exists"
}
```

---

## Authentication & Authorization

Protected endpoints require a valid JWT bearer token in the `Authorization` header:

```http
Authorization: Bearer <access_token>
```

Authentication is enforced via `middleware.AuthMiddleware` (`internal/inbound/http/middleware/auth.go`). The middleware validates the JWT token, checks allowed user roles, and attaches the parsed `model.User` to the Gin context at key `macro.Me` (`"me"`).

| Access Level | Routes | Required Role |
| --- | --- | --- |
| **Public** | `/healthz`, `/v1/auth/signup`, `/v1/auth/login`, `/v1/auth/refresh` | None |
| **Authenticated** | `DELETE /v1/auth/logout`, `/v1/videos/*`, `/v1/analysis/*` | `user` or `admin` |
| **Admin Only** | `/v1/users/*` | `admin` |

---

## Rate Limiting

Rate limiting is enforced per client IP via `middleware.RateLimiter`:

| Route / Group | Rate Limit |
| --- | --- |
| `POST /v1/auth/signup` | 5 requests / minute |
| `POST /v1/auth/login` | 10 requests / minute |
| `DELETE /v1/auth/logout` | 10 requests / minute |
| `PUT /v1/auth/refresh` | 10 requests / minute |
| `/v1/users/*` | 100 requests / minute |
| `/v1/videos/*` | 10 requests / minute |
| `/v1/analysis/*` | 10 requests / minute |

Excess requests receive `429 Too Many Requests`.

---

## Auth

All auth endpoints live under `/v1/auth`.

### POST /v1/auth/signup — Register a new account

Creates a new user account, hashes the password with bcrypt, creates a refresh session, and issues tokens.

**Rate limit:** 5 req/min.\
**Authentication:** None.

**Request body:**

```json
{
  "username": "climber42",
  "first_name": "Alex",
  "last_name": "Honnold",
  "email": "alex@example.com",
  "password": "securepassword123",
  "remember": true
}
```

| Field | Type | Rules |
| --- | --- | --- |
| `username` | string | Required, 6–24 characters |
| `first_name` | string | Required |
| `last_name` | string | Required |
| `email` | string | Required, valid email format |
| `password` | string | Required, 8–64 characters |
| `remember` | boolean | Optional (extends session expiration) |

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `200 OK` | Account created and user logged in | `LoginResponse` |
| `400 Bad Request` | Validation failed | `{"error": "<msg>"}` |
| `409 Conflict` | Email or username already exists | `{"error": "<msg>"}` |

**Example response (200):**

```json
{
  "refresh_token": "a1b2c3d4...",
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 900,
  "user": {
    "ID": "018e6e5a-1234-7abc-8def-0123456789ab",
    "Username": "climber42",
    "FirstName": "Alex",
    "LastName": "Honnold",
    "Email": "alex@example.com",
    "Role": "user",
    "Status": "active"
  }
}
```

---

### POST /v1/auth/login — Log in

Authenticates a user via their identifier (email or username) and password.

**Rate limit:** 10 req/min.\
**Authentication:** None.

**Request body:**

```json
{
  "identifier": "climber42",
  "password": "securepassword123",
  "remember": false
}
```

| Field | Type | Rules |
| --- | --- | --- |
| `identifier` | string | Required (username or email) |
| `password` | string | Required |
| `remember` | boolean | Optional |

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `200 OK` | Successfully authenticated | `LoginResponse` |
| `400 Bad Request` | Validation failed | `{"error": "<msg>"}` |
| `401 Unauthorized` | Invalid credentials | `{"error": "<msg>"}` |

---

### DELETE /v1/auth/logout — Log out

Revokes the caller's active refresh session.

**Rate limit:** 10 req/min.\
**Authentication:** Required (`Authorization: Bearer <jwt>`).

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `200 OK` | Session successfully revoked | empty |
| `401 Unauthorized` | Missing or invalid token | empty |

---

### PUT /v1/auth/refresh — Refresh access token

Generates a new access token using a valid refresh token.

**Rate limit:** 10 req/min.\
**Authentication:** None.

**Request body:**

```json
{
  "refresh_token": "a1b2c3d4e5f6..."
}
```

| Field | Type | Rules |
| --- | --- | --- |
| `refresh_token` | string | Required |

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `200 OK` | New access token issued | `AccessTokenResponse` |
| `400 Bad Request` | Missing token | `{"error": "<msg>"}` |
| `401 Unauthorized` | Invalid, expired, or revoked refresh token | `{"error": "<msg>"}` |

**Example response (200):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 900
}
```

---

## Users (Admin Only)

All endpoints under `/v1/users` require the `admin` role (`authMW(model.UserRoleAdmin)`).

**Rate limit:** 100 req/min.

### POST /v1/users — Create a user

**Request body:**

```json
{
  "username": "coach_john",
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com",
  "password": "initialpassword123",
  "role": "coach"
}
```

| Field | Type | Rules |
| --- | --- | --- |
| `username` | string | Required, 6–24 characters |
| `first_name` | string | Required |
| `last_name` | string | Required |
| `email` | string | Required, valid email format |
| `password` | string | Required, 8–64 characters |
| `role` | string | Required (`"user"`, `"admin"`, `"coach"`, `"gym"`) |

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `201 Created` | User created successfully | `{"id": "<uuid>"}` |
| `400 Bad Request` | Validation failed | `{"error": "<msg>"}` |
| `409 Conflict` | Email or username already exists | `{"error": "<msg>"}` |

---

### GET /v1/users — List all users

Returns all registered users.

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `200 OK` | Success | Array of `response.User` |

---

### GET /v1/users/:id — Get user by ID

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `200 OK` | User found | `response.User` |
| `400 Bad Request` | Invalid UUID format | `{"error": "<msg>"}` |
| `404 Not Found` | User does not exist | `{"error": "<msg>"}` |

---

### PUT /v1/users/:id — Partially update user

Allows updating any subset of a user's fields. All fields in the body are optional.

**Request body:**

```json
{
  "first_name": "Jonathan",
  "role": "admin",
  "status": "active"
}
```

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `200 OK` | User updated successfully | `{"id": "<uuid>"}` |
| `400 Bad Request` | Validation error | `{"error": "<msg>"}` |
| `404 Not Found` | User does not exist | `{"error": "<msg>"}` |

---

### DELETE /v1/users/:id — Delete user

Permanently deletes the specified user.

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `200 OK` | User deleted | empty |
| `404 Not Found` | User does not exist | `{"error": "<msg>"}` |

---

## Videos

**Rate limit:** 10 req/min.\
**Authentication:** Required (`user` or `admin`).

### GET /v1/videos/upload-url — Get a presigned upload URL

Generates a presigned PUT URL allowing direct upload from the mobile client to MinIO/S3.

**Request body (JSON):**

```json
{
  "content_type": "video/mp4",
  "size": 52428800,
  "visibility": "private",
  "climbing_session_id": null,
  "title": "Send of Sector 4",
  "retained": false
}
```

| Field | Type | Rules |
| --- | --- | --- |
| `content_type` | string | Required (`video/mp4`, `video/webm`, `video/quicktime`, `video/x-msvideo`) |
| `size` | int | Required, size in bytes (maximum 1 GB) |
| `visibility` | string | Required (`"private"`, `"friends"`, `"public"`) |
| `climbing_session_id` | UUID | Optional parent climbing session ID |
| `title` | string | Optional video title |
| `retained` | boolean | Optional flag to bypass the default 7-day deletion policy |

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `200 OK` | Presigned URL generated | `{"video_id": "<uuid>", "upload_url": "<presigned-url>", "expires_at": "<time>"}` |
| `400 Bad Request` | Validation failed | `{"error": "<msg>"}` |

---

### PUT /v1/videos/upload-done/:id — Complete upload

Notifies the server that the mobile client has finished uploading the file to object storage. The server verifies the object in storage, extracts metadata, and marks the video as completed.

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `204 No Content` | Upload verified and completed | empty |
| `400 Bad Request` | Invalid UUID | `{"error": "<msg>"}` |
| `404 Not Found` | Video not found | `{"error": "<msg>"}` |

---

### GET /v1/videos/download-url/:id — Get download URL

Generates a time-limited presigned GET URL to stream or download the video.

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `200 OK` | Download URL generated | `{"download_url": "<presigned-url>", "expires_at": "<time>"}` |
| `404 Not Found` | Video not found | `{"error": "<msg>"}` |

---

## Analyses

**Rate limit:** 10 req/min.\
**Authentication:** Required (`user` or `admin`).

### POST /v1/analysis — Trigger an analysis

Creates a pending analysis record and dispatches a job message to the RabbitMQ queue (`vision.skeleton`).

**Request body:**

```json
{
  "video_id": "018e6e5a-1234-7abc-8def-0123456789ab",
  "type": "2d",
  "visibility": "private"
}
```

| Field | Type | Rules |
| --- | --- | --- |
| `video_id` | UUID string | Required, ID of a completed video |
| `type` | string | Required (`"2d"` or `"3d"`) |
| `visibility` | string | Required (`"private"`, `"friends"`, `"public"`) |

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `202 Accepted` | Job successfully queued | `AnalysisResponse` |
| `400 Bad Request` | Validation failed | `{"error": "<msg>"}` |
| `404 Not Found` | Video does not exist | `{"error": "<msg>"}` |

---

### GET /v1/analysis/:id — Get analysis details & progress

Returns the current progress, status, and results of an analysis.

**Responses:**

| Status | Meaning | Body |
| --- | --- | --- |
| `200 OK` | Analysis found | `AnalysisResponse` |
| `404 Not Found` | Analysis does not exist | `{"error": "<msg>"}` |

**Example response (200):**

```json
{
  "id": "018e6e5a-abcd-7ef0-1234-567890abcdef",
  "video_id": "018e6e5a-1234-7abc-8def-0123456789ab",
  "type": "2d",
  "status": "completed",
  "visibility": "private",
  "progress": 100,
  "result": {
    "fps": 30.0,
    "width": 1080,
    "height": 1920,
    "frames": [...]
  },
  "advice": "Keep your hips closer to the wall on hold 4.",
  "error": null,
  "processing_time_ms": 14250,
  "started_at": "2026-09-22T10:15:00Z",
  "completed_at": "2026-09-22T10:15:14Z"
}
```

**Analysis Status Lifecycle:**

```
pending → processing → completed
                    ↘ failed
```

---

## Health

### GET /healthz — Liveness probe

Simple unauthenticated liveness check.

**Responses:**

| Status | Meaning |
| --- | --- |
| `204 No Content` | Server is running and healthy |

---

## HTTP Status Codes Reference

| HTTP Status | Ascension Usage |
| --- | --- |
| `200 OK` | Request succeeded with response body |
| `201 Created` | Resource created successfully |
| `202 Accepted` | Async task successfully queued for processing |
| `204 No Content` | Success with no response body |
| `400 Bad Request` | Request binding or format validation failed |
| `401 Unauthorized` | Missing, expired, or invalid JWT token |
| `403 Forbidden` | Valid token but insufficient role privileges |
| `404 Not Found` | Requested entity not found |
| `409 Conflict` | Unique constraint violation (duplicate email or username) |
| `422 Unprocessable Entity` | Domain validation rules rejected the input |
| `429 Too Many Requests` | IP rate limit exceeded |
| `500 Internal Server Error` | Unexpected internal failure |
