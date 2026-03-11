> **Last updated:** 9th March 2026  
> **Version:** 1.0  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Mobile — Developer Guide

This guide covers the architecture, screens, navigation, and API integration of the
Ascension Flutter mobile application. No prior Flutter or Dart knowledge is assumed —
everything is explained from scratch.

---

## Table of Contents

- [Mobile — Developer Guide](#mobile--developer-guide)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Tech Stack](#tech-stack)
  - [Repository Layout](#repository-layout)
  - [Running Locally](#running-locally)
    - [Moon Tasks Reference](#moon-tasks-reference)
  - [App Architecture](#app-architecture)
    - [Feature-First Folder Structure](#feature-first-folder-structure)
    - [Shared Layer](#shared-layer)
    - [Core Layer](#core-layer)
  - [Navigation](#navigation)
  - [Screens](#screens)
    - [Home](#home)
    - [Upload](#upload)
    - [Stats](#stats)
    - [Profile](#profile)
    - [Analysis Result](#analysis-result)
  - [API Integration](#api-integration)
    - [ApiService — Singleton](#apiservice--singleton)
    - [Backend URL Configuration](#backend-url-configuration)
    - [Available API Calls](#available-api-calls)
  - [Video Upload Flow](#video-upload-flow)
  - [Theme](#theme)
  - [Environment Variables](#environment-variables)
  - [Testing](#testing)
  - [Common Errors](#common-errors)

---

## Prerequisites

- **Flutter SDK** ≥ 3.11 (Dart ≥ 3.11)
- **Android Studio** or **Xcode** (for device emulators)
- `flutter doctor` must show no critical errors

Install Flutter by following the [official guide](https://docs.flutter.dev/get-started/install).

---

## Tech Stack

| Package              | Version | Role                                         |
|----------------------|---------|----------------------------------------------|
| **Flutter**          | stable  | UI framework                                 |
| `image_picker`       | ^1.1.2  | Pick videos from gallery or camera           |
| `video_player`       | ^2.9.3  | Preview selected videos inline               |
| `http`               | ^1.2.0  | HTTP client for the Rust API                 |
| `fl_chart`           | ^0.69.0 | Charts for biomechanics data (angle graphs)  |
| `shared_preferences` | ^2.3.0  | Persists the backend URL across app restarts |
| `equatable`          | ^2.0.8  | Value equality for state objects             |

---

## Repository Layout

```
apps/mobile/
├── pubspec.yaml              # Flutter package + dependencies
├── moon.yml                  # moon task definitions
├── lib/
│   ├── main.dart             # App entry point
│   ├── core/
│   │   ├── constants/        # AppConstants (backend URL, storage keys)
│   │   ├── error/            # Shared error types
│   │   └── network/
│   │       └── api_service.dart  # Singleton HTTP client for the Rust API
│   ├── features/
│   │   ├── auth/             # Login & Register pages (UI only, auth not wired)
│   │   ├── home/             # Home screen
│   │   ├── upload/           # Upload page + Analysis result page
│   │   ├── stats/            # Stats screen
│   │   └── profile/          # Profile screen
│   └── shared/
│       ├── components/       # Reusable widgets (Header, VideoUpload, …)
│       ├── layout/           # MobileLayout — bottom nav bar shell
│       └── theme/            # AppTheme (dark theme)
├── assets/
│   └── images/               # Static image assets
├── android/                  # Android-specific config
├── ios/                      # iOS-specific config
└── test/                     # Unit & widget tests
```

---

## Running Locally

Make sure the backend is running first (see the [server guide](../server/README.md)).

```bash
# Install dependencies
moon run mobile:install

# Run on a connected device / emulator
moon run mobile:dev

# Run tests
moon run mobile:test

# Lint
moon run mobile:lint
```

### Moon Tasks Reference

| Task            | Description                                                                                |
|-----------------|--------------------------------------------------------------------------------------------|
| `install`       | `flutter pub get` — installs all packages                                                  |
| `dev`           | `flutter run` with `BACKEND_URL` injected                                                  |
| `build`         | Auto-detects platform (Android by default, iOS on macOS) or reads `BUILD_PLATFORM` env var |
| `build-android` | `flutter build apk`                                                                        |
| `build-ios`     | `flutter build ios --no-codesign`                                                          |
| `test`          | `flutter test`                                                                             |
| `lint`          | `flutter analyze`                                                                          |
| `format`        | `dart format --set-exit-if-changed .`                                                      |

**Platform auto-detection for `moon run mobile:build`:**

1. If `BUILD_PLATFORM=ios` → builds iOS.
2. If `BUILD_PLATFORM=android` → builds Android APK.
3. If `BUILD_PLATFORM` is not set → iOS on macOS, Android everywhere else.

---

## App Architecture

The app follows a **feature-first** folder structure.
Each feature is self-contained and only the `shared/` and `core/` directories are shared
across features.

The app currently uses `StatefulWidget` + `setState` for local state management.
There is no global state manager (no BLoC, Provider, or Riverpod) yet — this is
intentional for the current scope.

### Feature-First Folder Structure

Each feature under `lib/features/<name>/` follows this layout:

```
features/<name>/
└── presentation/
    └── pages/
        └── <name>_page.dart    # The screen widget
```

As features grow, a feature folder may also contain:

```
features/<name>/
├── data/           # Repository implementations, DTOs
├── domain/         # Entities, use cases, repository interfaces
└── presentation/
    ├── pages/      # Screen widgets
    ├── widgets/    # Feature-specific sub-widgets
    └── bloc/       # State management (when added)
```

### Shared Layer

`lib/shared/` contains widgets and styles that are used across multiple features:

| Path                                  | Description                                                |
|---------------------------------------|------------------------------------------------------------|
| `shared/layout/mobile_layout.dart`    | The root shell — bottom navigation bar + `IndexedStack`    |
| `shared/components/header.dart`       | Reusable `AppBar`-like header with a title and description |
| `shared/components/video_upload.dart` | Full upload widget (pick → upload → analyse → display)     |
| `shared/theme/app_theme.dart`         | Global dark `ThemeData`                                    |

### Core Layer

`lib/core/` contains cross-cutting infrastructure:

| Path                                | Description                                           |
|-------------------------------------|-------------------------------------------------------|
| `core/network/api_service.dart`     | Singleton HTTP client — all API calls go through here |
| `core/constants/app_constants.dart` | Backend URL logic, storage keys                       |

---

## Navigation

The app uses a **bottom navigation bar** (`MobileLayout`) as the root shell.
It holds four tabs in an `IndexedStack`, meaning all pages are kept in memory
and switching tabs is instant (no rebuilds).

| Tab index | Page          | Icon      |
|-----------|---------------|-----------|
| 0         | `HomePage`    | 🏠 House  |
| 1         | `UploadPage`  | ☁️ Upload |
| 2         | `StatsPage`   | 📊 Graph  |
| 3         | `ProfilePage` | 👤 Person |

The `AnalysisPage` (analysis result) is **not** in the bottom nav — it is pushed
on top of `UploadPage` using `Navigator.push` after an analysis completes.

---

## Screens

### Home

**File:** `lib/features/home/presentation/pages/home_page.dart`

Landing screen. Currently a placeholder — will show a dashboard / recent sessions.

---

### Upload

**File:** `lib/features/upload/presentation/pages/upload_page.dart`

The upload screen wraps the `VideoUpload` component (in `shared/components/`).

**What `VideoUpload` does:**

1. User picks a video from gallery or camera (`image_picker`).
2. Video is previewed inline with `video_player`.
3. User taps **Upload** — the component runs the full upload + analysis flow:

```
Pick video
  → GET presigned URL from server (POST /v1/videos/upload-url)
  → PUT video bytes directly to MinIO
  → POST /v1/analyses  (trigger analysis)
  → Poll GET /v1/analyses/{id} every 5 s until status = completed / failed
  → Navigate to AnalysisPage with result data
```

States visible to the user:

| `_UploadState` | UI shown                              |
|----------------|---------------------------------------|
| `idle`         | "Pick a video" buttons                |
| `selected`     | Video preview + Upload button         |
| `uploading`    | Progress indicator (0–60 %)           |
| `analysing`    | Spinner "Analysing…"                  |
| `done`         | Success — navigates to `AnalysisPage` |
| `error`        | Error message with retry button       |

> **Note:** `user_id` is currently hard-coded as `00000000-0000-0000-0000-000000000001`.
> This will be replaced by the authenticated user ID once the auth flow is wired.

---

### Stats

**File:** `lib/features/stats/presentation/pages/stats_page.dart`

Placeholder screen for historical session statistics.

---

### Profile

**File:** `lib/features/profile/presentation/pages/profile_page.dart`

Placeholder screen for user profile management.

---

### Analysis Result

**File:** `lib/features/upload/presentation/pages/analysis_page.dart`

Displayed after a successful analysis. This is the most complex page in the app.

It parses the `result_json` returned by `GET /v1/analyses/{id}` and renders:

**1. Skeleton overlay player**

A frame-by-frame skeleton overlay drawn on a `CustomPaint` canvas.
The user can scrub through frames with a slider. The skeleton connects 12
landmarks using the same `_LM.connections` list as `pose_analysis.py`.

**2. Angle charts**

Line charts (`fl_chart`) showing joint angles over time (currently left elbow at
landmark index 13). One chart is shown per tracked joint.

**3. Landmark table**

For the selected frame: a table of all detected landmarks with their
normalised `(x, y)` coordinates and presence score.

**Landmark constants in the app** (mirror `pose_analysis.py`):

| Const       | Index | Joint          |
|-------------|-------|----------------|
| `lShoulder` | 11    | Left shoulder  |
| `rShoulder` | 12    | Right shoulder |
| `lElbow`    | 13    | Left elbow     |
| `rElbow`    | 14    | Right elbow    |
| `lWrist`    | 15    | Left wrist     |
| `rWrist`    | 16    | Right wrist    |
| `lHip`      | 23    | Left hip       |
| `rHip`      | 24    | Right hip      |
| `lKnee`     | 25    | Left knee      |
| `rKnee`     | 26    | Right knee     |
| `lAnkle`    | 27    | Left ankle     |
| `rAnkle`    | 28    | Right ankle    |

---

## API Integration

### ApiService — Singleton

All HTTP calls to the Rust backend go through `ApiService` (`lib/core/network/api_service.dart`).
It is a Dart singleton — call `ApiService()` from anywhere to get the same instance.

```dart
final api = ApiService(); // always the same instance
```

### Backend URL Configuration

The backend URL is resolved at runtime in this priority order:

1. **Persisted URL** — if the user has previously saved a custom URL via
   `ApiService().setBaseUrl(url)`, that value is loaded from `SharedPreferences`.
2. **Build-time constant** — if `BACKEND_URL` is set via `--dart-define`, it is used.
3. **Auto-detected default:**
   - Linux / macOS / Windows desktop → `http://localhost:8080`
   - Android emulator → `http://10.0.2.2:8080` (the loopback alias to the host machine)

### Available API Calls

| Method                                | Description                          | Server endpoint              |
|---------------------------------------|--------------------------------------|------------------------------|
| `getUploadUrl(filename, userId)`      | Get presigned MinIO PUT URL          | `POST /v1/videos/upload-url` |
| `uploadToMinio(uploadUrl, fileBytes)` | Upload video bytes directly to MinIO | `PUT <presigned-url>`        |
| `triggerAnalysis(videoId)`            | Start a pose-analysis job            | `POST /v1/analyses`          |
| `getAnalysis(analysisId)`             | Poll analysis status & result        | `GET /v1/analyses/{id}`      |

All methods throw an `Exception` on non-2xx responses.

---

## Video Upload Flow

```
┌──────────────────────────────────────────────────────────────────┐
│  Flutter app (VideoUpload widget)                                │
│                                                                  │
│  1. image_picker  →  File on disk                                │
│                                                                  │
│  2. POST /v1/videos/upload-url  →  { video_id, upload_url }      │
│                                                                  │
│  3. PUT <upload_url> (bytes)    →  MinIO (direct, no proxy)      │
│                                                                  │
│  4. POST /v1/analyses           →  { analysis_id, job_id }       │
│                                                                  │
│  5. Poll GET /v1/analyses/{id}  (every 5 s, max 10 min)          │
│     status: pending → processing → completed                     │
│                                                                  │
│  6. Navigate to AnalysisPage with result_json                    │
└──────────────────────────────────────────────────────────────────┘
```

The video is **never proxied through the Rust server**. It goes directly from the device
to MinIO using the presigned URL. The Rust server only creates the database record and
returns the URL.

---

## Theme

The app uses a single dark theme defined in `lib/shared/theme/app_theme.dart`.
`AppTheme.dark` is applied to both `theme` and `darkTheme` in `MaterialApp`,
so the app is always in dark mode regardless of system settings.

---

## Environment Variables

| Variable         | How it is set                                      | Description                                           |
|------------------|----------------------------------------------------|-------------------------------------------------------|
| `BACKEND_URL`    | `--dart-define=BACKEND_URL=http://...`             | Overrides the auto-detected backend URL at build time |
| `BUILD_PLATFORM` | Shell env var when running `moon run mobile:build` | `ios` or `android` — forces the target platform       |

---

## Testing

Tests live in `apps/mobile/test/`. Run them with:

```bash
moon run mobile:test
# or
flutter test
```

Currently the test suite uses Flutter's standard `flutter_test` framework.
Widget tests can be written using `testWidgets(...)`.

---

## Common Errors

| Error                                    | Likely cause                                 | Fix                                                                    |
|------------------------------------------|----------------------------------------------|------------------------------------------------------------------------|
| `Connection refused`                     | Backend not running                          | `docker compose up -d` then `moon run server:dev`                      |
| `[get upload URL] HTTP 500`              | MinIO not reachable from server              | Check `MINIO_ENDPOINT` in `.env`                                       |
| `image_picker` returns null              | User cancelled picker or permission denied   | Handle `null` return, check permissions on device                      |
| Video preview not shown on Linux/Windows | `video_player` only supports Android/iOS/Web | Expected — preview is skipped on unsupported platforms                 |
| Analysis stuck at `pending`              | AI worker not running                        | Run `moon run ai:dev` or start with `docker compose --profile prod up` |
| Analysis `failed` immediately            | Stale failed status from previous attempt    | The app waits at least 30 s before accepting `failed` to handle this   |
