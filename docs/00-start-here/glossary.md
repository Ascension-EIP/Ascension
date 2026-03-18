> **Last updated:** 16th March 2026  
> **Version:** 1.1  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Project Glossary

This glossary defines key terms, acronyms, and domain vocabulary used across the Ascension project.

## Table of Contents

- [Project Glossary](#project-glossary)
  - [Product and Business Terms](#product-and-business-terms)
  - [Technical Terms](#technical-terms)
  - [Climbing and Biomechanics Terms](#climbing-and-biomechanics-terms)
  - [Project Components](#project-components)

---

## Product and Business Terms

- **Ascension:** AI-powered climbing coaching platform including mobile, backend, and AI services.
- **Prototype Pool:** Product workstream for validating features, requirements, and feasibility before full implementation.
- **RNCP:** French certification framework used as a compliance context for audit and project documentation.
- **User Journey:** Step-by-step user path from route capture to movement analysis and coaching feedback.

---

## Technical Terms

- **MediaPipe:** Google framework used for human pose landmark detection and tracking.
- **Skeleton Extraction:** Conversion of video frames into body landmarks for movement analysis.
- **Hold Detection:** Computer vision process that identifies climbable holds from wall images.
- **REST API:** HTTP API used by clients to interact with backend resources.
- **WebSocket:** Persistent bidirectional channel used for low-latency updates and streaming events.
- **JSONB:** PostgreSQL binary JSON type used for flexible and queryable structured payloads.
- **moonrepo:** Monorepo task runner and orchestration tool used across apps and shared workflows.

---

## Climbing and Biomechanics Terms

- **Route:** Defined sequence of holds to complete on a climbing wall.
- **Boulder:** Short climbing problem usually performed without ropes at low height.
- **Beta:** Strategy or sequence advice for solving a route.
- **Crux:** Most difficult move or section of a route.
- **Center of Gravity (COG):** Estimated point representing body mass balance through motion.
- **Body Alignment:** Relative positioning of limbs and trunk used to evaluate technique quality.

---

## Project Components

- **Mobile App:** User-facing client for recording climbs, viewing analyses, and receiving coaching feedback.
- **Server:** Backend service layer handling persistence, APIs, authentication, and business logic.
- **AI Worker:** Processing service that runs pose, holds, and movement analysis pipelines.
- **Ghost Climber:** Visual guidance overlay that shows an optimized movement sequence on top of user video.
