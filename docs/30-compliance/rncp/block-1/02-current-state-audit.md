> **Last updated:** 16th March 2026  
> **Version:** 1.0  
> **Authors:** Darius (Docs), Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# Bloc 1 — M1 — 02 Audit de l’existant (technique, fonctionnel, sécurité)

---

## Table des matières

- [Bloc 1 — M1 — 02 Audit de l’existant (technique, fonctionnel, sécurité)](#bloc-1--m1--02-audit-de-lexistant-technique-fonctionnel-sécurité)
  - [Table des matières](#table-des-matières)
  - [Objectif et périmètre](#objectif-et-périmètre)
  - [Méthodologie d’audit](#méthodologie-daudit)
  - [Audit technique](#audit-technique)
    - [1) Architecture exécutable observée](#1-architecture-exécutable-observée)
    - [2) Flux technique principal vérifié](#2-flux-technique-principal-vérifié)
    - [3) Modèle de données observé (implémenté)](#3-modèle-de-données-observé-implémenté)
  - [Audit fonctionnel](#audit-fonctionnel)
  - [Audit sécurité](#audit-sécurité)
  - [Audit accessibilité (PSH)](#audit-accessibilité-psh)
  - [Contraintes et opportunités](#contraintes-et-opportunités)
    - [Contraintes](#contraintes)
    - [Opportunités](#opportunités)
  - [Traçabilité RNCP M1 (O3, O4)](#traçabilité-rncp-m1-o3-o4)

---

## Objectif et périmètre

Dresser un état de l’existant vérifiable dans le repo : architecture, flux applicatifs, sécurité de base, points forts et limites.

Périmètre audité :

- `apps/server/**`
- `apps/ai/**`
- `apps/mobile/**`
- `docker-compose.yml`
- `docs/10-product/prototype-pool/workshop/*`
- `docs/20-engineering/developer_guide/architecture/specifications/*`

---

## Méthodologie d’audit

Méthode appliquée (O4) :

1. **Audit documentaire** des livrables produit/ingénierie.
2. **Audit de configuration** (`docker-compose.yml`, `moon.yml`, `apps/ai/moon.yml`).
3. **Audit code** sur les points critiques (routes API, pipeline IA, migrations DB, middleware auth).
4. **Consolidation** en contraintes/opportunités et écarts à combler pour l’oral.

---

## Audit technique

### 1) Architecture exécutable observée

- **Monorepo** orchestré via moonrepo (`moon.yml`).
- **Backend Rust** (`apps/server`) avec Axum + SQLx + Lapin (`apps/server/Cargo.toml`).
- **Worker IA Python** (`apps/ai/src/worker.py`) consommant la queue `vision.skeleton`.
- **Infra locale** Docker Compose (`docker-compose.yml`) : PostgreSQL, RabbitMQ, MinIO, server, ai-worker.

### 2) Flux technique principal vérifié

- API expose `POST /v1/videos/upload-url`, `POST /v1/analyses`, `GET /v1/analyses/{id}` (`apps/server/src/inbound/http.rs`).
- Le worker IA :
  - télécharge depuis S3/MinIO,
  - calcule l’analyse (`analyze`),
  - met à jour PostgreSQL (`_update_analysis`),
  - publie un événement (`_publish_event`),
  - ack/nack le message (`apps/ai/src/worker.py`).

### 3) Modèle de données observé (implémenté)

- Table `analyses` créée par migration avec `status`, `result_json`, `processing_time_ms`.
- Colonnes `progress` et `hints` ajoutées par migrations ultérieures (`apps/server/migrations/20260311000001_add_progress_to_analyses.sql`, `apps/server/migrations/20260312000001_add_hints_to_analyses.sql`).

---

## Audit fonctionnel

Fonctionnalités prouvées par code/API :

- **Auth** : register/login/logout (`/v1/auth/*`).
- **Upload vidéo** : URL présignée (`/v1/videos/upload-url`).
- **Analyse asynchrone** : déclenchement + consultation (`/v1/analyses`, `/v1/analyses/{id}`).
- **CRUD users** en API (`/v1/users/*`) présent côté serveur.

Constat de cadrage :

- Le périmètre documentaire produit mentionne des capacités plus larges (ghost, hold detection, coaching), mais l’existant serveur audité expose surtout un socle auth/upload/analysis/user. Cela reste cohérent avec un cadrage MVP.

---

## Audit sécurité

Contrôles identifiés dans l’existant :

- **Rate limiting** via `tower_governor` (`apps/server/src/inbound/http.rs`).
- **Authentification** : token JWT via header Bearer ou cookie HttpOnly `session_token` (`apps/server/src/inbound/http/middleware/auth.rs`).
- **Transport de secrets/config** par variables d’environnement (`apps/server/src/config.rs`, `docker-compose.yml`).
- **Persistance jobs** RabbitMQ : queue durable et messages persistants (`apps/server/src/outbound/rabbitmq.rs`, `apps/ai/src/worker.py`).
- **Requêtes SQL paramétrées** dans le repository PostgreSQL (`apps/server/src/outbound/postgresql.rs`).

Point de vigilance :

- Le fichier `docker-compose.yml` contient des valeurs locales explicites pour certains secrets de développement ; c’est acceptable en local mais à isoler strictement en environnements partagés.

---

## Audit accessibilité (PSH)

État actuel observable :

- Les exigences PSH sont bien documentées côté spécifications (`docs/10-product/prototype-pool/workshop/tech-func-specs.md`).
- Côté mobile (`apps/mobile/lib`), on observe des éléments favorables (thème cohérent, tooltips ponctuels), mais peu de traces explicites d’une stratégie accessibilité systématique (sémantique lecteur d’écran, check-list RGAA/WCAG outillée).

Conclusion PSH audit :

- **Intention claire au niveau specs**, **preuve d’implémentation partielle** dans le code actuel. À expliciter en oral comme axe de sécurisation.

---

## Contraintes et opportunités

### Contraintes

- Forte dépendance aux composants infra (RabbitMQ, PostgreSQL, MinIO) pour le flux d’analyse.
- Alignement nécessaire entre documentation “cible produit” et API effectivement exposée.
- Exigences PSH à rendre mesurables (pas seulement déclaratives).

### Opportunités

- Base technique déjà modulaire par service (`apps/server`, `apps/ai`, `apps/mobile`).
- Pipeline asynchrone robuste pour absorber la charge progressive.
- Migrations SQL versionnées favorables à l’évolutivité.

---

## Traçabilité RNCP M1 (O3, O4)

| Observable                                    | Éléments de preuve                                                                                                   | Couverture |
|:----------------------------------------------|:---------------------------------------------------------------------------------------------------------------------|:-----------|
| **O3** — audit technique/fonctionnel/sécurité | `docker-compose.yml`, `apps/server/src/inbound/http.rs`, `apps/ai/src/worker.py`, migrations SQL, docs atelier audit | **Forte**  |
| **O4** — méthode d’audit explicitée           | Démarche en 4 étapes + sources et limites documentées ici                                                            | **Forte**  |
