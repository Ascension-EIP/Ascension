---
id: a521a93c-f811-4150-a388-1a7238a7242c
---

:::warning
**Version:** 0.3
:::

---

# AI worker

The AI worker (`apps/ai`, Python 3.11, managed with `uv`) does the heavy lifting outside the API: it fetches a climber's video, computes the 2D analysis and produces advice. It never talks directly to the mobile app. It consumes RabbitMQ jobs, reads the video from RustFS (S3), writes its progress and results to PostgreSQL, and publishes its statuses on RabbitMQ.

Today, only the 2D video pipeline exists: route reading (photo), pathfinding, Ghost Mode and 3D are not implemented. The details of each building block, its thresholds and its limits are in [pipeline-2d-decomposition.md](pipeline-2d-decomposition.md). Installation, environment variables, commands and tests are in the [worker README](../../../../../apps/ai/README.md).

---

## What the worker does

| Step | Queue | Input | Output |
| --- | --- | --- | --- |
| Pose detection | `poses.detect` | `pose.detect.requested`: `{job_id, object_key}` | `analyses.result` (filtered skeleton, angles, speeds, metrics, movements, pauses) |
| Advice | `poses.advice` | `pose.detect.completed` or `pose.advice.requested`: `{job_id}` | `analyses.hints` (structured advice, in French) |

- The exchange is `events` (topic). Jobs that fail permanently go to `<queue>.dlq`.
- `job_id` is the identifier of the `analyses` row. The bucket is a configuration value, not part of the message.
- Statuses: `pending` (created by the server), `started` (picked up by the worker), `running`, `success`, `failed`. `success` is only set after the advice step.
- If the LLM fails or is not configured, the analysis ends in `success` with empty `hints`, and `pose.advice.status` is `failed`. The skeleton remains usable.
- One job at a time per process. To scale, add replicas.
- The language model is interchangeable: a single OpenAI-compatible client, configured by `LLM_BASE_URL`, `LLM_API_KEY` and `LLM_MODEL`. It only receives computed values, never the video or any identifier.

Each pipeline step is also a subcommand (`uv run worker pose-detect`, `pose-advice`, etc.) that works without a broker, database or storage.

The Go server is not yet wired to these queues: it still publishes on the old `vision.skeleton` queue. In the meantime, `apps/ai/src/producer.py` triggers jobs by hand.

---

## AI flow diagram

*Summary: the app uploads the video directly to RustFS, then the API publishes the job. The worker analyzes the video, writes the result and the advice to PostgreSQL and publishes its statuses. The photo pipeline (Ghost Mode) is planned, not implemented. Both pipelines use the same blocks as the* [2D pipeline decomposition](pipeline-2d-decomposition.md) *and are connected in two places: the route context (dotted lines), which lets the video analysis and the advice refer to the same route as the holds detected on the photo, and the shared delivery path to the mobile app (API, WebSocket, then rendering E1 or E2).*

```mermaid
flowchart TD
    subgraph Client ["Client layer"]
        App["Mobile app (Flutter)"]
        E1["E1 Skeleton overlay<br/>& advice on video"]
        E2["E2 Step-by-step viewer<br/>Ghost Mode on photo"]
    end

    subgraph Gateway ["API Gateway"]
        API["API server (Go/Gin)"]
    end

    subgraph Broker ["Message Broker"]
        RMQ["RabbitMQ"]
    end

    subgraph IA ["AI processing layer"]
        subgraph A ["A. Video analysis (pose)"]
            A1["A1 Ingestion<br/>climber video"] --> A2["A2 MediaPipe skeleton<br/>33 points per frame"]
            A2 --> A3["A3 Angles and metrics"]
            A3 --> A4["A4 Movement segmentation"]
        end

        subgraph D ["D. Advice & video comparison"]
            D3["D3 Advice<br/>external model"]
            D2["D2 Video-to-video comparison<br/>(same route, public/friends)"]
        end

        subgraph B ["B. Route reading (photo of empty wall)"]
            B1["B1 Wall photo"] --> B2["B2 Hold detection<br/>YOLOv8"]
            B2 --> B3["B3 Dominant color<br/>OpenCV"]
            B3 --> B4["B4 Clustering<br/>by route / color"]
            B4 --> B5["B5 Group or manual selection"]
        end

        subgraph C ["C. Pathfinding"]
            C1["C1 Selected holds<br/>+ morphology"] --> C2["C2 Feasible beta<br/>step by step (images)"]
        end

        A4 --> D3
        A4 --> D2
        B5 --> C1
        B5 -.->|"route context"| D3
        B5 -.->|"same route"| D2
    end

    subgraph Data ["Data and Storage layer"]
        S3["Object Storage S3 (RustFS)"]
        PG["PostgreSQL"]
    end

    %% Communication flow (1 to 12)
    App -->|"1. Request presigned URL"| API
    API -->|"2. Generate presigned URL"| S3
    App -->|"3. Direct upload (video or photo)"| S3
    App -->|"4. Notify upload done"| API
    API -->|"5. Publish the job"| RMQ

    RMQ -->|"6a. Pose analysis job<br/>(climbing video)"| A1
    A1 -->|"Fetch the video"| S3
    A3 -->|"7a. Store result (JSON)"| PG
    D3 -->|"7a. Store advice (JSON)"| PG
    D3 -->|"8a. Publish statuses"| RMQ

    RMQ -->|"6b. Ghost Mode job<br/>(wall photo)"| B1
    B1 -->|"Fetch the photo"| S3
    C2 -->|"7b. Store steps & images"| PG
    C2 -->|"8b. Publish completed event"| RMQ

    RMQ -->|"9. Notify result ready"| API
    API -->|"10. WebSocket notification"| App
    App -->|"11. Fetch the analysis (JSON)"| API
    API -->|"12. Read the data"| PG

    App --> E1
    App --> E2
```
