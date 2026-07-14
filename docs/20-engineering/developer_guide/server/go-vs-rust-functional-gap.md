# Go vs Rust — Comparaison fonctionnelle serveur

_Date: 2026-04-01_

## Périmètre comparé

- Serveur Go: `apps/server`
- Serveur Rust: `apps/server-rust`
- Axes: domaines métier (`auth`, `users`, `videos`, `analysis`), API HTTP, sécurité/middlewares, persistance, intégrations (PostgreSQL, MinIO, RabbitMQ), exposition API.

---

## Synthèse rapide

- Les deux serveurs couvrent les mêmes domaines principaux: authentification, gestion des utilisateurs, upload vidéo, déclenchement et lecture d’analyse.
- Le serveur **Go** est plus complet sur certains flux API (refresh token, upload completion, download URL, contrôles de rôle appliqués au routeur).
- Le serveur **Rust** est plus avancé sur le **modèle d’analyse** (progression, hints, job id) et sur la **documentation API** (OpenAPI/Swagger intégrée).

---

## Différences fonctionnelles détaillées

## 1) Authentification

### Go (`apps/server`)
- Endpoints:
  - `POST /v1/auth/signup`
  - `POST /v1/auth/signup` + login implicite via `SignupLogin`
  - `POST /v1/auth/login`
  - `DELETE /v1/auth/logout`
  - `PUT /v1/auth/refresh`
- Mécanisme:
  - JWT access token + refresh token stocké côté session.
  - Middlewares appliqués (`auth`, `admin`, `user`) selon groupes de routes.

### Rust (`apps/server-rust`)
- Endpoints:
  - `POST /v1/auth/register`
  - `POST /v1/auth/login`
  - `POST /v1/auth/logout`
- Mécanisme:
  - JWT + cookie `HttpOnly` (`session_token`) défini au login/register.
  - Pas d’endpoint de refresh token observé.
  - Middleware auth implémenté mais non branché explicitement sur les groupes de routes dans `src/inbound/http.rs`.

### Écart
- Go > Rust: refresh token + stratégie rôles effectivement appliquée au routeur.
- Rust > Go: ergonomie web via cookie HttpOnly natif.

---

## 2) Users

### Go
- CRUD users complet sous `/v1/users`.
- Routes protégées avec `auth + admin`.

### Rust
- CRUD users complet sous `/v1/users`.
- Contrôles middleware définis, mais leur application explicite aux routes n’est pas visible dans le routeur principal.

### Écart
- Couverture fonctionnelle quasi équivalente, différence surtout côté wiring sécurité.

---

## 3) Videos

### Go
- Endpoints:
  - `GET /v1/videos/upload-url`
  - `PUT /v1/videos/upload-done/:id`
  - `GET /v1/videos/download-url/:id`
- Flux complet: présign upload, confirmation d’upload, récupération URL de téléchargement.

### Rust
- Endpoints:
  - `POST /v1/videos/upload-url`
- Flux présent mais partiel: pas d’endpoint `upload-done`, pas d’endpoint `download-url`.

### Écart
- Go > Rust: workflow vidéo plus complet.

---

## 4) Analyses IA

### Go
- Endpoints:
  - `POST /v1/analysis`
  - `GET /v1/analysis/:id`
- Modèle/réponse exposée minimaliste: principalement `id`, `status`.
- Table `analysis` sans colonnes `job_id`, `progress`, `hints`.

### Rust
- Endpoints:
  - `POST /v1/analyses`
  - `GET /v1/analyses/{id}`
- Modèle enrichi:
  - `job_id`
  - `progress` (0–100)
  - `hints`
  - `result_json`
  - `processing_time_ms`, etc.
- Migrations dédiées observées:
  - `20260311000001_add_progress_to_analyses.sql`
  - `20260312000001_add_hints_to_analyses.sql`

### Écart
- Rust > Go: observabilité/statut métier d’analyse plus riche.

---

## 5) Documentation API

### Go
- Pas d’OpenAPI/Swagger intégré observé.

### Rust
- OpenAPI + Swagger UI intégrés (`utoipa`, `utoipa-swagger-ui`).

### Écart
- Rust > Go: DX/visibilité API meilleure côté doc.

---

## Ce qui manque à implémenter dans le serveur Go (checklist)

> Objectif: atteindre la parité utile avec les fonctionnalités avancées du serveur Rust, sans casser les flux déjà en place côté Go.

## Priorité P0 — Analyse enrichie (fort impact produit)

- [ ] **Ajouter `job_id` dans la table `analysis`**
  - Cible: `apps/server/migrations/`
  - Action: migration SQL `ALTER TABLE analysis ADD COLUMN job_id UUID ...` + index/contrainte utile.
  - Validation: création d’analyse retourne/persiste un `job_id`.

- [ ] **Ajouter `progress` (0–100) dans la table `analysis`**
  - Cible: `apps/server/migrations/`
  - Action: `progress INTEGER NOT NULL DEFAULT 0`.
  - Validation: lecture API reflète la progression.

- [ ] **Ajouter `hints` dans la table `analysis`**
  - Cible: `apps/server/migrations/`
  - Action: `hints TEXT NULL`.
  - Validation: champs visible en `GET /v1/analysis/:id` quand disponible.

- [ ] **Mettre à jour les DTO DB et modèle Go**
  - Cibles:
    - `apps/server/internal/model/analysis.go`
    - `apps/server/internal/outbound/postgres/dto/` (structure `Analysis`)
  - Action: mapper `job_id`, `progress`, `hints`.
  - Validation: tests repository/handler passent avec nouveaux champs.

- [ ] **Exposer les nouveaux champs dans les réponses HTTP**
  - Cibles:
    - `apps/server/internal/inbound/http/dto/response/analysis.go`
    - handlers analysis
  - Action: enrichir réponse de `GET` (et potentiellement `POST`) avec `job_id`, `progress`, `hints`, `result_json`, `processing_time_ms`.
  - Validation: contrat API vérifié par tests d’intégration.

- [ ] **Ajouter un usecase/repository update progress**
  - Cibles:
    - `apps/server/internal/service/analysis.go`
    - `apps/server/internal/outbound/postgres/analysis.go`
  - Action: méthode dédiée `UpdateAnalysisProgress(id, progress)`.
  - Validation: update transactionnel et borne `0..100`.

## Priorité P1 — Documentation API

- [ ] **Ajouter OpenAPI/Swagger au serveur Go**
  - Cible: `apps/server/internal/inbound/http/`
  - Action: intégrer génération spec + endpoint UI (`/swagger` ou similaire).
  - Validation: routes auth/users/videos/analysis documentées et testables via UI.

## Priorité P2 — Alignement DX/comportement (optionnel)

- [ ] **Évaluer l’ajout d’un cookie `HttpOnly` de session**
  - Cible: handlers auth Go.
  - Action: optionnel selon stratégie frontend (token header-only vs cookie).
  - Validation: règles CORS/CSRF définies et testées.

---

## Plan d’implémentation recommandé (ordre pratique)

1. Migrations DB (`job_id`, `progress`, `hints`).
2. Modèles + DTO persistence (`model`, `postgres/dto`, repo SQL).
3. Service analysis (create/get/update progress).
4. DTO/handlers HTTP analysis.
5. Tests unitaires + intégration analysis.
6. OpenAPI/Swagger.

---

## Critères d’acceptation (Done)

- [ ] `POST /v1/analysis` persiste et renvoie `job_id`.
- [ ] `GET /v1/analysis/:id` expose `progress` et `hints`.
- [ ] Une méthode backend permet de mettre à jour `progress` de façon sûre.
- [ ] Les tests analysis (service + handler + repo) couvrent les nouveaux champs.
- [ ] Une documentation Swagger de l’API Go est accessible et alignée au comportement réel.

---

## Notes de compatibilité

- Conserver les endpoints Go existants (`refresh`, `upload-done`, `download-url`) qui apportent déjà une valeur supérieure sur les flux auth/video.
- Les ajouts recommandés visent la parité sur la richesse de suivi `analysis` et la documentabilité API, sans régression de l’existant.
