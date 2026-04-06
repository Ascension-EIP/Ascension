<!-- markdownlint-disable MD041 -->

> **Last updated:** 6th April 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO, Ascension Team  
> **Status:** Final  
> {.is-success}

---

# Ascension Action Plan

---

## Table of Contents

- [Ascension Action Plan](#ascension-action-plan)
  - [Table of Contents](#table-of-contents)
  - [1. Context](#1-context)
    - [1.1 Origine du projet](#11-origine-du-projet)
    - [1.2 Problème identifié](#12-problème-identifié)
    - [1.3 Solution proposée](#13-solution-proposée)
    - [1.4 Objectif global et résultat attendu](#14-objectif-global-et-résultat-attendu)
    - [1.5 Inside track choisi](#15-inside-track-choisi)
    - [1.6 Parties prenantes et appuis externes](#16-parties-prenantes-et-appuis-externes)
  - [2. Technical Specifications](#2-technical-specifications)
    - [2.1 Stack visée](#21-stack-visée)
    - [2.2 Méthode de travail technique](#22-méthode-de-travail-technique)
    - [2.3 Périmètre fonctionnel suivi dans ce plan](#23-périmètre-fonctionnel-suivi-dans-ce-plan)
    - [2.4 User stories de référence](#24-user-stories-de-référence)
    - [2.5 Milestones planifiés](#25-milestones-planifiés)
    - [2.6 Definition of Done transversale](#26-definition-of-done-transversale)
  - [3. Non-Technical Specifications](#3-non-technical-specifications)
    - [3.1 Mentorat et gouvernance](#31-mentorat-et-gouvernance)
    - [3.2 Topic mandatory - Evaluate and integrate new technologies](#32-topic-mandatory---evaluate-and-integrate-new-technologies)
    - [3.3 Topic optional - Collaborate with technical experts](#33-topic-optional---collaborate-with-technical-experts)
    - [3.4 Topic optional - Protect and enhance your technology](#34-topic-optional---protect-and-enhance-your-technology)
    - [3.5 Topic optional - Develop community contributions](#35-topic-optional---develop-community-contributions)

---

## 1. Context

### 1.1 Origine du projet

Ascension est un projet EIP développé par une équipe de 5 personnes passionnées d’escalade et de technologie.

Le projet est né d’un besoin vécu directement sur le terrain : progresser techniquement en escalade coûte souvent cher, prend du temps, et dépend de la disponibilité d’un coach humain.

### 1.2 Problème identifié

Les problèmes principaux sont les suivants :

- Les grimpeurs ne voient pas facilement leurs micro-erreurs de posture.
- Le coaching expert est limité en disponibilité et en coût.
- La lecture de voie et la compréhension d’une bonne bêta sont difficiles sans support visuel.
- Les outils existants ne couvrent pas un parcours complet, de l’analyse à la progression continue.

### 1.3 Solution proposée

Ascension transforme un smartphone en coach d’escalade assisté par IA.

Le produit permet de :

- analyser une grimpe à partir d’une vidéo,
- reconstruire et expliquer le mouvement,
- comparer la montée avec une trajectoire de référence (mode fantôme),
- fournir des conseils personnalisés,
- accompagner la progression dans le temps.

### 1.4 Objectif global et résultat attendu

L’objectif de cet Action Plan est de définir clairement comment l’équipe travaille jusqu’au GreenLight et comment elle sécurise l’exécution du projet.

Résultat attendu :

- un pilotage clair,
- des jalons mesurables,
- des priorités connues de tous,
- des preuves régulières de progression technique.

### 1.5 Inside track choisi

Ascension est inscrit dans la **Technical Track**.

### 1.6 Parties prenantes et appuis externes

Parties prenantes internes :

- équipe produit/tech Ascension,
- encadrement EIP,
- mentor.

Parties prenantes externes :

- utilisateurs testeurs (grimpeurs),
- experts techniques externes (architecture, IA, performance, sécurité),
- partenaires potentiels (salles d’escalade, réseau professionnel).

---

## 2. Technical Specifications

### 2.1 Stack visée

| Couche          | Technologie                                         | Rôle principal                                     |
|:----------------|:----------------------------------------------------|:---------------------------------------------------|
| Mobile          | Flutter / Dart                                      | Expérience utilisateur, rendu 3D, parcours complet |
| API             | Rust (migration planifiée vers Go)                  | Orchestration, sécurité, contrats API              |
| IA              | Python (MediaPipe, OpenCV, PyTorch, pipeline SAM3D) | Analyse biomécanique, détection prises, conseils   |
| Broker          | RabbitMQ                                            | Traitement asynchrone fiable                       |
| Base de données | PostgreSQL                                          | Stockage métier et résultats                       |
| Stockage objet  | MinIO (S3 compatible)                               | Upload vidéo et artefacts                          |
| CI/CD           | Moonrepo + pipelines CI                             | Qualité, tests, build, release                     |

### 2.2 Méthode de travail technique

Méthode choisie : cycles courts, mesurables, et orientés preuves.

Règles de pilotage :

- backlog unique et priorisé,
- sprint et suivi réguliers,
- revue risques + revue qualité à chaque cycle,
- décisions techniques toujours documentées,
- boucle continue : mesurer -> tester -> optimiser -> re-mesurer.

### 2.3 Périmètre fonctionnel suivi dans ce plan

Ce plan couvre le pilotage des blocs suivants :

- authentification et gestion du profil,
- upload et analyse IA asynchrone,
- restitution biomécanique et score,
- expérience 3D,
- mode fantôme (MVP puis enrichi),
- accessibilité mobile,
- robustesse backend, CI/CD et observabilité.

### 2.4 User stories de référence

|  ID   | User story                                                                | Critère d’acceptation                                           |
|:-----:|:--------------------------------------------------------------------------|:----------------------------------------------------------------|
| US-01 | En tant que grimpeur, je crée un compte et me connecte.                   | Je peux accéder à l’application sans blocage.                   |
| US-02 | En tant que grimpeur, je configure mon profil morphologique.              | Mes données sont sauvegardées et réutilisées dans les analyses. |
| US-03 | En tant que grimpeur, j’envoie une vidéo et je lance une analyse.         | Une analyse est créée avec statut visible.                      |
| US-04 | En tant que grimpeur, je consulte un résultat clair.                      | Je reçois des indicateurs et conseils compréhensibles.          |
| US-05 | En tant que grimpeur, je visualise ma montée en 3D.                       | Le rendu est stable et manipulable.                             |
| US-06 | En tant que grimpeur, j’utilise le mode fantôme pour comparer ma montée.  | Les écarts de trajectoire sont lisibles et exploitables.        |
| US-07 | En tant qu’équipe technique, je mesure la performance des flux critiques. | Les KPI sont enregistrés, comparés et améliorés.                |

### 2.5 Milestones planifiés

Le plan contient 5 milestones, comme recommandé dans les consignes G-EIP-600.

| Milestone                     | Période cible                  | Objectifs                                                                                                   |
|:------------------------------|:-------------------------------|:------------------------------------------------------------------------------------------------------------|
| M1 - Cadrage opérationnel     | Avril -> Juin 2026             | Finaliser gouvernance, backlog, risques, CI/CD de base, architecture de référence.                          |
| M2 - Stabilisation fondations | Juillet -> Septembre 2026      | Finaliser livrables administratifs, sécuriser migration backend, fiabiliser pipeline d’analyse.             |
| M3 - BTP core features        | Septembre 2026 -> Janvier 2027 | Parcours utilisateur complet, analyse stable, résultats exploitables, onboarding et accessibilité critique. |
| M4 - GreenLight readiness     | Février -> Juillet 2027        | Mode fantôme MVP, expérience 3D stable, preuves performance, revues experts, dossier GreenLight complet.    |
| M5 - ATP launch readiness     | Juillet -> Août 2027           | Passage GreenLight, livraison ATP, plan détaillé phase alpha prêt à exécuter.                               |

### 2.6 Definition of Done transversale

Une fonctionnalité est considérée "done" quand :

- elle fonctionne sur le parcours réel utilisateur,
- ses cas d’échec principaux sont gérés,
- ses critères de succès sont mesurés,
- sa documentation est à jour,
- son impact accessibilité est vérifié,
- elle est intégrée sans régression majeure.

---

## 3. Non-Technical Specifications

### 3.1 Mentorat et gouvernance

Le mentorat est intégré dans le fonctionnement courant :

- point mentor planifié à fréquence régulière,
- compte-rendu après chaque échange,
- décisions traduites en actions concrètes dans le backlog.

Le mentor sert de support stratégique, de garde-fou méthodologique, et de relais d’expérience.

### 3.2 Topic mandatory - Evaluate and integrate new technologies

**Intention**

Évaluer les technologies de manière pragmatique, avec des preuves comparables, sans suivre les tendances sans justification.

**Plan d’action**

- veille technique mensuelle,
- benchmark comparatif par chantier majeur,
- POC ciblés pour valider ou invalider une option,
- décision formalisée après mesure.

**Objectif mesurable**

- au moins 1 benchmark structuré par grand chantier (IA, backend, mobile),
- au moins 1 POC à impact décisionnel documenté.

### 3.3 Topic optional - Collaborate with technical experts

**Intention**

Améliorer la qualité des choix techniques en sollicitant des retours externes qualifiés.

**Plan d’action**

- échanger avec Quentin BRIAND notre mentor expert en IA,
- identifier les sujets nécessitant une revue experte,
- organiser des sessions de feedback ciblées,
- intégrer les retours dans les décisions d’architecture.

**Objectif mesurable**

- au moins 2 revues externes significatives,
- traçabilité des actions issues des retours.

### 3.4 Topic optional - Protect and enhance your technology

**Intention**

Sécuriser la valeur du projet sur le plan technique, juridique et opérationnel.

**Plan d’action**

- clarifier stratégie licence et conformité dépendances,
- structurer la documentation d’architecture et de sécurité,
- cadrer la protection des actifs techniques clés.

**Objectif mesurable**

- audit licences validé,
- checklist sécurité/conformité utilisée en revue,
- documentation des composants stratégiques finalisée.

### 3.5 Topic optional - Develop community contributions

**Intention**

Créer un cadre qui facilite les contributions techniques externes à terme.

**Plan d’action**

- améliorer guides de contribution,
- normaliser templates d’issues et de PR,
- publier des sujets de contribution accessibles.

**Objectif mesurable**

- guide de contribution complet,
- workflow PR standardisé,
- premier lot de tickets "good first issue" publié.
