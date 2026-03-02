> **Last updated:** 26th February 2026  
> **Version:** 1.0  
> **Authors:** Nicolas  
> **Status:** In Progress  
> {.is-warning}  

---

# Stack Summary

**Résumé De La Stack**

Ce document donne une vue d'ensemble concise de la stack technique utilisée dans le monorepo `Ascension` et des principaux composants décrits dans le dossier `docs/developer_guide/architecture`.

**Contexte général**
- **Monorepo**: Organisation en mono-repository géré avec [moonrepo](https://moonrepo.dev), regroupant les services backend, mobile et AI dans un seul dépôt Git.
- **Environnements**: Support pour `development`, `staging` et `production` (déploiements et composantes décrits dans `deployment/`).

**Langages & frameworks principaux**
- **Backend (server)**: Rust — `apps/server/` (avec `Cargo.toml`). Langage choisi pour performance et sécurité mémoire.
- **Mobile**: Flutter — `apps/mobile/` (avec `pubspec.yaml`). Application mobile multiplateforme.
- **AI / ML**: Python — `apps/ai/` (avec `requirements.txt`). Workers organisés en 2 pipelines : Pipeline Vision (détection de prises, squelettisation MediaPipe, conseils, mode fantôme) et Pipeline Entraînement (programmes personnalisés).

**Infrastructure & Conteneurisation**
- **Docker & Compose**: `docker-compose.yml` à la racine de `Ascension/` pour orchestrer les services locaux (PostgreSQL, RabbitMQ, MinIO, API, Worker).
- **Déploiement**: Guides séparés pour `development`, `staging` et `production` dans `deployment/`.

**Outils de développement & automatisation**
- **moonrepo**: Gestionnaire de tâches du monorepo. Chaque projet possède un `moon.yml` définissant ses tâches (`dev`, `build`, `test`, `lint`).
  - Lancer un service : `moon run server:dev`
  - Tester tous les projets : `moon run :test`
  - Tester les projets affectés uniquement : `moon run :test --affected`
- **Toolchain**: Les versions de Rust et Python sont fixées dans `.moon/toolchain.yml`.
- **Package managers**: `Cargo.toml` pour Rust ; `pubspec.yaml` pour Flutter ; `requirements.txt` pour Python.

**Observabilité & workflows**
- **Workflows**: Flows métiers et pipelines (ex. `workflows/video-analysis-flow.md`) décrivant la chaîne d'analyse vidéo.

**Structure de dépôt (points clés)**
- **`.moon/`** : Configuration du workspace moonrepo (`workspace.yml`, `toolchain.yml`).
- **`apps/server/`** (Rust) — service API principal.
- **`apps/mobile/`** (Flutter) — application mobile multiplateforme.
- **`apps/ai/`** (Python) — workers AI et modèles ML.
- **`docs/`** — guides, architecture et pré-prompts AI.

**Recommandations opérationnelles rapides**
- **Local dev**: Installer `moon`, cloner le repo (sans `--recursive`), copier `.env.example` → `.env`, lancer `docker-compose up -d`, puis `moon run server:dev`.
- **CI/CD**: Utiliser `moon run :test --affected` et `moon run :lint --affected` dans GitHub Actions pour n'exécuter que les projets modifiés.
- **Extensibilité**: Ajouter un nouveau service sous `apps/<nom>/`, créer son `moon.yml`, et l'enregistrer dans `.moon/workspace.yml`.

**Où regarder pour plus de détails**
- `MONOREPO_GUIDE.md` — règles et bonnes pratiques du monorepo moonrepo.
- `system-overview.md` — vue système et composants.
- `deployment/` — procédures et guides d'environnement.
- `workflows/video-analysis-flow.md` — exemple de pipeline métier.

---
Ce résumé vise à fournir une lecture rapide de la stack utilisée ; je peux étoffer chaque section si tu le souhaites.
