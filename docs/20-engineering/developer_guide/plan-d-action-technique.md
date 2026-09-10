<!-- markdownlint-disable MD041 -->

> **Last updated:** 4th September 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Original language:** French  
> **Status:** In progress  
> {.is-warning}

---

# Plan d'Action Technique : Audit, Harmonisation d'Architecture & Refonte Mobile

Ce document rassemble l'ensemble des constats, anomalies identifiées, fonctionnalités manquantes et chantiers techniques nécessaires pour synchroniser et faire évoluer le projet **Ascension** (Backend Go, Worker IA Python et Application Mobile Flutter).

---

## Table of Contents

- [Plan d'Action Technique : Audit, Harmonisation d'Architecture \& Refonte Mobile](#plan-daction-technique--audit-harmonisation-darchitecture--refonte-mobile)
  - [Table of Contents](#table-of-contents)
  - [1. Contexte \& Synthèse Globale](#1-contexte--synthèse-globale)
    - [1.1 Postulat de travail retenu](#11-postulat-de-travail-retenu)
    - [1.2 Les grands axes de travail](#12-les-grands-axes-de-travail)
  - [2. Chantier 1 : Cadrage \& Harmonisation des Contrats d'API](#2-chantier-1--cadrage--harmonisation-des-contrats-dapi)
    - [2.1 Divergences actuelles entre Mobile et Backend](#21-divergences-actuelles-entre-mobile-et-backend)
    - [2.2 Cadrage futur \& Spécification OpenAPI](#22-cadrage-futur--spécification-openapi)
  - [3. Chantier 2 : Backend Go (Parité Fonctionnelle \& Corrections)](#3-chantier-2--backend-go-parité-fonctionnelle--corrections)
    - [3.1 Fonctionnalités perdues lors de la migration Rust vers Go](#31-fonctionnalités-perdues-lors-de-la-migration-rust-vers-go)
    - [3.2 Bugs techniques \& Anomalies SQL identifiés](#32-bugs-techniques--anomalies-sql-identifiés)
    - [3.3 Travaux prioritaires sur le Backend](#33-travaux-prioritaires-sur-le-backend)
  - [4. Chantier 3 : Worker IA (Stabilisation, Environnement \& SAM 3D)](#4-chantier-3--worker-ia-stabilisation-environnement--sam-3d)
    - [4.1 État actuel des pipelines d'analyse](#41-état-actuel-des-pipelines-danalyse)
    - [4.2 Focus sur SAM 3D (`ai_sam3d.py`)](#42-focus-sur-sam-3d-ai_sam3dpy)
    - [4.3 Anomalies de configuration \& Déploiement Docker](#43-anomalies-de-configuration--déploiement-docker)
    - [4.4 Travaux prioritaires sur l'IA](#44-travaux-prioritaires-sur-lia)
  - [5. Chantier 4 : Application Mobile Flutter (Refonte Graphique \& Réseau)](#5-chantier-4--application-mobile-flutter-refonte-graphique--réseau)
    - [5.1 Refonte UI / UX Complète (Design Moderne Grimpeur)](#51-refonte-ui--ux-complète-design-moderne-grimpeur)
    - [5.2 Intégration Réseau \& Gestion de Session](#52-intégration-réseau--gestion-de-session)
    - [5.3 Travaux prioritaires sur le Mobile](#53-travaux-prioritaires-sur-le-mobile)
  - [6. Matrice des Priorités \& Roadmap d'Exécution](#6-matrice-des-priorités--roadmap-dexécution)
    - [Phase 1 : Rétablissement du Flux de Bout en Bout (Court Terme)](#phase-1--rétablissement-du-flux-de-bout-en-bout-court-terme)
    - [Phase 2 : Cadrage Formel \& Standardisation OpenAPI (Moyen Terme)](#phase-2--cadrage-formel--standardisation-openapi-moyen-terme)
    - [Phase 3 : Parité Fonctionnelle Backend \& Données d'Analyse (Moyen Terme)](#phase-3--parité-fonctionnelle-backend--données-danalyse-moyen-terme)
    - [Phase 4 : Refonte Graphique Complète du Mobile Flutter (Moyen/Long Terme)](#phase-4--refonte-graphique-complète-du-mobile-flutter-moyenlong-terme)
    - [Phase 5 : Tests d'Intégration End-to-End \& Monitoring (Long Terme)](#phase-5--tests-dintégration-end-to-end--monitoring-long-terme)

---

## 1. Contexte & Synthèse Globale

Le projet **Ascension** repose sur une architecture événementielle distribuée :

- **Mobile** (`apps/mobile`) : Client Flutter multiplateforme pour la capture vidéo, la visualisation du squelette et le suivi de progression.
- **Backend API Gateway** (`apps/server`) : Serveur Go (Gin) gérant l'authentification, les autorisations, la persistance PostgreSQL, le stockage objet MinIO et la publication des tâches sur RabbitMQ.
- **Worker IA** (`apps/ai`) : Service Python consommant les vidéos pour extraire les keypoints biomécaniques et interroger Google Gemini pour les conseils d'entraînement.

### 1.1 Postulat de travail retenu

Le **Backend Go représente actuellement la base la plus propre, structurée et sécurisée** du dépôt (architecture en couches claire, rate limiting, middlewares de sécurité, gestion propre des transactions).

Par conséquent :

1. **À court terme** : les ajustements d'alignement immédiats (routes, headers, formats d'appels) se feront en adaptant le Mobile et l'IA pour matcher le Backend Go existant.
2. **À moyen terme** : une session de cadrage technique dédiée sera organisée pour figer les conventions de nommage, les verbes HTTP, les structures de données (DTOs) et générer une spécification **OpenAPI / Swagger** faisant autorité.

### 1.2 Les grands axes de travail

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PLAN D'ACTION ASCENSION                           │
├─────────────────┬─────────────────┬────────────────────┬────────────────────┤
│ 1. CADRAGE API  │ 2. BACKEND GO   │ 3. WORKER IA       │ 4. MOBILE FLUTTER  │
├─────────────────┼─────────────────┼────────────────────┼────────────────────┤
│ • Session specs │ • Parité Rust   │ • Fix RabbitMQ/Env │ • Refonte UI/UX    │
│ • OpenAPI 3.0   │ • BDD analyses  │ • MediaPipe sync   │ • Auth Bearer JWT  │
│ • Alignement    │ • Données compl.│ • Roadmap SAM 3D   │ • Cycle upload     │
│   Mobile/IA     │ • Fix bugs SQL  │ • BDD analyses     │ • Dashboard Home   │
└─────────────────┴─────────────────┴────────────────────┴────────────────────┘
```

---

## 2. Chantier 1 : Cadrage & Harmonisation des Contrats d'API

### 2.1 Divergences actuelles entre Mobile et Backend

L'analyse comparative révèle des ruptures de contrat bloquantes entre le client mobile (`ApiService`) et l'API Gateway Go :

| Domaine               | Implémentation Mobile (`api_service.dart`)                        | Implémentation Backend Go (`router.go`)                                                         | Statut / Conséquence                                                             |
| :-------------------- | :---------------------------------------------------------------- | :---------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------- |
| **Inscription**       | `POST /v1/auth/register`<br>Body: `{username, email, password}`   | `POST /v1/auth/signup`<br>Body: `{name, email, password}`                                       | **404 Not Found** (Route inexistante sur le serveur)                             |
| **Headers d'Auth**    | Aucun en-tête `Authorization` transmis sur les requêtes protégées | `authMW` vérifie `Authorization: Bearer <token>` sur `/users`, `/videos`, `/analysis`           | **401 Unauthorized** systématique sur toutes les routes métier                   |
| **Demande d'Upload**  | `POST /v1/videos/upload-url`<br>Body: `{"filename", "user_id"}`   | `GET /v1/videos/upload-url?content_type=...&size=...`                                           | **405 Method Not Allowed** (Méthode POST refusée)                                |
| **Validation Upload** | Étape non appelée par le Mobile                                   | `PUT /v1/videos/upload-done/:id`<br>Vérifie l'objet dans MinIO et passe le statut à `completed` | **Blocage analyse** : la vidéo reste `pending`, le backend refuse de lancer l'IA |
| **Déclenchement IA**  | `POST /v1/analyses`<br>Attend `analysis_id` dans la réponse       | `POST /v1/analysis/`<br>Retourne `{id, status}`                                                 | **404 Not Found** (Pluriel vs singulier) + champ d'ID divergent                  |
| **Lecture Analyse**   | `GET /v1/analyses/:id`                                            | `GET /v1/analysis/:id`                                                                          | **404 Not Found** (Pluriel vs singulier)                                         |
| **Host MinIO**        | Upload direct sur l'URL présignée MinIO (`http://minio:9000/...`) | URL présignée construite avec l'endpoint interne Docker                                         | **Échec réseau mobile** : un smartphone ou émulateur ne résout pas `minio`       |

### 2.2 Cadrage futur & Spécification OpenAPI

Une session de cadrage d'équipe doit formaliser les points suivants :

- **Convention d'URL** : Adopter formellement soit le singulier (`/analysis`, `/user`, `/video`), soit le standard RESTful au pluriel (`/analyses`, `/users`, `/videos`).
- **Standardisation des DTOs** :
  - Unifier les clés d'identification d'utilisateurs (`name` vs `username`).
  - Standardiser les retours de création (`id` vs `analysis_id`, `video_id`).
- **Génération OpenAPI / Swagger** : Mettre en place un outil de documentation automatique (ex: `swaggo/gin-swagger`) pour que le backend serve de contrat unique et vérifiable.

---

## 3. Chantier 2 : Backend Go (Parité Fonctionnelle & Corrections)

### 3.1 Fonctionnalités perdues lors de la migration Rust vers Go

Lors du passage de l'ancien serveur Rust (Axum) au serveur Go (Gin), plusieurs fonctionnalités clés documentées dans `docs/developer_guide/server/go-vs-rust-functional-gap.md` n'ont pas encore été réintégrées dans le serveur Go :

1. **Richesse des réponses d'analyse (`GET /v1/analysis/:id`)** :
   - _Ancien état (Rust)_ : renvoyait `job_id`, `progress` (0–100), `hints` (conseils textuels Gemini), `result_json` (coordonnées des 33 keypoints par frame), et `processing_time_ms`.
   - _État actuel (Go)_ : renvoie uniquement `id` et `status` (`pending` / `completed`). Les données brutes et les conseils sont inaccessibles par l'API REST.
2. **Accès au profil personnel (`GET /v1/users/:id`)** :
   - La route est protégée par `adminMW`, interdisant à un utilisateur authentifié de consulter ou mettre à jour son propre profil.
3. **Historique des analyses et des vidéos** :
   - Aucun endpoint pour lister les analyses d'un utilisateur (`GET /v1/users/me/analyses` ou `GET /v1/analysis?user_id=...`).
4. **Statistiques & Métriques agrégées de grimpe** :
   - Aucun endpoint pour calculer le volume d'entraînement, le taux de détection moyen, ou la progression des angles articulaires.
5. **Documentation d'API intégrée** :
   - Disparition de l'interface Swagger UI qui était générée via `utoipa` en Rust.

### 3.2 Bugs techniques & Anomalies SQL identifiés

1. **Incompatibilité du nom de table SQL entre Go et l'IA** :
   - Le Backend Go insère dans la table `analysis` (singulier) : `INSERT INTO analysis (video_id) ...`
   - Le Worker IA met à jour la table `analyses` (pluriel) : `UPDATE analyses SET status = ...`
   - _Impact_ : Les deux services pointent sur des tables différentes. L'analyse ne passe jamais à `completed` aux yeux du backend.
2. **Migrations orphelines et conflictuelles** :
   - Deux jeux de migrations coexistent dans `apps/server/migrations/` :
     - Format officiel `golang-migrate` : `000001_...up.sql` à `000009_...up.sql` (crée la table `analysis` sans les colonnes `progress` et `hints`).
     - Fichiers par date : `20260307...`, `20260311...`, `20260312...` (non exécutés par `golang-migrate` car dépourvus de `.up.sql`).
3. **Erreur de cible sur le trigger SQL des vidéos** :
   - Dans `000004_create_videos_table.up.sql` :
     ```sql
     CREATE TRIGGER update_videos_updated_at BEFORE UPDATE ON users FOR EACH ROW ...
     ```
     Le trigger s'attache à la table `users` au lieu de `videos`.
4. **Syntaxe MySQL dans une requête PostgreSQL** :
   - Dans `internal/outbound/postgres/auth.go` (`DeleteExpiredSessions`) :
     Utilisation du marqueur `?` au lieu de `$1` pour le paramètre de date.
5. **Faille de sécurité & Bug sur la mise à jour utilisateur** :
   - Dans `internal/inbound/http/dto/request/user.go` : Si le mot de passe est omis dans l'update, le pointeur pointe vers un slice vide, écrasant le mot de passe en base avec une chaîne vide (`""`).
   - Si un mot de passe est fourni lors de l'update, il est sauvegardé en texte clair (pas de hash bcrypt appliqué dans `UpdateUser`).
6. **Payload RabbitMQ partiel (`job_id` manquant)** :
   - Le service Go publie `{"analysis_id": "...", "video_url": "..."}` sans générer de `job_id`. L'IA publie donc l'événement de fin sous `skeleton.completed.unknown`.

### 3.3 Travaux prioritaires sur le Backend

- [ ] **Uniformiser la table SQL d'analyse** : Basculer définitivement sur le nom standard `analyses` (au pluriel), intégrer les colonnes `job_id`, `progress`, `hints`, `result_json`, `processing_time_ms`.
- [ ] **Nettoyer le dossier `migrations/`** : Supprimer les fichiers timestamp orphelins et consolider la séquence numérotée `000001` à `000010_...up.sql`. Corriger le trigger `videos` et la requête de suppression de session.
- [ ] **Enrichir le DTO de retour `AnalysisInfoResponse`** : Renvoyer l'intégralité des métriques et des conseils IA sur `GET /v1/analysis/:id`.
- [ ] **Générer et transmettre un `job_id` (UUID)** dans le payload RabbitMQ publié vers `vision.skeleton`.
- [ ] **Débloquer la consultation du profil utilisateur** : Autoriser l'accès à son propre profil sans exiger le rôle `admin`.
- [ ] **Sécuriser la mise à jour de profil** : Hasher systématiquement le mot de passe avec bcrypt s'il est renseigné, et ignorer le champ s'il est nul.
- [ ] **Intégrer Swagger/OpenAPI** : Ajouter `swaggo/gin-swagger` et configurer la route `GET /swagger/*any`.

---

## 4. Chantier 3 : Worker IA (Stabilisation, Environnement & SAM 3D)

### 4.1 État actuel des pipelines d'analyse

Le dossier `apps/ai/src/` contient deux pipelines d'analyse :

```
apps/ai/src/
├── worker.py          # Démon RabbitMQ principal (écoute vision.skeleton)
├── ai_mediapipe.py    # [ACTIF] Pipeline 3D MediaPipe + Google Gemini
└── ai_sam3d.py        # [SOMMEIL] Pipeline SAM 3D Body + MHR-70 (554 lignes)
```

- **Pipeline MediaPipe (`ai_mediapipe.py`) - Opérationnel** :
  - Extraction de 33 points clés squelettiques 3D normalisés par frame.
  - Calcul trigonométrique des angles articulaires clés (épaules, coudes, hanches, genoux).
  - Échantillonnage intelligent des données pour générer un prompt compact.
  - Appel à Google Gemini (`gemini-3.1-flash-lite-preview` / `gemini-1.5-flash`) fournissant 3 conseils techniques personnalisés avec horodatage (`[3200ms]`).
  - Émission de la progression en BDD toutes les 30 frames.

### 4.2 Focus sur SAM 3D (`ai_sam3d.py`)

Le pipeline **SAM 3D Body** vise à reconstruire un modèle corporel complet en 3D (squelette MHR-70 avec 70 points de repère, maillage volumétrique et angles 3D fins).

**Pourquoi est-il désactivé aujourd'hui ?**

1. **Dépendances lourdes absentes** : `torch`, `torchvision`, `sam_3d_body`, `tqdm` ne sont **pas déclarés** dans `apps/ai/pyproject.toml`.
2. **Ressources matérielles requises** : SAM 3D s'appuie sur le backbone DINOv3 et requiert une carte graphique NVIDIA avec CUDA sous peine de temps de traitement prohibitifs (plusieurs dizaines de secondes par seconde de vidéo sur CPU).
3. **Poids du modèle manquant** : Le modèle exige le téléchargement d'un checkpoint PyTorch volumineux (`./checkpoints/sam-3d-body-dinov3/model.ckpt`) non versionné dans Git.

**Orientation retenue pour SAM 3D :**

- **Conserver MediaPipe par défaut** : Il s'exécute immédiatement sur CPU en production et en local, sans surcoût d'infrastructure.
- **Isoler SAM 3D dans un profil d'exécution distinct** : Garder le code `ai_sam3d.py` propre, créer un environnement optionnel (ex: `[project.optional-dependencies] gpu = ["torch", "sam-3d-body"]`) et prévoir son activation quand l'infrastructure GPU dédiée sera provisionnée.

### 4.3 Anomalies de configuration & Déploiement Docker

1. **Hôte RabbitMQ incorrect dans `docker-compose.yml`** :
   - Le service `ai-worker` a `RABBITMQ_URL=amqp://ascension:ascension@localhost:5672`.
   - Dans Docker, `localhost` isole le conteneur du conteneur `rabbitmq`. L'URL doit être `amqp://ascension:ascension@rabbitmq:5672`.
2. **Clé API Gemini absente du conteneur** :
   - `GEMINI_API_KEY` n'est pas transmise au service `ai-worker` dans `docker-compose.yml`. En environnement conteneurisé, la génération des conseils échoue silencieusement.
3. **Divergence de modèle MediaPipe** :
   - `Dockerfile` télécharge `pose_landmarker_lite.task`.
   - `scripts/download-model.sh` télécharge `pose_landmarker_heavy.task`.
4. **Fichier `requirements.txt` invalide** :
   - Fait référence à des sous-dossiers `-r requirements/base.txt` inexistants. Le projet utilise désormais `uv` et `pyproject.toml`.

### 4.4 Travaux prioritaires sur l'IA

- [x] **Corriger `docker-compose.yml`** : Remplacer `localhost` par `rabbitmq` et injecter `GEMINI_API_KEY: ${GEMINI_API_KEY}`.
- [ ] **Harmoniser le nom de la table SQL** : S'assurer que `worker.py` met à jour la même table que celle requêtée par le Backend Go (`analyses`).
- [ ] **Prendre en compte le `job_id`** envoyé par RabbitMQ pour router correctement les événements de sortie `skeleton.completed.<job_id>`.
- [ ] **Harmoniser la version du modèle MediaPipe** (`pose_landmarker_heavy.task` pour la précision de pose).
- [ ] **Nettoyer `requirements.txt`** pour refléter la configuration `uv` / `pyproject.toml`.

---

## 5. Chantier 4 : Application Mobile Flutter (Refonte Graphique & Réseau)

### 5.1 Refonte UI / UX Complète (Design Moderne Grimpeur)

L'interface actuelle est jugée **austère, peu attrayante et datée** ("moche"). Une refonte graphique complète est nécessaire pour positionner Ascension comme une application sportive premium et technologique.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       AXES DE REFONTE VISUELLE MOBILE                       │
├───────────────────────┬───────────────────────┬─────────────────────────────┤
│ CHARTE & COULEURS     │ TYPOGRAPHIE & STYLE   │ EXPÉRIENCE DE GRIMPE        │
├───────────────────────┼───────────────────────┼─────────────────────────────┤
│ • Thème sombre épuré  │ • Typo sport/tech     │ • Feedback temps réel       │
│ • Accents vert/lime   │ • Cartes néomorphiques│ • Superposition squelette   │
│   ou orange électrique│   avec bordures fines │   haute précision           │
│ • Contrastes forts    │ • Micro-interactions  │ • Visualisation 3D fluide   │
└───────────────────────┴───────────────────────┴─────────────────────────────┘
```

#### Écrans cibles de la refonte graphique :

1. **`HomePage` (Actuellement placeholder)** :
   - _Actuel_ : Simple texte "Accueil bientôt disponible !".
   - _Cible_ : Dashboard grimpeur moderne :
     - Widget "Dernière ascension" avec snapshot du squelette et note technique.
     - Raccourci central "Nouvelle Analyse" proéminent (bouton flottant / hero banner).
     - Carte "Conseil d'entraînement du jour" propulsée par l'IA.
     - Résumé rapide des statistiques hebdomadaires (voies grimpées, temps sous tension).
2. **`UploadPage` & Lecteur de Sélection Vidéo** :
   - Zone de drop/sélection modernisée avec animations d'onde lors de l'enregistrement.
   - Lecteur de prévisualisation plein écran avec recadrage dynamique et slider de rognage de vidéo (pour ne garder que la section grimpée).
   - Écran d'attente d'analyse dynamique : remplacer les slides statiques par une animation 3D ou un skeleton animé montrant l'IA en train de "scanner" la vidéo, avec barre de progression temps réel (0–100%).
3. **`AnalysisViewPage` (Visualiseur de Performance)** :
   - **Onglet Squelette** : Superposition vidéo transparente, tracés néon des segments corporels, affichage des angles critiques en surbrillance (vert = optimal, rouge = angle sous tension/fermé).
   - **Onglet Angles & Biomécanique** : Graphiques temporels interactifs (`fl_chart`) modernes, synchronisés au millimètre près avec la tête de lecture vidéo.
   - **Onglet Conseils IA** : Cartes de conseils ergonomiques avec badges temporels cliquables (`[02:14]`) qui recalent directement la vidéo à l'instant du mouvement fautif.
4. **`StatsPage` (Historique & Statistiques)** :
   - Graphiques d'évolution dans le temps, heatmap des prises sollicitées, jauge de symétrie corporelle (bras gauche vs bras droit).
   - Filtres par date, cotation ou type de bloc.
5. **`ProfilePage`** :
   - Fiche morphologique visuelle (taille, envergure / ape index, poids).
   - Mannequin corporel interactif pour indiquer les zones de blessures ou faiblesses.

### 5.2 Intégration Réseau & Gestion de Session

- **Authentification & Headers JWT** :
  - Modifier [`api_service.dart`](file:///home/toronicolas/Epitech/EIP/Ascension/apps/mobile/lib/core/network/api_service.dart) pour injecter systématiquement l'en-tête :
    ```dart
    'Authorization': 'Bearer $token'
    ```
- **Gestion du rafraîchissement silencieux des tokens** :
  - Si une requête renvoie `401 Unauthorized`, appeler automatiquement `PUT /v1/auth/refresh` avec le `refresh_token` pour obtenir un nouvel `access_token` avant de rejouer la requête d'origine.
- **Workflow d'upload vidéo conforme au Backend** :
  - **Étape 1** : `GET /v1/videos/upload-url?content_type=video/mp4&size=...` ➔ Récupération de l'URL présignée MinIO et du `video_id`.
  - **Étape 2** : `PUT <presignedUrl>` ➔ Upload direct des octets vidéo sur MinIO.
  - **Étape 3** : `PUT /v1/videos/upload-done/:video_id` ➔ Confirmation d'upload auprès du backend.
  - **Étape 4** : `POST /v1/analysis` avec `{"video_id": "..."}` ➔ Lancement du calcul IA.
  - **Étape 5** : Polling `GET /v1/analysis/:id` pour suivre le progrès et afficher les résultats.

### 5.3 Travaux prioritaires sur le Mobile

- [ ] **Mettre à jour `ApiService`** : Aligner les routes, méthodes et paramètres sur le serveur Go (`/v1/auth/signup`, `/v1/analysis`, `GET upload-url`).
- [ ] **Injecter le Bearer Token JWT** dans toutes les requêtes HTTP nécessitant une authentification.
- [ ] **Implémenter l'appel à `/v1/videos/upload-done/:id`** dans la séquence de `VideoUpload`.
- [ ] **Concevoir la nouvelle charte graphique** (Maquettes / composants UI Flutter réutilisables).
- [ ] **Implémenter le nouveau dashboard `HomePage`**.
- [ ] **Moderniser l'interface de visualisation d'analyse (`AnalysisViewPage`)**.

---

## 6. Matrice des Priorités & Roadmap d'Exécution

```mermaid
flowchart TD
    subgraph Phase 1 [Phase 1 : Rétablissement du Flux End-to-End]
        P1_A[1. Fix docker-compose & env IA]
        P1_B[2. Alignement immédiat ApiService Mobile]
        P1_C[3. Harmonisation table BDD 'analyses']
    end

    subgraph Phase 2 [Phase 2 : Cadrage & Contrats API]
        P2_A[4. Réunion cadrage conventions API]
        P2_B[5. Intégration Swagger / OpenAPI Go]
    end

    subgraph Phase 3 [Phase 3 : Parité Backend & Données]
        P3_A[6. Exposition result_json & hints dans GET /analysis/:id]
        P3_B[7. Endpoints profil personnel & historique]
        P3_C[8. Endpoints statistiques grimpeur]
    end

    subgraph Phase 4 [Phase 4 : Refonte UI/UX Mobile]
        P4_A[9. Nouveau Design System Flutter]
        P4_B[10. Refonte Dashboard HomePage]
        P4_C[11. Refonte écran Visualisation Analyse & Stats]
    end

    Phase 1 --> Phase 2
    Phase 2 --> Phase 3
    Phase 3 --> Phase 4
```

### Phase 1 : Rétablissement du Flux de Bout en Bout (Court Terme)

_Objectif : Pouvoir uploader une vidéo depuis le téléphone, la faire traiter par MediaPipe et Gemini, et afficher le résultat sans crash._

1. **Docker / IA** : Corriger `RABBITMQ_URL` et transmettre `GEMINI_API_KEY` dans [`docker-compose.yml`](file:///home/toronicolas/Epitech/EIP/Ascension/docker-compose.yml).
2. **Base de données** : Aligner le Backend et l'IA sur la table `analyses` (au pluriel) avec les colonnes `progress` et `hints`.
3. **Mobile** : Corriger [`api_service.dart`](file:///home/toronicolas/Epitech/EIP/Ascension/apps/mobile/lib/core/network/api_service.dart) pour envoyer le token JWT Bearer, utiliser la route `GET /v1/videos/upload-url`, exécuter l'étape `upload-done`, et corriger les routes `/v1/auth/signup` et `/v1/analysis`.

### Phase 2 : Cadrage Formel & Standardisation OpenAPI (Moyen Terme)

_Objectif : Définir une fois pour toutes les contrats d'API pour que toute l'équipe travaille sur le même référentiel._

1. **Atelier technique** : Valider définitivement le nom des routes (singulier vs pluriel) et la forme des DTOs.
2. **Swagger Backend** : Mettre en place `swaggo` sur l'API Go pour générer une doc interactive et la spec `swagger.json`.
3. **Clients synchronisés** : Vérifier la conformité du code Flutter et Python avec la spec générée.

### Phase 3 : Parité Fonctionnelle Backend & Données d'Analyse (Moyen Terme)

_Objectif : Rattraper les fonctionnalités de l'ancien serveur Rust._

1. **Enrichissement de `GET /v1/analysis/:id`** : Transmettre l'intégralité des données d'analyse (`result_json`, `hints`, `progress`, `job_id`).
2. **Gestion de profil** : Débloquer la consultation et la mise à jour de son profil pour chaque utilisateur connecté.
3. **Historique & Statistiques** : Créer les endpoints d'historique utilisateur pour ne plus dépendre du cache local du téléphone.

### Phase 4 : Refonte Graphique Complète du Mobile Flutter (Moyen/Long Terme)

_Objectif : Transformer l'application en une expérience utilisateur moderne, dynamique et valorisante._

1. **Création de la nouvelle identité visuelle** : Palette sombre, accents sportifs, typographie nette, composants néomorphiques légers.
2. **Développement du nouveau dashboard `HomePage`** : Remplacer l'écran vide par un tableau de bord complet avec métriques et actions rapides.
3. **Modernisation du visualiseur `AnalysisViewPage`** : Superposition vidéo haute performance, timecodes interactifs sur les conseils d'entraînement Gemini.
4. **Refonte des statistiques `StatsPage`** : Visualisation de l'évolution de la technique et des volumes de grimpe.

### Phase 5 : Tests d'Intégration End-to-End & Monitoring (Long Terme)

_Objectif : Garantir la non-régression de l'architecture._

1. **Pipeline de test E2E** : Automatiser un test simulant l'envoi d'une vidéo test jusqu'à la vérification du résultat en BDD.
2. **Monitoring** : Instrumentation Prometheus / Grafana / Loki pour surveiller la latence des analyses IA et le débit de traitement.
