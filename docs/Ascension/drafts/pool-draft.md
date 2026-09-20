---
id: ce8455bb-a167-4a33-a58e-1f2fb55b5627
---

:::success
**Version:** 1.1\
**Original language:** English\
DON'T EDIT THIS FILE !
:::

---

# Prototype Pool Draft Notes

---

## Sprint Intent

This draft captures the initial alignment notes for the prototyping pool sprint. The objective is to deliver a first end-to-end, functional slice using the core Ascension stack.

---

## Initial Scope

- Deliver a first AI analysis pipeline with skeleton extraction.
- Connect backend and AI through RabbitMQ.
- Provide a working frontend flow to upload a video and trigger analysis.
- Store source videos in MinIO.
- Initialize the database with the required schema.

---

## Team Ownership

- `@livo3192`: first AI implementation with MediaPipe.
- `@jundo`: backend ↔ AI integration via RabbitMQ.
- `@itskarmaoff`: frontend upload and analysis trigger flow.
- `@dimitri_lapoudre`: backend initialization and first API routes.
- `@nicolas_toro`: project management setup (GitHub Projects, planning), then support on cross-team coordination.

---

## Technical Flow Draft

- Backend returns a presigned upload URL.
- Mobile uploads video directly to object storage.
- User triggers analysis from the app.
- Backend publishes analysis job to RabbitMQ.
- AI worker processes the job and returns JSON results.
- Backend persists results in the database and exposes them to frontend.
- Authentication can be integrated once the core flow is stable.
- Depth estimation exploration can leverage SAM3.

---

## Key Stages and Deliverables

### Stage 1: Definition

- Define scope, goals, and demo scenario.
- Expected deliverables: up-to-date GitHub project, assigned milestone tasks, documented ownership, technical environment definition, and hardware request if needed.

### Stage 2: User Flow and Prototyping

- Build one cohesive demonstration flow (no fragmented demos).
- Track progress with intermediate check-ins.
- Finalize the prototype before the presentation window.

### Stage 3: Presentation Readiness

- Prepare a 15-minute pitch.
- Deliver a public demo with a real user flow.
