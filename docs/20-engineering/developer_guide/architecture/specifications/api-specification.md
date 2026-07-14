> **Last updated:** 16th February 2026  
> **Version:** 1.0  
> **Authors:** Gianni TUERO  
> **Status:** Done  
> {.is-success}

---

# API Specification

---

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
  - [Register](#register)
  - [Login](#login)
- [Video Analysis (Skeleton Detection)](#video-analysis-skeleton-detection)
  - [1. Request Upload URL](#1-request-upload-url)
  - [2. Start Video Analysis](#2-start-video-analysis)
  - [3. Get Analysis Result](#3-get-analysis-result)
- [Route Ghost (Optimal Path Generation)](#route-ghost-optimal-path-generation)
  - [1. Upload Route Photo](#1-upload-route-photo)
  - [2. Generate Ghost](#2-generate-ghost)
  - [3. Get Ghost Result](#3-get-ghost-result)
- [Ghost Overlay on Video](#ghost-overlay-on-video)
  - [Compare Video with Ghost](#compare-video-with-ghost)
- [Hold Recognition](#hold-recognition)
  - [1. Upload Hold Image](#1-upload-hold-image)
  - [2. Detect Holds](#2-detect-holds)
  - [3. Correct Hold Type](#3-correct-hold-type)
- [Coaching & Goals](#coaching-goals)
  - [1. Set Goals](#1-set-goals)
  - [2. Get Routine](#2-get-routine)
  - [3. Log Training Session](#3-log-training-session)
- [User Profile & Subscription](#user-profile-subscription)
  - [Get Profile](#get-profile)
  - [Subscription Tiers](#subscription-tiers)
- [WebSocket (Real-time Updates)](#websocket-real-time-updates)
  - [Messages from Server](#messages-from-server)
    - [Analysis Progress](#analysis-progress)
    - [Analysis Complete](#analysis-complete)
- [Error Codes](#error-codes)


---

## Overview

This document describes the Ascension REST API for video analysis, route visualization, and climbing coaching.

**Base URL**: `https://api.ascension.app/v1`
**Authentication**: JWT Bearer tokens
**Format**: JSON

---

## Authentication

### Register

```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response (201)**:
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "subscription_tier": "freemium"
  },
  "access_token": "jwt_token"
}
```

### Login

```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response (200)**:
```json
{
  "access_token": "jwt_token",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "subscription_tier": "freemium"
  }
}
```

---

## Video Analysis (Skeleton Detection)

### 1. Request Upload URL

Get a presigned URL to upload a climbing video directly to storage.

```http
POST /analysis/video/request-upload
Authorization: Bearer {token}
Content-Type: application/json

{
  "file_name": "my-climb.mp4",
  "file_size": 52428800
}
```

**Response (200)**:
```json
{
  "video_id": "uuid",
  "upload_url": "https://s3.../presigned-url",
  "expires_at": "2026-02-16T10:45:00Z"
}
```

### 2. Start Video Analysis

Analyze a video to extract skeleton keypoints and joint angles.

```http
POST /analysis/video/start
Authorization: Bearer {token}
Content-Type: application/json

{
  "video_id": "uuid"
}
```

**Response (202)**:
```json
{
  "analysis_id": "uuid",
  "status": "pending",
  "estimated_time_seconds": 30
}
```

### 3. Get Analysis Result

```http
GET /analysis/video/{analysis_id}
Authorization: Bearer {token}
```

**Response (200)**:
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

### 1. Upload Route Photo

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

### 2. Generate Ghost

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

### 3. Get Ghost Result

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

### 1. Upload Hold Image

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

### 2. Detect Holds

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

### 3. Correct Hold Type

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

### 1. Set Goals

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

### 2. Get Routine

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

### 3. Log Training Session

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

## User Profile & Subscription

### Get Profile

```http
GET /users/me
Authorization: Bearer {token}
```

**Response (200)**:
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "subscription_tier": "premium",
  "monthly_quota": 30,
  "quota_used": 12,
  "created_at": "2026-01-01T00:00:00Z"
}
```

### Subscription Tiers

| Tier | Price | Videos/Month | Ghost Mode | Server Priority | Deep Analysis | Ads |
|------|-------|--------------|------------|-----------------|---------------|-----|
| **Freemium** | Free | 10 | ❌ | ❌ | ❌ | ✅ |
| **Premium** | 20€/month | 30 | ✅ | ❌ | ❌ | ❌ |
| **Infinity** | 30€/month | 100 | ✅ | ✅ | ✅ | ❌ |

---

## WebSocket (Real-time Updates)

Connect to receive live updates on analysis progress.

**Endpoint**: `wss://api.ascension.app/v1/ws?token={jwt}`

### Messages from Server

#### Analysis Progress
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

#### Analysis Complete
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
|------|---------|
| 400 | Invalid request |
| 401 | Unauthorized (invalid/missing token) |
| 403 | Quota exceeded or feature not available in tier |
| 404 | Resource not found |
| 413 | File too large |
| 429 | Too many requests |
| 500 | Server error |

---

**Related Documentation**:
- [Database Schema](./database-schema.md)
- [System Overview](../system-overview.md)
- [Video Analysis Workflow](../workflows/video-analysis-flow.md)
