<div align="center">

# Ascension

**AI-powered climbing coach — objective technique analysis, personalized feedback**

[![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter)](https://flutter.dev)
[![Rust](https://img.shields.io/badge/Backend-Rust%20%2F%20Axum-DEA584?logo=rust)](https://www.rust-lang.org)
[![Python](https://img.shields.io/badge/AI%20Workers-Python%20%2F%20MediaPipe-3776AB?logo=python)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-336791?logo=postgresql)](https://postgresql.org)

</div>

---

## What is Ascension?

Ascension is a mobile application that analyzes your climbing videos using computer vision and AI to give you concrete, objective feedback on your technique — the kind of feedback that usually requires a professional coach standing right next to you.

Film yourself on the wall. Upload the video. Get a biomechanical breakdown of your movement, joint-by-joint coaching advice, and an optional ghost overlay showing the optimal path for your morphology.

---

## The problem we're solving

Professional climbing coaching is expensive, subjective, and hard to access. Most climbers train without real-time feedback and only correct bad habits when they plateau or get injured.

Ascension bridges that gap by making objective, AI-driven analysis available to any climber — from beginner to competition-level — at a fraction of the cost.

---

## Core features

**Video analysis**
Extracts a 33-point skeleton from each frame of your climbing video using pose estimation. Computes joint angles, center of gravity, and weight distribution throughout the move.

**Hold detection**
Photograph the route before you climb. The AI detects and classifies holds (crimp, sloper, jug, pinch, pocket…). You can manually correct misclassifications before the analysis runs.

**Coaching advice**
Combines skeleton data with hold positions to generate targeted, move-by-move feedback. Concrete, not generic — e.g. "hip too far from the wall on move 3" or "match hands before flagging right."

**Ghost Climber** *(Premium)*
Generates the optimal movement path for your morphology using inverse kinematics, then renders it as a frame-by-frame overlay on your video. Compare your actual movement to the ideal line.

**Personalized training programs**
Custom routines generated from your profile (level, goals, injury history) and updated based on your analysis history.

---

## Architecture

Ascension is built as a monorepo with three independently deployable services:

```
apps/
├── mobile/    Flutter app (iOS & Android)
├── server/    Rust / Axum REST API + WebSocket
└── ai/        Python AI workers (MediaPipe, PyTorch, OpenCV)
```

**Data flow**

```
User films → presigned URL → direct upload to object storage
→ API notifies queue → AI worker processes → JSON results stored
→ WebSocket notification → client renders overlay
```

Heavy AI workloads (pose estimation, hold detection, ghost path generation) are queued via RabbitMQ and processed asynchronously. The mobile client renders results from a lightweight JSON payload (~50 KB) rather than a re-encoded video — keeping latency low and egress costs minimal.

**Performance targets**
- API response time: p95 < 200 ms
- Analysis processing: < 30 s for a 30-second video
- Time to result (upload + processing): ~45 s

---

## Tech stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart), CustomPainter for overlays |
| API | Rust, Axum, Tokio, JWT auth, WebSocket |
| AI Workers | Python 3.10+, MediaPipe, PyTorch, OpenCV |
| Queue | RabbitMQ 3.12+ |
| Database | PostgreSQL 16 (JSONB for analysis results) |
| Object storage | MinIO (dev) / Hetzner Object Storage (prod) |
| Infra | Hetzner Cloud, Docker Compose → Kubernetes |
| Monorepo | moonrepo |

---

## Repositories

| Repository | Description |
|---|---|
| [Ascension](../Ascension) | **Main Monorepo** — Core ecosystem including Flutter mobile app, Rust API, and Python AI workers. |
| [benchmark](../benchmark) | **Performance Suite** — Technical benchmarks and stress tests for the mobile and backend stack. |
| [.github](../.github) | **Organization Profile** — Global GitHub profile configuration. |

---

## Subscription model

| Tier | Price | Analyses / month | Ghost Climber |
|---|---|---|---|
| Freemium | Free | 10 | No |
| Premium | €20 / month | 30 | Yes |
| Infinity | €30 / month | 100 | Yes |

---

## Status

Active development. The architecture, API specification, database schema, and infrastructure guides are finalized. Core services are being implemented.

---

<div align="center">

*Epitech Innovative Project — 2025/2026*

</div>
