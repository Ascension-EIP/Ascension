---
title: prototype-pool
description: 
published: true
date: 2026-03-02T11:19:15.625Z
tags: 
editor: markdown
dateCreated: 2026-03-02T11:17:35.272Z
---

> **Last updated:** 2nd March 2026
> **Version:** 1.0
> **Authors:** Nicolas TORO
> **Status:** Done
> {.is-success}

---

# Prototype Pool — 2-Week Prototyping Sprint

---

## Table of Contents

- [Prototype Pool — 2-Week Prototyping Sprint](#prototype-pool--2-week-prototyping-sprint)
  - [Table of Contents](#table-of-contents)
  - [1. Objectives](#1-objectives)
  - [2. Scope](#2-scope)
    - [2.1 AI Service](#21-ai-service)
    - [2.2 Backend Server](#22-backend-server)
    - [2.3 Mobile Application](#23-mobile-application)
    - [2.4 Infrastructure](#24-infrastructure)
  - [3. User Flow](#3-user-flow)
  - [4. Development Environment](#4-development-environment)
    - [4.1 Global Environment](#41-global-environment)
    - [4.2 Team Setup](#42-team-setup)
    - [4.3 Toolchain \& Versions](#43-toolchain--versions)
      - [Task Runner — moon](#task-runner--moon)
      - [Backend — Rust](#backend--rust)
      - [AI — Python](#ai--python)
      - [Mobile — Flutter / Dart](#mobile--flutter--dart)
      - [Infrastructure — Docker \& Services](#infrastructure--docker--services)
    - [4.4 Development Workflow](#44-development-workflow)
  - [5. Task Assignment](#5-task-assignment)
  - [6. Key Milestones](#6-key-milestones)
  - [7. Material Request](#7-material-request)
    - [7.1 Cloud Infrastructure (Hetzner)](#71-cloud-infrastructure-hetzner)
    - [7.2 Physical Test Devices](#72-physical-test-devices)

---

## 1. Objectives

The goal of this 2-week prototyping sprint is to build a **functional end-to-end prototype** that validates the feasibility of the entire Ascension technical stack.

Concretely, this sprint must answer the following questions:

- Is the **global data flow** (Mobile → Rust API → RabbitMQ → Python AI → PostgreSQL → Mobile) viable?
- Can each technology work together in a **unified, integrated system**?
- Does **MediaPipe** successfully extract skeleton keypoints from a climbing video?
- Can **MinIO** reliably handle video storage with presigned upload URLs?
- Does **RabbitMQ** correctly route messages between the backend and the AI worker?
- Is the **PostgreSQL schema** functional with the expected data model?

This prototype is **not a production-ready deliverable** — it is a technical proof-of-concept used to validate the stack, surface integration issues early, and establish a solid foundation for the next development phases.

---

## 2. Scope

### 2.1 AI Service

- Implement a first AI pipeline using **MediaPipe** for pose estimation.
- Analyze a climbing video and extract skeleton keypoints (33 landmarks).
- Return a structured **JSON result** containing keypoints, angles, and basic feedback.
- Consume analysis jobs from a **RabbitMQ queue** and publish results back.

### 2.2 Backend Server

- Initialize the **Rust/Axum** server with the foundational routes.
- Implement the video upload flow: generate a **presigned MinIO URL** and return it to the mobile client.
- Implement a route to **trigger an analysis**: publish an analysis job to RabbitMQ.
- Implement a route to **fetch analysis results** from PostgreSQL.
- Publish jobs to RabbitMQ and consume AI results.
- Set up the **PostgreSQL schema** with the core tables: `users`, `videos`, `analyses`.

### 2.3 Mobile Application

- Build a functional Flutter UI that allows the user to:
  - Select and **upload a video** to the presigned MinIO URL.
  - **Trigger an analysis** via the backend.
  - **Display the analysis result** (keypoints / basic skeleton overlay).
- The flow must be **seamless and continuous** — no separate isolated screens.

### 2.4 Infrastructure

- Set up **MinIO** (object storage) via Docker Compose.
- Set up **RabbitMQ** (message broker) via Docker Compose.
- Set up **PostgreSQL** (database) via Docker Compose with the initial schema.
- If time allows: implement **authentication** (JWT).

---

## 3. User Flow

The following describes the core user journey that the prototype must be able to demonstrate end-to-end:

1. The **mobile app** requests a presigned upload URL from the backend.
2. The backend generates and returns a **presigned MinIO URL**.
3. The mobile app **uploads the video directly to MinIO** using this URL.
4. The user taps **"Analyse"** — the mobile app sends an analysis request to the backend.
5. The backend **publishes an analysis job** to RabbitMQ.
6. The **AI worker** consumes the job, fetches the video from MinIO, runs MediaPipe, and publishes the JSON result back via RabbitMQ.
7. The backend **receives the result**, stores it in PostgreSQL, and makes it available via API.
8. The mobile app **polls or retrieves the result** and displays the skeleton overlay or feedback.

---

## 4. Development Environment

### 4.1 Global Environment

All development happens in a **UNIX-based environment**. Windows is not supported. The monorepo is managed with **[moonrepo](https://moonrepo.dev)**, which centralizes task execution, toolchain version pinning, and CI pipelines across all services.

Infrastructure services (PostgreSQL, RabbitMQ, MinIO) are orchestrated locally via **Docker Compose**.

### 4.2 Team Setup

| Developer            | OS         | Target Platforms | Role                       |
| -------------------- | ---------- | ---------------- | -------------------------- |
| Christophe VANDEVOIR | MacOS      | iOS              | Mobile (Flutter)           |
| Gianni TUERO         | Arch Linux | Android          | RabbitMQ integration       |
| Lou PELLEGRINO       | NixOS      | iOS              | Backend (Rust/Axum, init)  |
| Nicolas TORO         | Arch Linux | Android          | Project, then Rust support |
| Olivier POUECH       | Arch Linux | iOS              | AI (MediaPipe pipeline)    |

### 4.3 Toolchain & Versions

All toolchain versions are pinned in `.moon/toolchain.yml` and must be used consistently across all machines.

#### Task Runner — moon

| Tool     | Version | Install                                                   |
| -------- | ------- | --------------------------------------------------------- |
| moonrepo | latest  | `curl -fsSL https://moonrepo.dev/install/moon.sh \| bash` |

#### Backend — Rust

| Tool / Crate   | Version  | Notes                             |
| -------------- | -------- | --------------------------------- |
| Rust toolchain | `1.93.1` | Pinned via `.moon/toolchain.yml`  |
| Edition        | `2024`   | `Cargo.toml`                      |
| axum           | `0.8.8`  | HTTP framework                    |
| tokio          | `1.49.0` | Async runtime (`features = full`) |
| dotenv         | `0.15.0` | Environment variable loading      |

#### AI — Python

| Tool / Package | Version   | Notes                             |
| -------------- | --------- | --------------------------------- |
| Python         | `3.14.2`  | Pinned via `.moon/toolchain.yml`  |
| ruff           | latest    | Linter & formatter                |
| pytest         | latest    | Test runner                       |
| build          | latest    | Package builder                   |
| mediapipe      | TBD       | Pose estimation (33 keypoints)    |
| opencv-python  | TBD       | Computer vision / video decoding  |
| pika           | TBD       | RabbitMQ client (AMQP)            |

> **Note:** `mediapipe`, `opencv-python`, and `pika` are to be added to `requirements.txt` during the sprint as they are the core prototype dependencies.

#### Mobile — Flutter / Dart

| Tool            | Version   | Notes                     |
| --------------- | --------- | ------------------------- |
| Flutter SDK     | `≥ 3.x`   | Channel: stable           |
| Dart SDK        | `^3.11.0` | Defined in `pubspec.yaml` |
| cupertino_icons | `^1.0.8`  | iOS-style icons           |
| flutter_lints   | `^6.0.0`  | Lint rules                |

> **Note:** Additional packages (HTTP client, video picker, etc.) will be added to `pubspec.yaml` during the sprint.

#### Infrastructure — Docker & Services

| Service        | Image          | Version | Ports            |
| -------------- | -------------- | ------- | ---------------- |
| Docker         | Docker Engine  | ≥ 24.x  | —                |
| Docker Compose | Compose plugin | ≥ 2.x   | —                |
| PostgreSQL     | `postgres`     | latest  | `5432`           |
| RabbitMQ       | `rabbitmq`     | latest  | `5672` / `15672` |
| MinIO          | `minio/minio`  | latest  | `9000` / `9001`  |

### 4.4 Development Workflow

```bash
# 1. Clone the repository
git clone git@github.com:Ascension-EIP/Ascension.git
cd Ascension

# 2. Install moon
curl -fsSL https://moonrepo.dev/install/moon.sh | bash

# 3. Copy environment file
cp .env.example .env
# Edit .env with your local values

# 4. Start infrastructure services
docker compose up -d

# 5. Run a service
moon run server:dev    # Rust API
moon run ai:dev        # Python AI worker
moon run mobile:dev    # Flutter app

# 6. Run all tests
moon run :test

# 7. Run tests on affected projects only (recommended in CI)
moon run :test --affected
```

---

## 5. Task Assignment

| Developer            | Task                                                                               |
| -------------------- | ---------------------------------------------------------------------------------- |
| Olivier POUECH       | AI pipeline using MediaPipe — skeleton extraction from video                       |
| Christophe VANDEVOIR | Mobile Flutter UI — video upload + analysis trigger                                |
| Gianni TUERO         | RabbitMQ link between backend and AI worker                                        |
| Lou PELLEGRINO       | Backend init (Rust/Axum) — first routes + PostgreSQL schema                        |
| Nicolas TORO         | Project management (GitHub Projects, milestones, tasks), then joins Lou on Backend |

---

## 6. Key Milestones

| Milestone       | Day       | Deliverable                                                                                                    |
| --------------- | --------- | -------------------------------------------------------------------------------------------------------------- |
| Definition      | Tuesday   | GitHub Project up to date, milestone created, tasks assigned, environment defined, material requests submitted |
| Sprint start    | Thursday  | User journey started — first integration between services demonstrable                                         |
| Demo checkpoint | Monday    | End-to-end user journey demonstrable (upload → analysis → result display)                                    |
| Finalization    | Wednesday | Prototype finalized, edge cases handled, documentation updated                                                 |
| Presentation    | Friday    | 15-minute public pitch with live demo                                                                          |

---

## 7. Material Request

The following resources are required or desirable to carry out this prototype sprint in optimal conditions.

### 7.1 Cloud Infrastructure (Hetzner)

Our infrastructure is hosted on **Hetzner Cloud** (Germany), chosen for its price-to-performance ratio and GDPR compliance (biometric data stored in the EU). The following VPS instances are needed for the prototype environment:

| Machine        | Role                              | Spec (Hetzner)        | Storage     | Est. Cost    |
| -------------- | --------------------------------- | --------------------- | ----------- | ------------ |
| **Srv-API**    | Rust/Axum API + Nginx             | CX31 — 4 vCPU / 8 GB  | 80 GB SSD   | ~€15/month   |
| **Srv-DB**     | PostgreSQL + RabbitMQ + MinIO     | CX41 — 4 vCPU / 16 GB | 500 GB NVMe | ~€25/month   |
| **Srv-ML**     | Python AI Workers (MediaPipe)     | CX51 — 8 vCPU / 16 GB | 100 GB SSD  | ~€40/month   |

> **Total estimated:** ~€80/month for the prototype duration (2 weeks ≈ ~€40 prorated).

> **Note on Srv-ML:** MediaPipe and OpenCV video inference is CPU-intensive. The CX51 (8 vCPU) is the minimum viable configuration for processing climbing videos in a reasonable time during the demo. A GPU-enabled instance would be ideal but is not strictly required for the prototype.

### 7.2 Physical Test Devices

| Device                  | Quantity | Priority | Justification                                                                  |
| ----------------------- | -------- | -------- | ------------------------------------------------------------------------------ |
| Android device          | 1        | Medium   | Real hardware testing — emulator does not reflect real-world performance       |
| iOS device              | 1        | Medium   | Real hardware testing — Simulator does not cover all edge cases (camera, etc.) |
