

> **Last updated:** 20th April 2026  
> **Version:** 2.0  
> **Author:** GitHub Copilot audit  
> **Status:** Draft for validation  
> {.is-warning}

---

# Audit complet du backlog GitHub Issues (Ascension)

Ce document remplace l'ancien brouillon et sert de plan d'action concret.

Objectifs:
- analyser les issues existantes via `gh`;
- comparer avec l'etat actuel du code;
- proposer les modifications/fermetures des issues existantes;
- proposer les nouvelles issues manquantes;
- fournir **tout le backlog de migration backend Rust -> Go**.

Important:
- le texte d'analyse est en francais;
- les **titres et descriptions d'issues** sont en anglais pour rester alignes au repo;
- aucune issue n'est creee/modifiee automatiquement ici, c'est un guide d'execution.

---

## 1) Methode et constats

Sources utilisees:
- `gh api` et `gh issue list --state all` (72 issues total, 39 ouvertes);
- revue des issues ouvertes avec leur corps et checklist DoD;
- revue rapide du code sur `apps/server`, `apps/mobile`, `apps/ai`, et de la doc de management (migration Go mentionnee explicitement).

Constats majeurs:
- plusieurs issues ouvertes ont **100% des cases cochees** et devraient etre fermees;
- plusieurs issues ouvertes ont un contenu **obsolete** (`/api/...` vs `/v1/...`, anciennes queues RabbitMQ, Rust-only wording);
- duplication d'intention sur certaines issues historiques (ex: init backend Rust);
- des sujets importants ne sont pas couverts par des issues explicites (tests d'integration backend, securite stockage token mobile, observabilite, contrat API versionne);
- la migration Rust -> Go est indiquee comme direction projet, mais pas structuree en backlog exploitable.

---

## 2) Actions sur les issues existantes

## 2.1 A fermer rapidement

1. `#31` - `SETUP: local development infrastructure with Docker Compose`  
Action: close (DoD completement coche)

2. `#142` - `MOBILE: Settings page`  
Action: close (DoD completement coche)

## 2.2 A corriger avant fermeture

1. `#62` - `AUTH: basic JWT authentication`  
Problemes:
- corps obsolete (`/api/auth/...` au lieu de `/v1/auth/...`);
- DoD coche "secure storage" alors que le mobile utilise `SharedPreferences` (pas equivalent a `flutter_secure_storage`);
- DoD coche "protected routes use middleware" alors que le middleware n'est pas branche globalement sur des routes protegees.

Action:
- editer l'issue, remettre 2 cases en non-fait;
- ajouter une note "partially done";
- lier avec les nouvelles issues `SECURITY: mobile token secure storage` et `SERVER: enforce auth middleware on protected routes`.

2. `#33` - `SETUP: PostgreSQL with initial database schema`  
Action: garder ouverte mais clarifier le critere "idempotent migration script" en "migrations are replay-safe via migration table".

3. `#60` - `MOBILE: analysis result display screen`  
Action: garder ouverte pour finaliser les items UI encore non coches (angles lisibles, feedback, empty states, navigation "Analyze again").

## 2.3 A re-scoper (contenu obsolete)

1. `#34` - `SETUP: configure RabbitMQ`  
A changer:
- remplacer references `analysis_jobs` / `analysis_results` par les objets effectivement utilises (`vision.skeleton`, `ascension.events`) ou clarifier la strategy cible.

2. `#40` - `SETUP: RabbitMQ message flow between server and AI worker`  
A changer:
- mettre a jour le schema de message reel (`job_id`, `analysis_id`, `video_url`);
- documenter explicitement le mode actuel: AI ecrit en DB + event de completion.

3. `#44` - `SERVER: presigned upload URL route`  
Probleme critique:
- corps manifestement tronque (fence JSON non fermee);
- endpoint obsolete (`/api/analysis/video/request-upload`).

Action:
- reecrire completement avec endpoint actuel `POST /v1/videos/upload-url` et payload reel.

4. `#45` - `SERVER: analysis trigger route`  
A changer:
- endpoint `POST /v1/analyses`;
- queue/schema reels;
- statuts reels (`pending`, `processing`, `generating_hints`, `completed`, `failed`).

5. `#46` - `SERVER: analysis result fetch route`  
A changer:
- endpoint `GET /v1/analyses/{id}`;
- structure reelle de reponse (`result_json`, `hints`, `progress`, `processing_time_ms`).

6. `#58`, `#59` - mobile upload + polling  
A changer:
- references endpoints legacy `/api/...` -> `/v1/...`;
- aligner les methodes avec `ApiService` actuel (`getUploadUrl`, `triggerAnalysis`, `getAnalysis`).

## 2.4 A fusionner / fermer comme obsolete

1. `#35` et `#42` (double intention "initialize Rust/Axum backend")  
Action recommandee:
- fermer `#35` (obsolete);
- fermer `#42` (obsolete);
- ouvrir un epic de migration Go (ci-dessous) qui remplace ces sujets.

2. `#47` - `SERVER: RabbitMQ result consumer to store AI results`  
Action recommandee:
- fermer en l'etat (obsolete par l'implementation actuelle ou a convertir en "event consumer/projection").

---

## 3) Nouvelles issues manquantes (hors migration Go)

Format: titre + labels + corps en anglais, directement reutilisable.

### NEW-01

**Title:** `SECURITY: use secure storage for mobile auth tokens`  
**Suggested labels:** `Mobile`, `type:feature`, `priority:p1`

**Description (EN):**

Replace token persistence in mobile authentication from SharedPreferences to a secure storage mechanism (`flutter_secure_storage`) to prevent sensitive token leakage on rooted or compromised devices.

## Scope
- Store `access_token` and `refresh_token` in secure storage.
- Keep non-sensitive profile values in SharedPreferences if needed.
- Provide migration path for already logged-in users.

## Definition of Done
- [ ] `access_token` and `refresh_token` are no longer stored in SharedPreferences.
- [ ] Existing sessions are migrated safely or invalidated with a clear UX flow.
- [ ] Login/register/logout flows still work end-to-end.
- [ ] Unit tests cover storage read/write/remove behavior.
- [ ] Security note is added to mobile developer documentation.

---

### NEW-02

**Title:** `SERVER: enforce auth middleware on protected routes`  
**Suggested labels:** `Server`, `type:feature`, `priority:p1`

**Description (EN):**

Wire JWT authentication middleware to all protected API routes and ensure role-based guards are effectively applied where required.

## Scope
- Define public routes (`/v1/auth/*`, health) vs protected routes.
- Apply middleware at router level for protected groups.
- Validate `Authorization: Bearer` and session cookie strategies.

## Definition of Done
- [ ] Protected routes reject unauthenticated requests with `401`.
- [ ] Role-guarded routes return `403` when role is insufficient.
- [ ] Integration tests cover positive and negative auth scenarios.
- [ ] API spec explicitly marks auth requirements per endpoint.

---

### NEW-03

**Title:** `SERVER: add integration tests for upload-to-analysis API flow`  
**Suggested labels:** `Server`, `Tests`, `type:feature`, `priority:p1`

**Description (EN):**

Add backend integration tests validating the critical API workflow: request upload URL -> trigger analysis -> poll analysis status/result.

## Definition of Done
- [ ] Integration tests run in CI.
- [ ] Test covers happy path and common failures.
- [ ] Tests validate response schema compatibility with mobile expectations.
- [ ] Regression baseline is documented.

---

### NEW-04

**Title:** `AI: add unit tests for result serialization and angle computation`  
**Suggested labels:** `AI`, `Tests`, `type:feature`, `priority:p2`

**Description (EN):**

Introduce unit tests for AI analysis output serialization and angle computation helpers to prevent silent schema regressions.

## Definition of Done
- [ ] Angle helper behavior is covered with deterministic fixtures.
- [ ] Output JSON structure is validated against a canonical schema.
- [ ] Corrupt/missing input video paths are tested.
- [ ] Tests run in CI and fail on schema-breaking changes.

---

### NEW-05

**Title:** `CONTRACT: publish and version API schema for mobile-backend compatibility`  
**Suggested labels:** `Server`, `Documentation`, `type:feature`, `priority:p1`

**Description (EN):**

Version the backend API contract and publish a canonical schema artifact used by mobile and QA to detect breaking changes early.

## Definition of Done
- [ ] A versioned API contract (OpenAPI or equivalent) is generated in CI.
- [ ] Mobile-facing endpoints and payloads are documented from source of truth.
- [ ] Contract check is added to pull request validation.
- [ ] Breaking changes require explicit version bump and changelog entry.

---

### NEW-06

**Title:** `OBSERVABILITY: add correlation IDs across mobile, server and AI pipeline`  
**Suggested labels:** `Server`, `AI`, `CI/CD`, `type:feature`, `priority:p2`

**Description (EN):**

Propagate a correlation ID through API requests, RabbitMQ jobs, AI processing logs, and database records to simplify production debugging.

## Definition of Done
- [ ] Correlation ID is generated at request ingress or accepted from client.
- [ ] RabbitMQ messages include correlation metadata.
- [ ] Server and worker logs include correlation ID consistently.
- [ ] A troubleshooting guide documents how to trace one analysis end-to-end.

---

## 4) Backlog complet de migration backend Rust -> Go

Principe:
- 1 epic de pilotage;
- un lot d'issues techniques decoupees et ordonnees;
- descriptions en anglais et DoD mesurable.

### GO-EPIC-00

**Title:** `EPIC: backend migration from Rust to Go with zero feature regression`  
**Suggested labels:** `Server`, `Setup`, `type:epic`, `priority:p0`

**Description (EN):**

Plan and execute the migration of Ascension backend from Rust/Axum to Go while keeping API compatibility, production stability, and CI quality gates.

## Success Criteria
- [ ] Feature parity achieved for all mobile-consumed endpoints.
- [ ] No critical regression on auth, upload, analysis orchestration.
- [ ] CI quality gates are green for Go backend.
- [ ] Rust backend decommission plan is executed safely.

---

### GO-01

**Title:** `SERVER-GO: define target architecture and technical decisions`  
**Suggested labels:** `Server`, `Documentation`, `type:spike`, `priority:p0`

**Description (EN):**

Produce an ADR package for Go backend choices (router/framework, DB access strategy, migrations, configuration, logging, testing strategy).

## Definition of Done
- [ ] ADR document approved by team.
- [ ] Framework and dependency stack selected.
- [ ] Compatibility constraints with existing mobile app documented.
- [ ] Migration risks and rollback strategy documented.

---

### GO-02

**Title:** `SERVER-GO: bootstrap new Go service with project skeleton`  
**Suggested labels:** `Server`, `Setup`, `type:feature`, `priority:p0`

**Description (EN):**

Create the initial Go backend workspace (`apps/server-go` or replacement strategy), including module setup, folder architecture, config loading, health endpoint, and local run command.

## Definition of Done
- [ ] Go service starts locally with one command.
- [ ] `/health` endpoint returns `200`.
- [ ] Environment variables are loaded and validated.
- [ ] Moon/CI tasks are wired for format, lint, build, test.

---

### GO-03

**Title:** `SERVER-GO: implement database connectivity and migration compatibility`  
**Suggested labels:** `Server`, `Setup`, `Build`, `type:feature`, `priority:p0`

**Description (EN):**

Connect Go backend to PostgreSQL and ensure compatibility with existing schema and migration history.

## Definition of Done
- [ ] Connection pooling is implemented and configurable.
- [ ] Existing schema is readable without data migration.
- [ ] Migration tool strategy is defined and documented.
- [ ] CI validates migration state on clean database.

---

### GO-04

**Title:** `SERVER-GO: implement auth endpoints parity (register/login/logout)`  
**Suggested labels:** `Server`, `type:feature`, `priority:p0`

**Description (EN):**

Implement `/v1/auth/register`, `/v1/auth/login`, `/v1/auth/logout` with parity to current behavior and token semantics.

## Definition of Done
- [ ] Endpoint request/response contracts are backward-compatible.
- [ ] Password hashing and token signing match security requirements.
- [ ] Error codes match current mobile expectations.
- [ ] Integration tests cover success and failure cases.

---

### GO-05

**Title:** `SERVER-GO: implement users CRUD parity`  
**Suggested labels:** `Server`, `type:feature`, `priority:p0`

**Description (EN):**

Implement users CRUD endpoints with pagination and role constraints equivalent to existing backend behavior.

## Definition of Done
- [ ] Create/read/update/delete/list endpoints are implemented.
- [ ] Pagination behavior matches current API contract.
- [ ] Domain/business validation is covered by tests.
- [ ] API documentation is updated.

---

### GO-06

**Title:** `SERVER-GO: implement video upload URL endpoint parity`  
**Suggested labels:** `Server`, `type:feature`, `priority:p0`

**Description (EN):**

Implement `POST /v1/videos/upload-url` with MinIO/S3 presign behavior compatible with mobile upload flow.

## Definition of Done
- [ ] Endpoint returns `video_id` + presigned URL.
- [ ] Stored video metadata remains compatible with analysis pipeline.
- [ ] Error handling covers MinIO/S3 failures.
- [ ] Integration tests validate upload URL generation.

---

### GO-07

**Title:** `SERVER-GO: implement analysis trigger endpoint parity`  
**Suggested labels:** `Server`, `AI`, `type:feature`, `priority:p0`

**Description (EN):**

Implement `POST /v1/analyses` to create analysis records and publish analysis jobs to RabbitMQ using the agreed schema.

## Definition of Done
- [ ] Analysis records are persisted before publish.
- [ ] RabbitMQ publish is reliable and observable.
- [ ] Message payload schema is documented and versioned.
- [ ] Failure paths are tested (DB error, MQ error).

---

### GO-08

**Title:** `SERVER-GO: implement analysis fetch endpoint parity`  
**Suggested labels:** `Server`, `type:feature`, `priority:p0`

**Description (EN):**

Implement `GET /v1/analyses/{id}` with status/progress/result payload parity and null-safe behavior while analysis is in progress.

## Definition of Done
- [ ] Response fields match existing mobile usage.
- [ ] In-progress and completed statuses are handled consistently.
- [ ] Not-found behavior returns expected status code.
- [ ] Contract tests validate payload compatibility.

---

### GO-09

**Title:** `SERVER-GO: define and implement completion event strategy`  
**Suggested labels:** `Server`, `AI`, `Documentation`, `type:feature`, `priority:p1`

**Description (EN):**

Formalize whether the AI worker writes directly to DB, publishes completion events, or both; then implement the final strategy in Go backend integration.

## Definition of Done
- [ ] Final event/data ownership model is documented.
- [ ] Go backend behavior matches chosen model.
- [ ] Duplicate processing and race conditions are addressed.
- [ ] End-to-end tests validate status transitions.

---

### GO-10

**Title:** `SERVER-GO: add structured logging, metrics, and trace hooks`  
**Suggested labels:** `Server`, `CI/CD`, `type:feature`, `priority:p1`

**Description (EN):**

Introduce observability primitives (structured logs, metrics export, trace context propagation) in the Go backend.

## Definition of Done
- [ ] Logs include request ID / correlation ID.
- [ ] Metrics endpoint is exposed and documented.
- [ ] Key latency/error metrics are tracked.
- [ ] Dashboard/alert baseline is defined.

---

### GO-11

**Title:** `SERVER-GO: implement test pyramid (unit, integration, contract)`  
**Suggested labels:** `Server`, `Tests`, `type:feature`, `priority:p0`

**Description (EN):**

Set up a complete automated test strategy for Go backend including unit tests, integration tests against local infra, and contract tests against mobile expectations.

## Definition of Done
- [ ] Unit tests cover core business services.
- [ ] Integration tests run against PostgreSQL and RabbitMQ.
- [ ] Contract tests validate public endpoint schemas.
- [ ] CI enforces minimum quality threshold.

---

### GO-12

**Title:** `SERVER-GO: CI/CD integration and release pipeline for Go backend`  
**Suggested labels:** `CI/CD`, `Server`, `Build`, `type:feature`, `priority:p0`

**Description (EN):**

Integrate Go backend into monorepo CI/CD workflows (lint, build, test, Docker image build, deployment hooks).

## Definition of Done
- [ ] Go backend jobs are added to CI.
- [ ] Docker image build/publish is working.
- [ ] Deployment workflow can target Go backend artifact.
- [ ] Failure logs are actionable.

---

### GO-13

**Title:** `SERVER-GO: perform shadow traffic and parity validation`  
**Suggested labels:** `Server`, `Tests`, `type:feature`, `priority:p1`

**Description (EN):**

Run Rust and Go backends in parallel for parity checks on real/synthetic traffic before cutover.

## Definition of Done
- [ ] A replay/shadow strategy is documented.
- [ ] Response parity report is generated.
- [ ] Critical mismatches are resolved.
- [ ] Go readiness gate is approved.

---

### GO-14

**Title:** `SERVER-GO: execute production cutover and rollback plan`  
**Suggested labels:** `Server`, `Setup`, `type:feature`, `priority:p0`

**Description (EN):**

Execute controlled switch from Rust backend to Go backend with rollback safety and incident runbook.

## Definition of Done
- [ ] Cutover checklist is validated.
- [ ] Rollback procedure is tested and documented.
- [ ] Post-cutover monitoring confirms stability.
- [ ] Stakeholders sign off the migration milestone.

---

### GO-15

**Title:** `SERVER: decommission Rust backend and update technical documentation`  
**Suggested labels:** `Server`, `Documentation`, `type:chore`, `priority:p1`

**Description (EN):**

After successful cutover, archive/remove obsolete Rust backend paths and update all documentation, diagrams, and onboarding guides to the Go stack.

## Definition of Done
- [ ] Obsolete Rust runtime paths are removed or archived.
- [ ] Docs no longer present Rust as active backend stack.
- [ ] Developer setup instructions are updated and validated.
- [ ] Final migration report is published.

---

## 5) Ordre d'execution recommande

1. Nettoyage backlog existant: fermer/editer les issues obsoletes (`#31`, `#35`, `#42`, `#47`, `#142`, mise a jour de `#34`, `#40`, `#44`, `#45`, `#46`, `#58`, `#59`, `#62`).
2. Ouvrir les nouvelles issues transverses de qualite (`NEW-01` a `NEW-06`).
3. Ouvrir l'epic de migration Go + sous-issues (`GO-EPIC-00` a `GO-15`).
4. Lier chaque sous-issue Go a l'epic, puis prioriser `GO-01..GO-08` avant le reste.

---

## 6) Commandes `gh` utiles (a executer manuellement)

Exemples:

```bash
# Close a fully done issue
gh issue close 31 --repo Ascension-EIP/Ascension --comment "Closing as DoD is fully complete and verified in codebase."

# Edit title/body of an outdated issue
gh issue edit 44 --repo Ascension-EIP/Ascension --title "SERVER: presigned upload URL route (/v1/videos/upload-url)"

# Create a new issue from prepared content
gh issue create --repo Ascension-EIP/Ascension \
  --title "SECURITY: use secure storage for mobile auth tokens" \
  --label "Mobile" \
  --label "type:feature" \
  --label "priority:p1" \
  --body-file /path/to/prepared-issue-body.md
```

---

## 7) Validation finale attendue

Definition de "backlog sain" apres application de ce document:
- aucune issue ouverte avec DoD 100% coche;
- aucune issue ouverte avec endpoints/contrats obsoletes;
- roadmap Go complete, priorisee et liee a un epic;
- templates et politique d'issues formalises (voir second fichier).
