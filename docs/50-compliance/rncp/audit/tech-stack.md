> **Last updated:** 16th February 2026  
> **Version:** 1.0  
> **Authors:** Gianni TUERO  
> **Status:** Done  
> {.is-success}  

---

# Technology Stack Decisions

---

## Overview

This document explains the main technology choices for the Ascension platform and why we made them.

---

## Project Context

### What We Need

1. **Fast API**: Handle many users with quick response times
2. **AI Processing**: Analyze climbing videos efficiently
3. **Mobile App**: Work on both iOS and Android
4. **Cost-Effective**: Keep infrastructure costs low during development
5. **Quick Development**: Build MVP within 6 months

---

## Technology Decisions

### 1. Mobile Framework: Flutter

**Why Flutter?**

- **One codebase for iOS and Android**: Write once, deploy everywhere saves a lot of time
- **Good performance**: Native compilation means smooth animations
- **CustomPainter**: We can draw skeleton overlays directly on video (key feature)
- **Team knows it**: We already have Flutter experience
- **Hot reload**: Makes development much faster

**Alternatives we considered**:
- React Native: Popular but needs JavaScript bridge (slower)
- Native (Swift/Kotlin): Best performance but would need two separate codebases

**Trade-offs**: App will be slightly larger, but the time saved is worth it.

### 2. API Backend: Rust

**Why Rust?**

- **Very fast**: Comparable to C++ in performance
- **Memory safe**: Prevents common bugs like null pointers
- **Good for WebSockets**: Handle many concurrent connections efficiently
- **Low resource usage**: Means cheaper servers
- **Type safety**: Catches errors before code runs

**Alternatives we considered**:
- Node.js: Easier to learn but slower and uses more memory
- Go: Good performance, simpler than Rust, but our team already knows Rust
- Python: Too slow for high-traffic API

**Trade-offs**: Rust has a steeper learning curve, but we have one developer who knows it and can help the team.

### 3. AI/ML Stack: Python + MediaPipe

**Why Python & MediaPipe?**

- **Industry standard**: Most AI/ML work is done in Python
- **Pre-trained models**: MediaPipe already has pose estimation models ready to use (33 keypoints)
- **Fast to prototype**: Easy to test and adjust pipelines
- **Team expertise**: Our AI developer knows the Python ML ecosystem
- **Great libraries**: OpenCV, NumPy, scikit-image for computer vision
- **Two pipelines**: Vision pipeline (hold detection, skeleton extraction, advice, ghost mode) and Training pipeline (personalized programs)

**Alternatives we considered**:
- PyTorch: More flexibility for custom models, but MediaPipe covers our pose estimation needs out of the box
- TensorFlow: Also popular, heavier setup
- ONNX Runtime: Faster inference but harder to develop with

**Why it works**: AI processing happens separately from the API in async workers, so Python's speed is not a bottleneck. MediaPipe handles the heavy lifting for skeleton extraction.

### 4. Database: PostgreSQL

**Why PostgreSQL?**

- **Good for structured data**: Users, videos, and analyses have clear relationships
- **JSONB support**: Can store flexible JSON data (analysis results) in the same database
- **Reliable**: Used by many large companies for years
- **Complex queries**: Easy to join users with their videos and analyses
- **Free and open-source**: No licensing costs

**Alternatives we considered**:
- MongoDB: Good for flexible data, but our data is mostly structured
- MySQL: Similar to PostgreSQL but less features

**Trade-offs**: None significant for our use case.

### 5. Message Queue: RabbitMQ

**Why RabbitMQ?**

- **Reliability**: Ensures messages (video analysis jobs) are never lost even if a worker crashes.
- **Complex Routing**: Can handle different types of jobs with flexible routing keys.
- **Standard**: Industry standard for robust message queuing.
- **Decoupling**: Completely separates the API from the AI workers.

**Alternatives we considered**:
- Redis: Fast and simple, but message persistence and reliability are less robust than RabbitMQ.
- Kafka: Too complex for our current throughput needs.

**Trade-offs**: Slightly more complex setup than Redis, but worth it for reliability.

---

### 6. Object Storage: MinIO (Self-Hosted)

**Why MinIO?**

- **S3-compatible API**: Same standard protocol, code works everywhere
- **Self-hosted**: No cloud vendor lock-in, runs on Hetzner VPS
- **Docker-friendly**: Easy to run locally in dev and in production
- **Privacy**: Videos stay on our infrastructure (EU, GDPR-compliant)
- **Presigned URLs**: Users upload directly to MinIO, not through our API
- **Scalable**: Supports distributed mode for clustering when needed

**Alternatives we considered**:
- AWS S3: Industry standard but cloud-specific, adds cost and vendor lock-in
- Hetzner Object Storage: S3-compatible managed option on Hetzner (possible future migration)

**Trade-offs**: Requires managing storage ourselves, but avoids cloud costs and keeps data in-house.

---

## Summary

| Component      | Technology         | Main Reason                              |
| -------------- | ------------------ | ---------------------------------------- |
| Mobile App     | Flutter            | One codebase for iOS & Android           |
| API Backend    | Rust (Axum)        | Fast & memory-safe                       |
| AI Workers     | Python (MediaPipe) | Pose estimation + vision pipelines       |
| Database       | PostgreSQL         | Structured data + JSON support           |
| Message Queue  | RabbitMQ           | Reliable message broker with persistence |
| Object Storage | MinIO → S3        | S3-compatible, free dev → reliable prod |

---

## Future Considerations

We'll review these decisions in 6 months (August 2026) to see if they still make sense as the project grows.

**Possible future changes**:
- Add CDN for faster video delivery
- Separate AI workers onto dedicated Hetzner VPS with GPU
- Use Kubernetes (K3s on Hetzner) for horizontal auto-scaling
- Migrate MinIO to Hetzner Object Storage if managed solution is preferred

**Related Documents**:
- [System Overview](../system-overview.md)
- [Database Schema](../specifications/database-schema.md)
- [API Specification](../specifications/api-specification.md)
