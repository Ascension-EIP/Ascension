:::warning
**Version:** 1.3
:::

---

# Ascension AI worker

Python worker of the Ascension monorepo. It turns a climbing video into a 2D analysis (skeleton, joint angles, metrics, movements) and then into coaching hints written by an LLM. It also detects the holds of a route photo (contour, hold or volume, dominant colour), estimates the plane of the wall from that photo, and computes the pathfinding of a climber on a route (beta found by an A* search, then one posture per step). The pathfinding is the computation; the ghost is the Ghost Mode feature that shows its result, and the `pathfindings` table is where the job and its result are stored.

The worker consumes jobs from RabbitMQ, downloads the video or the photo from RustFS (S3), writes its progress and results into PostgreSQL, and publishes statuses back on RabbitMQ. Each pipeline step is also a command line sub-command, so it can run without any infrastructure.

This README describes the code as it is today. The pathfinding (wall plane, beta, postures) is implemented and was run with the real models on one route photo, with an unmeasured metric scale (see [Pathfinding](#pathfinding) and [Known limits](#known-limits)). Route grouping, the server and mobile parts of Ghost Mode, and 3D are not implemented: see [pipeline-2d-decomposition.md](../../docs/Ascension/developer/apps/ai/pipeline-2d-decomposition/readme.md).

---

## Table of Contents

- [Pipeline](#pipeline)
- [Installation](#installation)
- [Environment variables](#environment-variables)
- [Running the worker](#running-the-worker)
- [Command line steps](#command-line-steps)
- [Pathfinding](#pathfinding)
- [Triggering a job by hand](#triggering-a-job-by-hand)
- [Tests](#tests)
- [Project layout](#project-layout)
- [Shared schemas](#shared-schemas)
- [Known limits](#known-limits)

---

## Pipeline

```mermaid
flowchart LR
    Producer["Go server or producer.py"] -->|"pose.detect.requested"| Detect["queue poses.detect"]
    Detect --> S3["RustFS"]
    Detect --> Steps["_1_mediapipe"]
    Steps --> DB[("analyses")]
    Server["Go server (POST /advices/:id)"] -->|"pose.advice.requested"| Advice["queue poses.advice"]
    Advice --> DB
    Advice --> LLM["_2_advice + LLM"]
    LLM --> ADV[("advices")]
    Detect -.->|"pose.detect.status"| Events["Status consumers"]
    Advice -.->|"pose.advice.status"| Events
    RouteServer["Go server or producer.py"] -->|"holds.detect.requested"| Holds["queue holds.detect"]
    Holds --> S3
    Holds --> HoldSteps["_3_holds (ONNX)"]
    HoldSteps --> HDB[("routes, holds")]
    Holds -.->|"holds.detect.status"| Events
    HoldSteps --> Wall["_4_pathfinding wall plane"]
    Wall --> HDB
    PathServer["Go server or producer.py"] -->|"pathfinding.compute.requested"| PathQueue["queue pathfinding.compute"]
    PathQueue --> PathSteps["_4_pathfinding beta and postures"]
    HDB --> PathSteps
    PathSteps --> GDB[("pathfindings.result")]
    PathQueue -.->|"pathfinding.compute.status"| Events
```

_Summary: the detect job downloads the video, computes the result, stores it in `analyses` and ends the analysis. The advice job is independent: the server requests it for a video, the worker reads the `result` of the latest successful analysis of that video, and stores the hints in `advices.result`. The hold job downloads a route photo, detects its holds, estimates the wall plane (depth model, then plane fit) and stores one `holds` row per hold plus `routes.wall_plane`. The pathfinding job reads a `pending` pathfinding, its route and the holds of the route, searches the beta, computes the posture of each step and stores `pathfindings.result`. All four publish their statuses._

| Item           | Value                                                                                                                                                                                                                                                                                                            |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Exchange       | `events` (topic, durable)                                                                                                                                                                                                                                                                                        |
| Queues         | `poses.detect`, `poses.advice`, `holds.detect`, `pathfinding.compute`, plus a dead-letter queue `<queue>.dlq` bound to the exchange `events.dlx`                                                                                                                                                                 |
| Consumed keys  | `pose.detect.requested` (payload `{job_id, object_key}`), `pose.advice.requested` (payload `{job_id}`, the video id), `holds.detect.requested` (payload `{job_id, object_key, gravity?}`, `job_id` is the route id), `pathfinding.compute.requested` (payload `{job_id, preference?}`, `job_id` is the pathfinding id) |
| Published keys | `pose.detect.status`, `pose.advice.status`, `holds.detect.status`, `pathfinding.compute.status`                                                                                                                                                                                                                  |
| Statuses       | `pending`, `started`, `running`, `success`, `failed` (messages and the `status` column of `analyses`, `advices`, `routes` and `pathfindings`)                                                                                                                                                                          |
| Concurrency    | One job at a time per process. Scale by adding replicas                                                                                                                                                                                                                                                          |

Job lifecycle in `analyses`:

| Step                | `status`  | `progress` |
| ------------------- | --------- | ---------- |
| Job taken           | `started` | 0          |
| Skeleton extraction | `running` | 5 to 70    |
| Movements computed  | `running` | 80         |
| `result` stored     | `running` | 85         |
| Done                | `success` | 100        |

Job lifecycle in `advices` (`advices.id` is the video id, the row is created by the server):

| Step                 | `status`  | `progress` |
| -------------------- | --------- | ---------- |
| Job taken            | `started` | 0          |
| Advice generation    | `running` | 90         |
| `result` (hints) set | `success` | 100        |

Job lifecycle in `routes` (`routes.id` is the job id; the server creates the route in `pending` before publishing):

| Step                              | `status`  | `progress` |
| --------------------------------- | --------- | ---------- |
| Job taken                         | `started` | 0          |
| Photo download and detection      | `running` | 10         |
| Holds stored, real photo size set | `running` | 90         |
| Done                              | `success` | 100        |

The wall plane is computed after the detection, inside the `running` phase. It never fails the job: without the depth model, or when no plane is found, the holds are stored and `routes.wall_plane` stays empty (a warning is logged). A malformed `gravity` is the one exception: the job fails with `Invalid gravity` before any processing.

Job lifecycle of the pathfinding, written in `pathfindings` (`pathfindings.id` is the job id; the server creates the `pathfindings` row in `pending` before publishing):

| Step               | `status`  | `progress` |
| ------------------ | --------- | ---------- |
| Job taken          | `started` | 0          |
| Row taken          | `running` | 10         |
| Row and holds read | `running` | 30         |
| `path` stored      | `success` | 100        |

Each detected hold becomes one `holds` row with `source = 'ai'`: `type` and `predicted_type` are `unknown` or `volume` (the model does not classify grips yet), `contour` and `predicted_contour` follow the `{"points": [...], "bbox": {...}}` format, and `color` and `predicted_color` hold `{"name", "rgb", "distance"}`. A redelivered job replaces the AI holds the user has not corrected, so it never duplicates holds nor loses a correction. The photo size (`image_width`, `image_height`) is written by the worker: the server can create the route with 0.

If the LLM fails or is not configured, only the advice ends in `failed` with a short `error` (the analysis is untouched), and `pose.advice.status` is `failed`. The server relaunches it with `pose.advice.requested` (`POST /advices/:id/retry`).

Temporary errors (storage, database, LLM) are retried three times with an in-memory backoff (2 s, then 4 s). After that, or on a permanent error (invalid payload, unreadable video), the job is published as `failed` and the message goes to `<queue>.dlq`. Error messages stored in the database and in statuses are short; the traceback stays in the logs.

---

## Installation

Requirements: Python 3.11, [uv](https://docs.astral.sh/uv/), [moon](https://moonrepo.dev) for the monorepo tasks, and Docker for the infrastructure (PostgreSQL, RabbitMQ, RustFS).

```bash
# From the repository root
moon run ai:install   # uv sync
moon run ai:setup     # downloads resources/pose_landmarker_full.task and resources/moge-2-vits-normal.onnx if missing

# Or by hand
cd apps/ai
uv sync
bash scripts/download-model.sh
bash scripts/download-depth-model.sh
```

`download-depth-model.sh` fetches the metric depth model of the pathfinding (MoGe-2 ViT-S, ONNX, MIT licence, 141 MB on disk) from Hugging Face without a token, checks its SHA-256 and skips the download when the file exists. The file is not versioned. The `Dockerfile` runs the script, so the image build needs access to Hugging Face.

If `import cv2` fails with `has no attribute 'VideoCapture'`, run `uv sync --reinstall-package opencv-contrib-python`.

---

## Environment variables

The worker reads the `.env` file at the repository root (copy `.env.example`). Docker Compose passes it to the `ai-worker` container.

| Variable                                                                              | Default                                                    | Role                                                                                                |
| ------------------------------------------------------------------------------------- | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `POSTGRES_DB_URL`                                                                     | none                                                       | Full database URL. When unset, the URL is built from the `POSTGRES_*` variables below               |
| `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | `localhost`, `5432`, `ascension`, `ascension`, `ascension` | Database connection                                                                                 |
| `RABBITMQ_HOST`, `RABBITMQ_PORT`                                                      | `localhost`, `5672`                                        | Broker address                                                                                      |
| `RABBITMQ_USER`, `RABBITMQ_PASS`                                                      | none                                                       | Broker credentials. `RABBITMQ_DEFAULT_USER` and `RABBITMQ_DEFAULT_PASS` take precedence when set    |
| `RABBITMQ_RETRY_DELAY`, `RABBITMQ_MAX_RETRIES`                                        | `5`, `12`                                                  | Connection retries at startup (seconds, count)                                                      |
| `RUSTFS_ENDPOINT`                                                                     | `http://localhost:9000`                                    | S3 endpoint                                                                                         |
| `RUSTFS_ACCESS_KEY`, `RUSTFS_SECRET_KEY`                                              | `ascension`, `ascension`                                   | S3 credentials                                                                                      |
| `RUSTFS_BUCKET`                                                                       | `videos`                                                   | Bucket that holds the videos. The worker never creates it                                           |
| `LLM_BASE_URL`                                                                        | none                                                       | Base URL of any OpenAI-compatible API                                                               |
| `LLM_API_KEY`                                                                         | empty                                                      | API key (optional for a local server)                                                               |
| `LLM_MODEL`                                                                           | none                                                       | Model name                                                                                          |
| `POSE_MODEL_PATH`                                                                     | `resources/pose_landmarker_full.task`                      | MediaPipe model, relative to `apps/ai`                                                              |
| `HOLDS_MODEL_PATH`                                                                    | `resources/holds_seg.onnx`                                 | Hold segmentation model (ONNX), relative to `apps/ai`. Written by `moon run holds:export`           |
| `DEPTH_MODEL_PATH`                                                                    | `resources/moge-2-vits-normal.onnx`                        | Metric depth model (ONNX) of the pathfinding, relative to `apps/ai`. Written by `moon run ai:setup` |
| `TEST_POSTGRES_URL`                                                                   | none                                                       | Database used by the integration and end-to-end tests. See [Tests](#tests)                          |

Without `LLM_BASE_URL` or `LLM_MODEL` the worker still starts: advices end in `failed` (the analyses are not affected).

To change the model, change only the three `LLM_*` variables. There is one client for every provider.

| Provider | `LLM_BASE_URL`                                             | `LLM_MODEL`             |
| -------- | ---------------------------------------------------------- | ----------------------- |
| Gemini   | `https://generativelanguage.googleapis.com/v1beta/openai/` | `gemini-3.5-flash-lite` |
| DeepSeek | `https://api.deepseek.com`                                 | `deepseek-flash`        |

> **Not tested with a real provider.** Every test uses a simulated client. The values above come from the providers' documentation and the model names must be checked against their catalogue. Gemini's page for the OpenAI-compatible API does not mention `response_format={"type": "json_object"}`: confirm it with a real key. Choosing a provider also has GDPR consequences: biomechanical data (no identifier, no video) leaves for a third party.

`GEMINI_API_KEY` and `GEMINI_MODEL` stay in `.env.example` because the scripts in `.github/scripts` (commit message and PR review tooling) still read them. The worker does not.

The Go server still reads the `MINIO_*` variable names. Their values must stay equal to the `RUSTFS_*` ones.

---

## Running the worker

Start the infrastructure, apply the migrations, then run the worker.

```bash
moon run root:db-up        # PostgreSQL, RabbitMQ and RustFS
moon run server:migrate    # includes the job_status, advices, hold detection and pathfinding migrations
moon run ai:dev            # uv run worker, loads .env
```

Equivalent without moon: `cd apps/ai && uv run worker`.

Without a sub-command the worker connects to PostgreSQL, RustFS and RabbitMQ, then blocks on consumption. It exits with code 1 and a short message when a connection fails. The migrations must be applied first.

The bucket `videos` must exist. The Go server creates it at startup; `producer.py seed` creates it too.

The hold model is loaded on the first hold job, not at startup: without `resources/holds_seg.onnx` the worker still runs pose jobs, and hold jobs end in `failed` with `Hold model unavailable`. The depth model is loaded on the first wall estimation: without `resources/moge-2-vits-normal.onnx` hold jobs still end in `success` (without wall plane) and the pathfinding jobs of such routes fail with `Wall geometry missing`.

Queues created by an older version have no dead-letter arguments and are refused by RabbitMQ (`PRECONDITION_FAILED`). Delete `poses.detect` and `poses.advice` in the management interface, without touching the volumes. The worker recreates them.

---

## Command line steps

Every step runs on its own: no RabbitMQ, no database, no storage. The output of each pose step is validated against `AnalysisResult` before it is written, the output of `holds-detect` against `HoldDetectResult`, the output of `pathfinding-pose` and `pathfinding` against `PathfindingResult`.

| Command                           | Input                                                   | Output                                                     | Main options (defaults)                                                                                                              |
| --------------------------------- | ------------------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `uv run worker holds-detect`      | `--image`                                               | `--out` holds JSON (contour, type, colour)                 | `--render` writes the photo with every hold drawn in its colour, `--conf` (0.10), `--model`                                          |
| `uv run worker holds-colors-eval` | `--dataset`                                             | Colour name accuracy, per colour                           | `--splits` (`val test`). The dataset is the output of `holds merge` (apps/ai/training/holds)                                         |
| `uv run worker pathfinding-depth` | `--image`                                               | `--out` depth map `.npy` (metres, `NaN` where invalid)     | `--render` writes a coloured picture of the depth map. Prints the focal length, the median depth and the share of valid pixels       |
| `uv run worker pathfinding-wall`  | `--image`                                               | `--out` holds JSON plus the `wall` plane                   | `--holds` (a `holds-detect` output, its `start_limbs` and `finish_limbs` marks are kept; default: detect them), `--gravity GX GY GZ` |
| `uv run worker pathfinding-beta`  | `--input` (`pathfinding-wall` output)                   | `--out` beta JSON (hold under each limb at each step)      | Climber options below                                                                                                                |
| `uv run worker pathfinding-pose`  | `--input` (beta), `--holds` (`pathfinding-wall` output) | `--out` `PathfindingResult` JSON                           | `--render` with `--image` writes the photo with the skeletons drawn                                                                  |
| `uv run worker pathfinding`       | `--image`                                               | `--out` `PathfindingResult` JSON (the three steps chained) | `--render`, `--holds`, `--gravity` and the climber options below                                                                     |
| `uv run worker depth-eval`        | `--dataset`                                             | Relative error of the 3D distances, per image and overall  | Folder with the photos and `annotations.json`, see [Pathfinding](#pathfinding)                                                       |
| `uv run worker pose-skeleton`     | `--video`                                               | `--out` raw skeleton JSON                                  | `--render` writes a video with the skeleton drawn                                                                                    |
| `uv run worker pose-filter`       | `--input`                                               | `--out` filtered JSON                                      | `--min-visibility` (0.5), `--max-gap` (5 frames), `--window` (5 frames)                                                              |
| `uv run worker pose-metrics`      | `--input`                                               | `--out` JSON with speeds and metrics                       | `--bent-arm` (0.8)                                                                                                                   |
| `uv run worker pose-movements`    | `--input`                                               | `--out` JSON with movements and pauses                     | `--move-speed` (0.8), `--stop-speed` (0.4), `--merge-gap` (150 ms), `--min-move` (100 ms), `--min-pause` (500 ms)                    |
| `uv run worker pose-detect`       | `--video`                                               | `--out` full result (all four steps chained)               | `--render`                                                                                                                           |
| `uv run worker pose-advice`       | `--input` (a result)                                    | `--out` hints JSON                                         | `--dry-run` writes the prompt only (no key, no network), `--model`, `--base-url`                                                     |

Speeds are in torso lengths per second.

```bash
cd apps/ai
uv run worker pose-detect --video resources/example-2.mp4 --out /tmp/result.json
uv run worker pose-advice --input /tmp/result.json --out /tmp/prompt.txt --dry-run

# Or chain the steps one by one
uv run worker pose-skeleton  --video resources/example-2.mp4 --out /tmp/skeleton.json
uv run worker pose-filter    --input /tmp/skeleton.json --out /tmp/filtered.json
uv run worker pose-metrics   --input /tmp/filtered.json --out /tmp/metrics.json
uv run worker pose-movements --input /tmp/metrics.json --out /tmp/movements.json
```

The same task exists in moon: `moon run ai:pose-detect -- --video resources/example-2.mp4 --out /tmp/result.json`.

The thresholds are named constants in `src/worker/_1_mediapipe/` and can be overridden on the command line. See [Known limits](#known-limits) before trusting them.

```bash
uv run worker holds-detect --image path/to/wall.jpg --out /tmp/holds.json --render /tmp/holds.jpg
uv run worker holds-colors-eval --dataset training/holds/datasets/holds
```

The hold model is trained in [training/holds](training/holds/README.md) (its own environment, ignored by the worker tests, lint and image) and exported to `resources/holds_seg.onnx` with `moon run holds:export`. The worker runs it with ONNX Runtime on the CPU (no PyTorch): detection took 0.7 s per photo (median, at most 1 s) on the 11 test photos of training/holds, measured on a laptop CPU.

The pathfinding steps chain on their own, like the pose steps. The three computation steps share the climber options below; `pathfinding` runs `pathfinding-wall`, `pathfinding-beta` and `pathfinding-pose` in one go, and is equal to chaining them.

| Option (`pathfinding-beta` and `pathfinding`) | Default  | Role                                                                                                                                                                                    |
| --------------------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--morphology`                                | none     | `ClimberMorphology` JSON (height, arm span, constraints). Overrides `--height` and `--arm-span`                                                                                         |
| `--height`, `--arm-span`                      | 175, 178 | Height and arm span in cm                                                                                                                                                               |
| `--preference`                                | `easy`   | `easy`, `power` or `technique`                                                                                                                                                          |
| `--feet-free`                                 | off      | Every usable hold of the photo can hold a foot                                                                                                                                          |
| `--color`                                     | none     | Colour name of the route (`color.name` of the holds, case-insensitive): adds the holds of that colour to `--selected`. An unknown colour is an error that lists the colours of the file |
| `--selected`                                  | all      | Ids of the holds of the route, comma separated. The id is the index of the hold in the file when it has no `id`                                                                         |

```bash
cd apps/ai
# All at once (needs both models: moon run ai:setup, moon run holds:export)
uv run worker pathfinding --image path/to/wall.jpg --out /tmp/pathfinding.json --render /tmp/pathfinding.jpg --gravity 0 1 0 --color yellow

# Or step by step
uv run worker pathfinding-depth --image path/to/wall.jpg --out /tmp/depth.npy --render /tmp/depth.png
uv run worker pathfinding-wall  --image path/to/wall.jpg --out /tmp/holds_wall.json --gravity 0 1 0
uv run worker pathfinding-beta  --input /tmp/holds_wall.json --out /tmp/beta.json --preference technique --feet-free
uv run worker pathfinding-pose  --input /tmp/beta.json --holds /tmp/holds_wall.json --out /tmp/pathfinding.json --render /tmp/pathfinding.jpg --image path/to/wall.jpg
```

`pathfinding-beta` and `pathfinding-pose` need no model and no network: they only read the holds JSON with its `wall`.

---

## Pathfinding

The pathfinding turns the photo of a route and the morphology of a climber into a list of postures. It is the computation behind Ghost Mode: the ghost is the product feature, the pathfinding is the worker module that produces it (the `pathfindings` table holds the job and its result in `pathfindings.result`). The worker code is in `src/worker/_4_pathfinding/`:

| Module              | Role                                                                                                                                                                                             |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `_0_wall.py`        | Wall geometry: unprojects the depth map, fits the wall plane by RANSAC outside the holds, returns the homography photo pixels to cm in the wall plane (y up) and the wall angle from the gravity |
| `_1_depth.py`       | Depth model (MoGe-2 ViT-S, ONNX Runtime on the CPU, no PyTorch), rendering and `depth-eval`                                                                                                      |
| `_2_beta.py`        | A* search of the beta over the states of the four limbs                                                                                                                                          |
| `_3_pose.py`        | Inverse kinematics: the 33 MediaPipe landmarks (lowercase names, the keys of `Frame.landmarks`) of each step                                                                                     |
| `_4_pathfinding.py` | The chain, shared by the CLI and the job, plus the debug rendering                                                                                                                               |

**Wall plane.** The hold job calls the depth model on the photo, fits one plane (200 RANSAC iterations) on the pixels outside the holds, with an inlier threshold of 1.2 % of the median depth (`RANSAC_REL_THRESHOLD`, floor 2 cm), and stores it in `routes.wall_plane` (`homography`, `angle_deg`, `focal_px`, `inlier_ratio`, `model`) and `routes.wall_angle_deg`. The focal length is the one estimated by the model. `gravity` (optional, direction of the floor in the OpenCV camera frame: x right, y down, z forward, three finite numbers, not all zero) gives the angle: 0 vertical, positive overhang, negative slab. Without it `angle_deg` is `null` and the search treats the wall as vertical. The plane is rejected (no wall, a warning) when fewer than 1000 pixels are valid or when the inliers cover less than 20 % of the whole image (`MIN_WALL_COVERAGE`), so the floor and the ceiling visible on the photo do not count against the wall. `inlier_ratio` is the share of the valid pixels within the threshold.

**What the pathfinding job reads.** The `pathfindings` row (`morphology`, `route_id`), the route (`image_width`, `image_height`, `feet_free`, `wall_plane`), the holds of the route (`id`, `type`, `contour`, `usable`, `start_limbs`, `finish_limbs`) and `pathfinding_holds`. `job_id` is `pathfindings.id`.

| Input                               | Format and rule                                                                                                                                                                                                                                                                                                                            |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `pathfindings.morphology`           | `ClimberMorphology`: `height_cm` (required), `arm_span_cm` (defaults to the height), `dominant_hand` (read, not used by the search), `constraints` (`[{zone, type}]`, `type` is `missing` or `injured`)                                                                                                                                    |
| Body constraints                    | A zone of an arm (`*_shoulder`, `*_upper_arm`, `*_elbow`, `*_forearm`, `*_wrist`, `*_hand`, `*_fingers`) applies to the hand of the same side, a zone of a leg (`*_hip`, `*_thigh`, `*_knee`, `*_shin`, `*_ankle`, `*_foot`) to the foot. `missing` limbs are never used, `injured` limbs pay a cost on each move. Other zones are ignored |
| `pathfinding_holds`                 | The holds of the route for this pathfinding. Empty: every `usable` hold of the route                                                                                                                                                                                                                                                             |
| `routes.feet_free`                  | When true, the other `usable` holds of the photo can hold a foot (not a hand)                                                                                                                                                                                                                                                              |
| `holds.start_limbs`, `finish_limbs` | Marks: 1 to 4 limbs at the start, 1 to 2 hands at the finish. Both hands take the start marks first, the other marks are feet. Without marks, the lowest hold of the route is the start (2) and the highest the finish (2)                                                                                                                 |
| Hold type                           | Every hold is generic (`unknown`: usable by hands and feet, in every direction, big enough for two hands). Costs come from a table by type, `volume` is penalised for hands                                                                                                                                                                |
| `pathfinding.compute.requested`     | `preference`: `easy` (default), `power` (fewer, longer moves) or `technique` (short moves, more foot placements)                                                                                                                                                                                                                           |

**What the pathfinding job writes.** `pathfindings.result` is a `PathfindingResult`: `image_width`, `image_height`, `wall_angle_deg` and `steps`. Each step has its `index`, the `moved_limb` (absent at the start), the hold id under each limb (`null` when the limb is free), the `center_of_mass` and the 33 `landmarks`, in pixels of the photo (y down). The statuses and the progress are in [Pipeline](#pipeline).

Failures are permanent, written in `pathfindings.error` and dead-lettered to `pathfinding.compute.dlq`:

| Message                         | Cause                                                                                               |
| ------------------------------- | --------------------------------------------------------------------------------------------------- |
| `Job not found`                 | The `pathfindings` row does not exist                                                                     |
| `Wall geometry missing`         | `routes.wall_plane` is empty (no depth model at detection time, or no plane found)                  |
| `Wall geometry invalid`         | The homography is not a finite, invertible 3x3 matrix                                               |
| `Invalid pathfinding data`      | The stored morphology or wall does not match the schema, or a hold contour, type or mark is invalid |
| `No beta between holds A and B` | No sequence exists. `A` is the highest hold reached and `B` the nearest one that is not reached     |
| `Pathfinding failed`            | Any other permanent error of the computation, for example no usable hold                            |
| `Database unavailable`          | Temporary error, after three retries                                                                |

The hold job fails with `Invalid gravity` when `gravity` is not three finite numbers.

**`depth-eval`.** It measures the depth model on photos whose real distances are known. `--dataset` is a folder with the photos and an `annotations.json`: a list of `{"image": "<file name>", "pairs": [{"a": [x, y], "b": [x, y], "distance_cm": <real distance>}]}`, with `a` and `b` in pixels of the photo. It prints, per image then overall, the mean and median relative error of the 3D distance between the two pixels (pairs on a pixel without valid depth are counted as skipped). No such dataset exists in the repository yet.

**End-to-end test.** `tests/e2e/test_e2e_pathfinding.py` runs the real worker, RabbitMQ, PostgreSQL and RustFS, with the depth model replaced by a wall facing the camera at 3 m and the hold model by the squares of a drawn ladder (a synthetic photo is no scene for the real models). Scenarios: a route to `success` with `wall_plane`, then a seeded `pathfindings` row to `success` with a valid `result`; a route without wall (`pathfindings` row `failed` with `Wall geometry missing`); two holds too far apart (`No beta between holds ...`); a wall failure that does not fail the detection; the real models on a real photo, which never fail the detection. `tests/functional/test_cli_pathfinding.py` runs the sub-commands as processes (`pathfinding-beta` and `pathfinding-pose` without any model, the real models on a real photo).

---

## Triggering a job by hand

The Go server publishes `pose.detect.requested` itself; it does not publish `holds.detect.requested` nor `pathfinding.compute.requested` yet. Without the server, `src/producer.py` plays its role. It needs PostgreSQL (migrated), RabbitMQ and RustFS.

| Command                                                                      | Effect                                                                                                                                                                 |
| ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `uv run python src/producer.py seed --video resources/example-2.mp4`         | Creates a test user, video, `pending` analysis and `pending` advice, creates the bucket if missing, uploads the video, prints `job_id=`, `object_key=` and `video_id=` |
| `uv run python src/producer.py detect --job-id <id> --object-key <key>`      | Publishes `pose.detect.requested`                                                                                                                                      |
| `uv run python src/producer.py advice --job-id <id>`                         | Publishes `pose.advice.requested` (`--job-id` is the `video_id`)                                                                                                       |
| `uv run python src/producer.py seed-route --image path/to/wall.jpg`          | Creates a test user and a `pending` route, uploads the photo, prints `route_id=` and `object_key=`                                                                     |
| `uv run python src/producer.py holds --job-id <route_id> --object-key <key>` | Publishes `holds.detect.requested` (without `gravity`, so the wall angle stays empty)                                                                                  |
| `uv run python src/producer.py seed-pathfinding --route-id <route_id>`        | Creates a `pending` `pathfindings` row on an existing route, for the user of the route (`--height` 175, `--arm-span` 178), without `pathfinding_holds`; prints `pathfinding_id=` |
| `uv run python src/producer.py pathfinding --job-id <pathfinding_id>`         | Publishes `pathfinding.compute.requested` (`--preference` `easy`, `power` or `technique`, optional)                                                                    |

The pathfinding needs a route in `success` with a `wall_plane`: run `seed-route` and `holds`, wait for the route, then `seed-pathfinding` and `pathfinding`.

Through moon: `moon run ai:producer -- seed --video resources/example-2.mp4`.

---

## Tests

| Command                | Scope                                                                                                                                  | Needs                                 |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `moon run ai:test`     | Unit tests plus functional tests (the CLI in sub-processes on `resources/example-2.mp4`). `-m "not e2e and not integration"`           | No infrastructure, no network         |
| `moon run ai:coverage` | Same tests with a coverage report of `src/` (generated `shared/models.py` excluded)                                                    | No infrastructure                     |
| `moon run ai:e2e`      | End to end (real worker, RabbitMQ, PostgreSQL, RustFS, LLM simulated) plus the PostgreSQL integration tests. `-m "e2e or integration"` | PostgreSQL migrated, RabbitMQ, RustFS |

`ai:test` is no longer tolerant: a failing test fails the task and the CI. It also depends on `ai:setup` (model download) and `root:schemas-generate`.

`ai:e2e` depends on `root:db-up` and `server:migrate` (the `migrate` tool comes from `moon run server:setup`). A test whose service is unreachable is skipped, not failed: read the reasons with `-rs`.

**`TEST_POSTGRES_URL`** points the integration and end-to-end tests to a specific database. When unset, the end-to-end test falls back to `POSTGRES_DB_URL` or the `POSTGRES_*` variables, which target port 5432 by default. If another project uses that port, the test would connect to it with `ascension/ascension`. Always set the variable (or `POSTGRES_PORT`) to a disposable, migrated database. The integration tests are skipped without `TEST_POSTGRES_URL`.

Example with disposable containers (adapt the ports):

```bash
export TEST_POSTGRES_URL=postgres://ascension:ascension@127.0.0.1:55434/ascension \
       POSTGRES_PORT=55434 RABBITMQ_PORT=55672 RUSTFS_ENDPOINT=http://127.0.0.1:59000
cd apps/ai && uv run pytest -p no:cacheprovider -rs -m "e2e or integration"
```

Where the tests live:

| Path                | Content                                                                                                                                                                                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tests/test_*.py`   | Unit tests with simulated broker, database, storage and LLM (`test_holds.py`, `test_hold_handler.py`, `test_postgresql_routes.py` for the holds; `test_pathfinding_*.py`, `test_postgresql_pathfindings.py` and `test_producer_pathfinding.py` for the pathfinding) |
| `tests/functional/` | The `worker` CLI in sub-processes (`test_cli_pathfinding.py` for the pathfinding sub-commands)                                                                                                                                                                |
| `tests/e2e/`        | Real services, five scenarios: nominal, invalid payload, missing object, LLM failure, advice rerun; plus five pathfinding scenarios in `test_e2e_pathfinding.py` (see [Pathfinding](#pathfinding))                                                            |

Without `--upstream none`, moon first runs the upstream tasks, including `root:schemas-generate`, which rewrites `src/shared/models.py` and `apps/server/internal/shared/models.go`.

---

## Project layout

| Path (under `apps/ai/`)            | Role                                                                                                                                                                                                     |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `src/worker/__init__.py`, `cli.py` | `worker` entry point and sub-commands                                                                                                                                                                    |
| `src/worker/runtime.py`            | Lazy, cached access to the broker, database, storage, skeleton extractor, hold segmenter and LLM                                                                                                         |
| `src/worker/_1_mediapipe/`         | Pipeline steps: `_1_pose_skeleton`, `_2_pose_filter`, `_3_pose_metrics`, `_4_pose_movements`, plus `pose_geometry` and `_0_pose_detect` (chains them)                                                    |
| `src/worker/_2_advice/`            | `pose_advice`: prompt, LLM call, `Hints`                                                                                                                                                                 |
| `src/worker/_3_holds/`             | Hold steps: `_1_hold_segment` (ONNX model, NMS, masks to polygons), `_2_hold_color` (dominant colour and palette), `_0_hold_detect` (chains them), `evaluate` (colour accuracy)                          |
| `src/worker/_4_pathfinding/`       | Pathfinding steps: `_0_wall` (wall plane, homography), `_1_depth` (depth model, `depth-eval`), `_2_beta` (A*), `_3_pose` (inverse kinematics), `_4_pathfinding` (chain), see [Pathfinding](#pathfinding) |
| `src/worker/handlers/`             | One handler per RabbitMQ flow, plus `failure.py`                                                                                                                                                         |
| `src/services/`                    | Third-party services: `rabbitmq.py`, `postgresql.py`, `rustfs.py`, `llm.py`                                                                                                                              |
| `src/common/models/`               | Configuration models of the services                                                                                                                                                                     |
| `src/common/db_schemas/`           | Row models of the `analyses` and `advices` tables                                                                                                                                                        |
| `src/common/utils/`                | Retry and error classes, the `@consume` wrapper, bindings, logger                                                                                                                                        |
| `src/shared/models.py`             | Generated from `schemas/`. Never edit it                                                                                                                                                                 |
| `src/producer.py`                  | Stand-in for the Go server                                                                                                                                                                               |
| `scripts/download-model.sh`        | Downloads the MediaPipe model                                                                                                                                                                            |
| `scripts/download-depth-model.sh`  | Downloads the depth model of the pathfinding (MoGe-2 ViT-S, 141 MB)                                                                                                                                      |
| `resources/`                       | MediaPipe models, hold model `holds_seg.onnx` (42 MB, exported by training/holds), depth model `moge-2-vits-normal.onnx` (141 MB, downloaded, not versioned) and the sample video `example-2.mp4`        |
| `tests/`                           | See [Tests](#tests)                                                                                                                                                                                      |

Pipeline steps take and return data. They do not depend on RabbitMQ, the database or storage.

---

## Shared schemas

The contract between the worker and the server lives in `schemas/` at the repository root. `moon run root:schemas-generate` generates `src/shared/models.py` (Python) and `apps/server/internal/shared/models.go` (Go). Edit the schemas, never the generated files. `ai:lint`, `ai:test` and `ai:build` run the generation first.

---

## Known limits

- **Hands are unreliable on `example-2.mp4`.** With `MIN_VISIBILITY` at 0.5, the wrist is measured on only 142 (left) and 136 (right) frames out of 309. On that video no frame has both arms measurable at once. The movements of the hands are therefore unusable and no pause is detected (14 movements, 0 pause). The feet are consistent. Lowering `MIN_VISIBILITY` to 0.1 to 0.3 makes the hands continuous, but it is not validated: those landmarks are ones the model judges unreliable. The advice step flags such limbs as unreliable and forbids conclusions on them.
- **Thresholds are calibrated on one video** (`resources/example-2.mp4`, climber seen from behind): `MIN_VISIBILITY` 0.5, `MAX_GAP_FRAMES` 5, `SMOOTH_WINDOW` 5, `BENT_ARM_THRESHOLD` 0.8, speeds 0.8 and 0.4 torso lengths per second, merge gap 150 ms, minimum movement 100 ms, minimum pause 500 ms. Revisit them with real climbs and other camera angles.
- **LLM providers are not tested for real.** No call to Gemini or DeepSeek has been made. Model names and JSON mode support are unverified.
- **The Go server does not consume the worker's events.** It publishes `pose.detect.requested` and `pose.advice.requested` but ignores `pose.detect.status` and `pose.advice.status`: the app polls the API, which reads the `analyses` and `advices` rows.
- **An invalid payload goes to the dead-letter queue without any status.** The analysis stays `pending` in the database. The server's cron job marks an analysis still `pending` after 15 minutes as `failed`.
- **Progress 75 is never written.** Skeleton, filtering, metrics and movements run in one call, so the progress goes from 70 to 80.
- **No reconnection.** If the RabbitMQ connection drops, the process exits with a non-zero code and Docker restarts it. The worker finishes the running job first.
- **Hold detection misses small footholds and does not classify grips.** On the test split of training/holds, about 66 % of the holds smaller than 25 px (on a 1600 px photo) are found, against more than 90 % of the larger ones. Every hold is typed `unknown` (or `volume`).
- **Colour names are a hint, not a fact.** The displayed `rgb` is reliable; the `name` is right for about 62 % of the holds of the Guillaume dataset (83 % with a palette calibrated on that gym, about 60 % in an unseen one). Red/orange, green/yellow and chalked black/cream are the usual confusions. The user validates the holds of a route anyway.
- **The Go server does not publish hold jobs yet.** The contract is ready (`schemas/hold_detect_request.schema.json`, `holds.detect.requested`, the `routes` job columns); the routes of the API remain to be written.
- **The pathfinding was run for real on one route photo only.** On `resources/voie.jpg` (a framed route, median depth 4.56 m) the wall is accepted (`inlier_ratio` 0.48, 39 holds, 12 of them yellow with one duplicate detection) and the yellow beta (`--color yellow`) has 13 steps; `worker pathfinding` takes about 5 s with both models on a 24-core CPU. The inlier threshold (1.2 % of the median depth, floor 2 cm) and the coverage criterion (0.2 of the image) were chosen on that photo and on synthetic scenes, and must be checked on other routes (farther, closer, overhanging). The previous criterion (2 cm, 40 % of the valid points) failed on the six whole-gym images of `docs/Ascension/resources/images/deck` (inlier ratio 0.14 to 0.31); with the current one `pathfinding-wall` accepts a wall on them too, but those walls were not checked and four of the images are generated pictures.
- **The metric scale is probably too small and is not measured.** On `voie.jpg` the wall is 3.4 to 3.5 m high from its top to the mat, where a boulder wall is more likely 4 to 4.5 m: an underestimate of about 15 to 25 %, with no ground truth (the top of the wall may be out of the photo). The distances between yellow holds stay plausible. The wall has three facets and is fitted as one plane (the normal moves by about 2 degrees with the threshold). Annotate distances and run `worker depth-eval` to settle it.
- **The metric accuracy of the depth model is not measured.** The 5 to 15 % error target is unverified. The depth model takes about 2 s on a 24-core CPU for a 1880x2272 photo (`pathfinding-wall` about 4.4 s); the time on a server CPU is not measured.
- **The floor is not modelled.** At the start the feet are free (`null`; only the two hands are placed) and the first move puts one on a hold, possibly the one of a hand.
- **Reach constraints are checked by pairs.** Hand to hand, hand to foot and foot to foot distances are checked one pair at a time, not jointly by the body. About 8 to 10 % of the steps on random walls are not reachable together; the posture then draws a stretched limb up to about 20 cm from its hold. On `voie.jpg`, 5 steps out of 13 have a wrist or ankle 7 to 21 cm from its hold. A joint feasibility test of the torso in the search is not written.
- **The A* search is slow with many holds.** 30 hand holds plus 30 foot holds take about 1.2 s, but 76 holds without selection took 48 s. The search stops with `No beta` after 100,000 expansions. In practice the route is the selection of the user (`pathfinding_holds`), smaller than the photo.
- **The posture is simple.** The torso is vertical, the hold is generic (no grip type, no pulling direction), the reach ratios and cost weights are reasonable values not calibrated on real climbers or routes, and the postures are 2D (knees and elbows only bend sideways). The plausibility was tested by geometric properties, not by eye on real routes.
- **A malformed `gravity` fails the hold job** (`Invalid gravity`) instead of being ignored. The generated Pydantic models do not enforce the array sizes of the schemas, so the worker checks them by hand.
- **The whole pathfinding job is validated with a fake depth map only.** The CLI chain ran with the real models on `voie.jpg`, but the job (database, RabbitMQ) and the end-to-end test use a fake depth map and a fake hold model. Duplicate detections of the same hold (two holds at the same position on `voie.jpg`) are not merged.
- **The Go server and the mobile app do not use the pathfinding yet.** The server does not create the `pathfindings` row, fill `pathfinding_holds`, nor publish and consume `pathfinding.compute.*`. The mobile app does not validate the marks, send `gravity` from the accelerometer, nor draw the ghost (the postures).
- **The end-to-end test is not in the CI.** It needs `docker compose`. Processing time of `example-2.mp4` (10 s, 1.6 MB) was measured at about 6 s on a CPU, with a simulated LLM. This is a baseline from a single video.
