> **Last updated:** 16th March 2026  
> **Version:** 1.0  
> **Authors:** Darius (Docs), Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# Bloc 1 — M1 — 04 Spécifications techniques

---

## Table des matières

- [Bloc 1 — M1 — 04 Spécifications techniques](#bloc-1--m1--04-spécifications-techniques)
  - [Table des matières](#table-des-matières)
  - [Objectif](#objectif)
  - [Architecture technique retenue](#architecture-technique-retenue)
  - [Composants et responsabilités](#composants-et-responsabilités)
  - [Contrat API réellement exposé](#contrat-api-réellement-exposé)
  - [Données et persistance](#données-et-persistance)
  - [Chaîne opérationnelle et points de rupture](#chaîne-opérationnelle-et-points-de-rupture)
    - [Chaîne nominale](#chaîne-nominale)
    - [Ruptures potentielles identifiées](#ruptures-potentielles-identifiées)
  - [Exigences non fonctionnelles](#exigences-non-fonctionnelles)
  - [Exigences accessibilité techniques (PSH)](#exigences-accessibilité-techniques-psh)
  - [Découpage en livrables testables](#découpage-en-livrables-testables)

---

## Objectif

Définir la traduction technique du besoin fonctionnel M1 avec des composants, interfaces et contraintes vérifiables dans le code actuel.

---

## Architecture technique retenue

Architecture distribuée asynchrone (API + worker IA + services infra) :

- **Mobile** : Flutter (`apps/mobile`).
- **API** : Rust/Axum (`apps/server`).
- **Worker IA** : Python (`apps/ai/src/worker.py`).
- **Persistance** : PostgreSQL.
- **Messaging** : RabbitMQ.
- **Stockage objet** : MinIO/S3.

Références : `docker-compose.yml`, `apps/server/src/main.rs`, `apps/ai/src/worker.py`.

---

## Composants et responsabilités

| Composant             | Responsabilité principale                                  | Référence                                                    |
|:----------------------|:-----------------------------------------------------------|:-------------------------------------------------------------|
| API Rust              | Exposer endpoints, orchestrer jobs, persister état         | `apps/server/src/inbound/http.rs`, `apps/server/src/main.rs` |
| Worker IA             | Consommer job, analyser vidéo, publier fin de traitement   | `apps/ai/src/worker.py`                                      |
| Publisher RabbitMQ    | Déclarer queue/exchange durables, publier jobs persistants | `apps/server/src/outbound/rabbitmq.rs`                       |
| Repository PostgreSQL | Requêtes SQL paramétrées et mapping domaine                | `apps/server/src/outbound/postgresql.rs`                     |
| Config runtime        | Charger variables d’environnement critiques                | `apps/server/src/config.rs`                                  |

---

## Contrat API réellement exposé

D’après `apps/server/src/inbound/http.rs` :

- `POST /v1/auth/register`
- `POST /v1/auth/login`
- `POST /v1/auth/logout`
- `POST /v1/videos/upload-url`
- `POST /v1/analyses`
- `GET /v1/analyses/{id}`
- CRUD users sous `/v1/users/*`

NB : ces routes sont la base technique démontrable pour le Bloc 1. Les routes métier plus larges documentées dans `docs/20-engineering/developer_guide/architecture/specifications/api-specification.md` relèvent en partie d’une cible produit étendue.

---

## Données et persistance

Éléments techniques observés :

- `analyses` créée par migration SQL dédiée.
- Ajout de `progress` (suivi temps réel) et `hints` (restitution textuelle) par migrations incrémentales.

Références :

- `apps/server/migrations/20260307000002_create_analyses_table.sql`
- `apps/server/migrations/20260311000001_add_progress_to_analyses.sql`
- `apps/server/migrations/20260312000001_add_hints_to_analyses.sql`

---

## Chaîne opérationnelle et points de rupture

### Chaîne nominale

1. Upload URL générée par API.
2. Vidéo uploadée sur MinIO/S3.
3. Job publié en queue `vision.skeleton`.
4. Worker traite la vidéo.
5. Résultat écrit en DB + événement publié.
6. API restitue statut et résultat.

### Ruptures potentielles identifiées

- RabbitMQ indisponible (publication/consommation).
- DB indisponible au moment du writeback du worker.
- Erreur traitement IA (statut `failed`).
- Désalignement documentaire entre cible et implémentation effective.

Mitigations déjà présentes :

- Queue durable + messages persistants.
- Retry de connexion RabbitMQ côté worker.
- Gestion explicite du `failed` avec `nack` sans requeue infini.

---

## Exigences non fonctionnelles

- **Maintenabilité** : séparation claire des responsabilités (`inbound`, `outbound`, `usecase`).
- **Scalabilité** : worker découplé via queue.
- **Observabilité minimale** : logs structurés côté API et worker.
- **Sécurité de base** : JWT/cookie HttpOnly + rate limiting + config par env.

---

## Exigences accessibilité techniques (PSH)

Pour être conformes au besoin Bloc 1, les specs techniques incluent :

- APIs capables de fournir des contenus textuels exploitables par lecteur d’écran (ex. `hints`).
- Front mobile devant garantir lisibilité, vocalisation et alternatives textuelles des éléments visuels.
- Validation accessibilité à intégrer aux critères de recette (pas uniquement au design).

---

## Découpage en livrables testables

| Lot | Livrable             | Test d’acceptation                                   |
|:----|:---------------------|:-----------------------------------------------------|
| L1  | Auth + session       | Login/logout fonctionnels                            |
| L2  | Upload URL vidéo     | URL présignée valide                                 |
| L3  | Création analyse     | Job créé + statut `pending`                          |
| L4  | Pipeline worker      | `completed`/`failed` cohérent + `progress`           |
| L5  | Restitution résultat | `GET /v1/analyses/{id}` renvoie données exploitables |
