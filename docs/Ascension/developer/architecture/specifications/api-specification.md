---
id: 5d09b283-adb5-4bde-b3a4-5d9d79c195d2
---

:::success
**Version:** 1.0
:::

---

# API Specification

---

## Overview

This document describes the Ascension REST API for video analysis, route visualization, and climbing coaching.

**Base URL**: `https://api.ascension.app/v1` **Authentication**: JWT Bearer tokens **Format**: JSON

---

## Authentication

### Register (Sign Up)

```http
POST /v1/auth/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "first_name": "John",
  "last_name": "Doe",
  "username": "johndoe"
}
```

**Response (201 Created)**:

```json
{
  "user": {
    "id": "0191e4b8-7a8f-7c11-9a4f-123456789abc",
    "first_name": "John",
    "last_name": "Doe",
    "username": "johndoe",
    "email": "user@example.com",
    "role": "user",
    "created_at": "2026-03-01T12:00:00Z",
    "updated_at": "2026-03-01T12:00:00Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsIn...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsIn..."
}
```

### Login

Accepts either `email` or `username` via the `identifier` field:

```http
POST /v1/auth/login
Content-Type: application/json

{
  "identifier": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response (200 OK)**:

```json
{
  "user": {
    "id": "0191e4b8-7a8f-7c11-9a4f-123456789abc",
    "first_name": "John",
    "last_name": "Doe",
    "username": "johndoe",
    "email": "user@example.com",
    "role": "user",
    "created_at": "2026-03-01T12:00:00Z",
    "updated_at": "2026-03-01T12:00:00Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsIn...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsIn..."
}
```

### Refresh Token

```http
POST /v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsIn..."
}
```

**Response (200 OK)**:

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsIn...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsIn..."
}
```

### Logout

```http
DELETE /v1/auth/logout
Authorization: Bearer <access_token>
```

**Response (204 No Content)**: Empty body

---

## Video Management & Analysis

### 1\. Request Video Upload URL

Request a presigned URL to upload a climbing video directly to object storage.

```http
GET /v1/videos/upload-url?content_type=video/mp4&size=52428800
Authorization: Bearer <access_token>
```

**Response (200 OK)**:

```json
{
  "id": "0191e4b8-7a8f-7c11-9a4f-123456789abc",
  "upload_url": "https://minio:9000/videos/...",
  "expires_at": "2026-03-01T12:15:00Z"
}
```

### 2\. Confirm Video Upload

Notify the backend that the client has finished uploading the file to storage:

```http
PUT /v1/videos/upload-done/{video_id}
Authorization: Bearer <access_token>
```

**Response (204 No Content)**: Empty body

### 3\. List & Get Videos

```http
GET /v1/videos
Authorization: Bearer <access_token>
```

**Response (200 OK)**:

```json
[
  {
    "id": "0191e4b8-7a8f-7c11-9a4f-123456789abc",
    "user_id": "0191e4b8-7a8f-7c11-9a4f-abcdef123456",
    "object_key": "raw/user-id/video.mp4",
    "status": "ready",
    "size_bytes": 52428800,
    "duration_ms": 45000,
    "created_at": "2026-03-01T12:00:00Z"
  }
]
```

### 4\. Start Video Analysis

Enqueues an asynchronous analysis job with the specified analysis `type` (`2d`, `3d`, `hold`, `advice`) and `visibility` (`private`, `friends`, `gym`, `public`).

```http
POST /v1/analysis
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "video_id": "0191e4b8-7a8f-7c11-9a4f-123456789abc",
  "type": "2d",
  "visibility": "private"
}
```

**Response (201 Created)**:

```json
{
  "id": "0191e4b8-7a8f-7c11-9a4f-987654321def",
  "video_id": "0191e4b8-7a8f-7c11-9a4f-123456789abc",
  "status": "pending",
  "type": "2d",
  "visibility": "private",
  "created_at": "2026-03-01T12:00:00Z"
}
```

### 5\. Get Analysis Result

Poll the status or fetch results of a specific analysis:

```http
GET /v1/analysis/{analysis_id}
Authorization: Bearer <access_token>
```

**Response (200 OK)**:

```json
{
  "id": "uuid",
  "status": "completed",
  "result": {
    "frames": [
      {
        "frame_number": 0,
        "timestamp_ms": 0,
        "keypoints": [
          {
            "name": "left_shoulder",
            "x": 0.5,
            "y": 0.3,
            "confidence": 0.95
          }
        ],
        "joint_angles": {
          "left_elbow": 145.2,
          "right_knee": 89.5,
          "left_shoulder": 120.0
        }
      }
    ]
  }
}
```

---

## Route Ghost (Optimal Path Generation)

### 1\. Upload Route Photo

Upload a photo of a climbing route to generate the optimal path (ghost).

```http
POST /analysis/route/request-upload
Authorization: Bearer {token}
Content-Type: application/json

{
  "file_name": "route-photo.jpg",
  "file_size": 2048000
}
```

**Response (200)**:

```json
{
  "route_id": "uuid",
  "upload_url": "https://s3.../presigned-url"
}
```

### 2\. Generate Ghost

Generate the optimal climbing path for the route.

```http
POST /analysis/route/generate-ghost
Authorization: Bearer {token}
Content-Type: application/json

{
  "route_id": "uuid"
}
```

**Response (202)**:

```json
{
  "ghost_id": "uuid",
  "status": "processing"
}
```

### 3\. Get Ghost Result

```http
GET /analysis/ghost/{ghost_id}
Authorization: Bearer {token}
```

**Response (200)**:

```json
{
  "id": "uuid",
  "route_id": "uuid",
  "status": "completed",
  "ghost_path": [
    {
      "step": 1,
      "hand_position": {"x": 100, "y": 200},
      "foot_position": {"x": 120, "y": 350},
      "body_position": {"x": 110, "y": 275}
    }
  ]
}
```

---

## Ghost Overlay on Video

### Compare Video with Ghost

Overlay the ghost path on a climbing video to compare performance.

```http
POST /analysis/compare
Authorization: Bearer {token}
Content-Type: application/json

{
  "video_analysis_id": "uuid",
  "ghost_id": "uuid"
}
```

**Response (200)**:

```json
{
  "comparison_id": "uuid",
  "metrics": {
    "path_similarity": 0.78,
    "efficiency_score": 0.82,
    "deviations": [
      {
        "frame": 45,
        "difference": 15.5,
        "note": "Hand reached too high"
      }
    ]
  }
}
```

---

## Hold Recognition

### 1\. Upload Hold Image

Upload a photo or video of the wall to detect holds.

```http
POST /holds/request-upload
Authorization: Bearer {token}
Content-Type: application/json

{
  "file_name": "wall.jpg",
  "file_size": 3145728
}
```

**Response (200)**:

```json
{
  "image_id": "uuid",
  "upload_url": "https://s3.../presigned-url"
}
```

### 2\. Detect Holds

Detect and classify climbing holds in the image.

```http
POST /holds/detect
Authorization: Bearer {token}
Content-Type: application/json

{
  "image_id": "uuid"
}
```

**Response (200)**:

```json
{
  "detection_id": "uuid",
  "holds": [
    {
      "id": 1,
      "type": "jug",
      "position": {"x": 150, "y": 200},
      "confidence": 0.92
    },
    {
      "id": 2,
      "type": "crimp",
      "position": {"x": 180, "y": 180},
      "confidence": 0.88
    }
  ]
}
```

### 3\. Correct Hold Type

Manually correct a hold type if AI made a mistake.

```http
PATCH /holds/{hold_id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "type": "sloper"
}
```

**Response (200)**:

```json
{
  "id": 1,
  "type": "sloper",
  "position": {"x": 150, "y": 200},
  "manually_corrected": true
}
```

**Hold Types**:

- `jug` - Easy to grip
- `crimp` - Small edge
- `sloper` - Rounded, requires friction
- `pinch` - Grip with thumb and fingers
- `pocket` - Finger holes
- `edge` - Flat ledge

---

## Coaching & Goals

### 1\. Set Goals

Define climbing goals and get personalized training recommendations.

```http
POST /coaching/goals
Authorization: Bearer {token}
Content-Type: application/json

{
  "current_level": "6a",
  "target_level": "6c",
  "timeline_weeks": 12,
  "focus_areas": ["technique", "strength"],
  "training_days_per_week": 3
}
```

**Response (201)**:

```json
{
  "goal_id": "uuid",
  "suggested_routine": {
    "monday": {
      "session_type": "technique",
      "exercises": [
        {
          "name": "Footwork drills",
          "duration_minutes": 20,
          "description": "Focus on precise foot placement"
        },
        {
          "name": "Easy volume climbing",
          "duration_minutes": 30,
          "routes": "5+ to 6a"
        }
      ]
    },
    "wednesday": {
      "session_type": "strength",
      "exercises": [
        {
          "name": "Hangboard training",
          "sets": 5,
          "duration_seconds": 10
        }
      ]
    }
  }
}
```

### 2\. Get Routine

Retrieve the current training routine.

```http
GET /coaching/routine
Authorization: Bearer {token}
```

**Response (200)**:

```json
{
  "goal_id": "uuid",
  "progress": {
    "weeks_completed": 3,
    "total_weeks": 12,
    "current_level": "6a+",
    "sessions_completed": 8
  },
  "this_week": {
    "monday": { "completed": true },
    "wednesday": { "completed": false },
    "friday": { "completed": false }
  }
}
```

### 3\. Log Training Session

Mark a training session as completed.

```http
POST /coaching/sessions
Authorization: Bearer {token}
Content-Type: application/json

{
  "date": "2026-02-16",
  "session_type": "technique",
  "duration_minutes": 90,
  "notes": "Felt strong today, completed all exercises"
}
```

**Response (201)**:

```json
{
  "session_id": "uuid",
  "logged_at": "2026-02-16T18:30:00Z"
}
```

---

## User Profile & Management

### Get Current User Profile

```http
GET /v1/users/me
Authorization: Bearer <access_token>
```

**Response (200 OK)**:

```json
{
  "id": "0191e4b8-7a8f-7c11-9a4f-123456789abc",
  "first_name": "John",
  "last_name": "Doe",
  "username": "johndoe",
  "email": "user@example.com",
  "role": "user",
  "created_at": "2026-03-01T12:00:00Z",
  "updated_at": "2026-03-01T12:00:00Z"
}
```

### User Management (Admin Only)

Administrative endpoints to manage users require the `admin` role:

| Method | Endpoint | Description |
| --- | --- | --- |
| `GET` | `/v1/users` | List all users (paginated) |
| `POST` | `/v1/users` | Create user directly |
| `GET` | `/v1/users/{id}` | Get user by ID |
| `PUT` | `/v1/users/{id}` | Update user details |
| `DELETE` | `/v1/users/{id}` | Delete user |

### Subscription Tiers

| Tier | Price | Videos | Ghost Mode | Max Routines | Server Priority | Ads |
| --- | --- | --- | --- | --- | --- | --- |
| **Freemium** | Free | 10 / month | ❌ | 5 | ❌ | ✅ |
| **Premium** | 20€/month | 30 / month | 30 / month | Unlimited | ❌ | ❌ |
| **Infinity** | 30€/month | 100 / month | 100 / month | Unlimited | ✅ | ❌ |

---

## WebSocket (Real-time Updates)

Connect to receive live updates on analysis progress.

**Endpoint**: `wss://api.ascension.app/v1/ws?token={jwt}`

### Messages from Server

Analysis Progress

```json
{
  "event": "analysis:progress",
  "data": {
    "analysis_id": "uuid",
    "progress": 45,
    "stage": "skeleton_detection"
  }
}
```

Analysis Complete

```json
{
  "event": "analysis:completed",
  "data": {
    "analysis_id": "uuid",
    "status": "completed"
  }
}
```

---

## Error Codes

| Code | Meaning |
| --- | --- |
| 400 | Invalid request |
| 401 | Unauthorized (invalid/missing token) |
| 403 | Quota exceeded or feature not available in tier |
| 404 | Resource not found |
| 413 | File too large |
| 429 | Too many requests |
| 500 | Server error |

---

**Related Documentation**:

- [Database Schema](database-schema.md)
- [System Overview](../system-overview.md)
- [Video Analysis Workflow](../workflows/video-analysis-flow.md)
