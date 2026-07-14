> **Last updated:** 16th March 2026  
> **Version:** 1.0  
> **Authors:** Darius (Docs), Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# Bloc 1 — M1 — 03 Spécifications fonctionnelles

---

## Table des matières

- [Bloc 1 — M1 — 03 Spécifications fonctionnelles](#bloc-1--m1--03-spécifications-fonctionnelles)
  - [Table des matières](#table-des-matières)
  - [Objectif](#objectif)
  - [Périmètre fonctionnel retenu](#périmètre-fonctionnel-retenu)
    - [Fonctionnalités cœur (MVP soutenable)](#fonctionnalités-cœur-mvp-soutenable)
    - [Fonctionnalités élargies (citées dans le dossier, hors preuve complète d’implémentation ici)](#fonctionnalités-élargies-citées-dans-le-dossier-hors-preuve-complète-dimplémentation-ici)
  - [Acteurs et cas d’usage](#acteurs-et-cas-dusage)
  - [Parcours utilisateur de référence](#parcours-utilisateur-de-référence)
    - [Parcours “Analyse vidéo”](#parcours-analyse-vidéo)
  - [Règles de gestion](#règles-de-gestion)
  - [Critères d’acceptation fonctionnels](#critères-dacceptation-fonctionnels)
  - [Exigences accessibilité (PSH)](#exigences-accessibilité-psh)
  - [Traçabilité besoins -\> fonctions](#traçabilité-besoins---fonctions)

---

## Objectif

Décrire ce que la solution doit faire pour répondre au besoin métier et utilisateur du Bloc 1, avec un périmètre testable et soutenable à l’oral.

Sources utilisées :

- `docs/10-product/prototype-pool/workshop/client-needs-and-functional-scope.md`
- `docs/10-product/prototype-pool/workshop/tech-func-specs.md`
- `docs/10-product/prototype-pool/workshop/context-audit-compliance.md`
- `apps/server/src/inbound/http.rs`
- `apps/ai/src/worker.py`

---

## Périmètre fonctionnel retenu

### Fonctionnalités cœur (MVP soutenable)

1. **Créer un compte / se connecter**.
2. **Obtenir une URL d’upload vidéo**.
3. **Déclencher une analyse asynchrone**.
4. **Consulter le statut, la progression et le résultat d’analyse**.

### Fonctionnalités élargies (citées dans le dossier, hors preuve complète d’implémentation ici)

- Ghost mode avancé.
- Détection de prises enrichie.
- Coaching/routines personnalisées.

Positionnement oral recommandé : distinguer explicitement **“implémenté et démontrable”** de **“spécifié et planifié”**.

---

## Acteurs et cas d’usage

| Acteur                          | Objectif                       | Cas d’usage                                          |
|:--------------------------------|:-------------------------------|:-----------------------------------------------------|
| Grimpeur                        | Recevoir un feedback technique | Upload vidéo -> lancer analyse -> lire résultats     |
| Backend API                     | Orchestrer le flux             | Générer URL présignée, créer analyse, exposer statut |
| Worker IA                       | Produire l’analyse             | Consommer job, traiter vidéo, écrire résultat        |
| Jury/évaluateur (contexte RNCP) | Vérifier la traçabilité        | Contrôler cohérence besoin/specs/audit/chiffrage     |

---

## Parcours utilisateur de référence

### Parcours “Analyse vidéo”

1. L’utilisateur s’authentifie (`/v1/auth/login`).
2. L’utilisateur demande une URL d’upload (`/v1/videos/upload-url`).
3. L’utilisateur déclenche l’analyse (`/v1/analyses`).
4. L’utilisateur suit l’avancement (`GET /v1/analyses/{id}` : `status`, `progress`).
5. L’utilisateur consulte le résultat final (`result_json`, `hints`).

Preuves de flux : `apps/server/src/inbound/http.rs`, `apps/server/src/inbound/http/handlers/analysis/get_analysis.rs`, `apps/ai/src/worker.py`.

---

## Règles de gestion

- Une analyse est liée à une vidéo existante (`video_id`).
- Le cycle d’état d’une analyse inclut au minimum : `pending` -> `completed` ou `failed`.
- La progression (`progress`) passe de `0` à `100` selon les mises à jour worker.
- Les conseils (`hints`) sont “best effort” (absence possible sans invalider toute l’analyse).

---

## Critères d’acceptation fonctionnels

| ID   | Critère                  | Résultat attendu                                      |
|:-----|:-------------------------|:------------------------------------------------------|
| F-01 | Création d’URL d’upload  | Retourne `video_id` + `upload_url`                    |
| F-02 | Création d’analyse       | Retourne `analysis_id`, `job_id`, `status=pending`    |
| F-03 | Suivi d’analyse          | Endpoint de consultation renvoie statut + progression |
| F-04 | Résultat final           | `result_json` disponible quand statut `completed`     |
| F-05 | Résilience erreur worker | Statut passe à `failed` sans boucle infinie de retry  |

---

## Exigences accessibilité (PSH)

Exigences à intégrer dans la définition de “fonctionnalité terminée” :

- Navigation clavier/lecteur d’écran pour les écrans critiques (auth, upload, résultat).
- Libellés explicites pour actions et états de progression.
- Contraste texte/fond conforme au minimum WCAG 2.1 AA.
- Restitution textuelle alternative des résultats visuels (graphes, overlay).

Source d’alignement : `docs/10-product/prototype-pool/workshop/tech-func-specs.md` (section accessibilité).

---

## Traçabilité besoins -> fonctions

| Besoin                      | Fonction couverte                  | Preuve repo                                                      |
|:----------------------------|:-----------------------------------|:-----------------------------------------------------------------|
| Feedback technique objectif | Analyse asynchrone vidéo           | `apps/ai/src/worker.py`                                          |
| Fluidité d’usage            | Upload direct via URL présignée    | `apps/server/src/inbound/http/handlers/video/get_upload_url.rs`  |
| Visibilité utilisateur      | Statut/progress/résultat d’analyse | `apps/server/src/inbound/http/handlers/analysis/get_analysis.rs` |
| Inclusion PSH               | Critères WCAG déclarés dans specs  | `docs/10-product/prototype-pool/workshop/tech-func-specs.md`     |
