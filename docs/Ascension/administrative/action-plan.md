---
id: 6dbad1cf-7a8f-43f8-a5a4-111052513263
---

:::success
**Version:** 1.1
:::

---

# Ascension Action Plan

---

## 1\. Contexte

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

## 2\. Spécifications techniques

### 2.1 Stack visée

| Couche          | Technologie                                                     | Rôle principal                                                                     |
| --------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Mobile          | Flutter / Dart                                                  | Expérience utilisateur, interface fluide, accessibilité, parcours complet          |
| API             | Go (Gin)                                                        | Orchestration, sécurité, contrats API                                              |
| IA              | Python (MediaPipe, OpenCV, PyTorch, modèle 3D en phase avancée) | Analyse biomécanique, détection prises, conseils |
| Broker          | RabbitMQ                                                        | Traitement asynchrone fiable                                                       |
| Base de données | PostgreSQL                                                      | Stockage métier et résultats                                                       |
| Stockage objet  | MinIO (S3 compatible)                                           | Upload vidéo et artefacts                                                          |
| CI/CD           | Moonrepo + pipelines CI                                         | Qualité, tests, build, release                                                     |

### 2.2 Méthode de travail technique

Méthode choisie : cycles courts, mesurables, et orientés preuves.

Règles de pilotage et cadence :

- charge prévue : **2 jours de travail par semaine** (capacité indicative d'environ 90 jours sur la période BTP),
- rythme de pilotage : **1 sprint + 1 suivi environs toutes les 6 semaines**,
- backlog unique et priorisé sur GitHub Project,
- revue risques + revue qualité à chaque cycle,
- décisions techniques toujours documentées (veille, benchmarks, PoC),
- boucle continue : mesurer -> tester -> optimiser -> re-mesurer.

### 2.3 Périmètre fonctionnel suivi dans ce plan

Ce plan couvre le pilotage des blocs ciblés pour le jalon **GreenLight (BTP)** :

- authentification et configuration du profil morphologique (avec possibilité de reprise ultérieure),
- onboarding guidé au premier lancement et tutoriels rejouables depuis les paramètres,
- upload vidéo et analyse IA 2D asynchrone (MediaPipe Pose, format biomécanique standardisé),
- restitution biomécanique, score global et suivi de progression dans le temps,
- conseils techniques personnalisés via modèle externe (type Gemini ou équivalent API),
- mode fantôme MVP (comparaison sur vidéo réelle et génération via photo de voie avec sélection manuelle des prises en mode custom),
- dimension communautaire et partage (partage d'analyses, comparaison de performances entre amis, contrôle fin de la visibilité),
- coach personnel et programmes d'entraînement (objectifs de progression, séances types personnalisées, journalisation des entraînements),
- accessibilité numérique mobile forte (objectifs WCAG 2.2 AA),
- robustesse backend (migration Go finalisée), CI/CD et observabilité.

_(Note : l'extraction de posture via modèle 3D, l'expérience 3D mobile interactive, la détection automatique avancée des prises, la grimpe assistée AR/audio temps réel et le cycle business complet sont planifiés pour l'ATP)._

### 2.4 User stories de référence

| ID    | User story                                                                                                                  | Critère d’acceptation                                                                                    |
| ----- | --------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| US-01 | En tant que grimpeur, je crée un compte et me connecte.                                                                     | Je peux accéder à l’application sans blocage.                                                            |
| US-02 | En tant que grimpeur, je configure mon profil morphologique. | Mes données sont sauvegardées et réutilisées dans les analyses. |
| US-03 | En tant que nouvel utilisateur, je découvre l'app via un onboarding guidé et peux rejouer les tutoriels.                    | L'onboarding s'affiche au premier lancement et les tutoriels sont accessibles depuis les paramètres.     |
| US-04 | En tant que grimpeur, j’envoie une vidéo de grimpe et je lance une analyse.                                   | Une analyse est créée avec statut et progression visibles jusqu'au résultat final.                       |
| US-05 | En tant que grimpeur, je consulte un résultat biomécanique clair, mon score global et mes conseils.                         | Je reçois des indicateurs, un score de séance et des recommandations personnalisées compréhensibles.     |
| US-06 | En tant que grimpeur, je sélectionne les prises de ma voie en mode custom sur photo pour générer le fantôme MVP. | Les prises sélectionnées manuellement sont prises en compte pour calculer la trajectoire optimale.       |
| US-07 | En tant que grimpeur, je visualise la bêta calculée sur photo.                      | La bêta est affichée clairement et progressivement sur la photo.                                                      |
| US-08 | En tant que grimpeur, je définis mes objectifs et génère des routines d'entraînement personnalisées.                        | Des séances types adaptées à mon profil sont proposées et je peux consigner mes entraînements.           |
| US-09 | En tant que grimpeur, je partage mes analyses et compare mes performances avec mes amis selon mes choix de confidentialité. | Le partage respecte les droits choisis (privé, amis, public) et l'accès ami est instantané.              |
| US-10 | En tant qu'utilisateur ayant des besoins d'accessibilité, je navigue confortablement dans l'application.                    | L'application respecte les contrastes, la mise à l'échelle des textes et le guidage par lecteur d'écran. |
| US-11 | En tant qu’équipe technique, je mesure la performance des flux critiques et la fiabilité système.                           | Les KPI (temps d'analyse, latence API, stabilité, score accessibilité) sont suivis et optimisés.         |

### 2.5 Milestones planifiés

Le plan contient 5 milestones, comme recommandé dans les consignes G-EIP-600.

| Milestone                          | Période cible                        | Objectifs                                                                                                                                                           |
| ---------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| M1 - Lancement opérationnel        | Septembre 2026 -> Mi-octobre 2026    | Lancer l’exécution : backlog final, registre des risques actif, CI/CD stabilisé, suivi d'équipe opérationnel et amorce de la finalisation Rust → Go.                |
| M2 - Stabilisation technique       | Mi-octobre 2026 -> Fin novembre 2026 | Sécuriser le socle API Go et l'IA 2D (MediaPipe), fiabiliser upload S3 et broker RabbitMQ.                                     |
| M3 - Parcours produit complet v1   | Décembre 2026 -> Mi-janvier 2027     | Valider le parcours principal de bout en bout (compte, profil morpho avec reprise, onboarding, tutoriels, upload, analyse 2D, restitution biomécanique et score).   |
| M4 - Valeur démontrable GreenLight | Mi-janvier 2027 -> Fin mars 2027     | Livrer le mode fantôme MVP (génération photo avec prises custom), les routines de base, le partage/communauté, la comparaison entre utilisateurs et l'accessibilité mobile forte. |
| M5 - Finalisation GreenLight       | Avril 2027 -> Juillet 2027           | Campagne de tests beta BTP, optimisation performance et accessibilité, consolidation des preuves techniques (benchmarks, revues experts), dossier GreenLight prêt.  |

### 2.6 Definition of Done transversale

Une fonctionnalité est considérée "done" quand :

- elle fonctionne sur le parcours réel utilisateur,
- ses cas d’échec principaux sont gérés,
- ses critères de succès sont mesurés,
- sa documentation est à jour,
- son impact accessibilité est vérifié,
- elle est intégrée sans régression majeure.

---

## 3\. Spécifications non techniques

### 3.1 Mentorat et gouvernance

Le mentorat est intégré dans le fonctionnement courant :

- point mentor planifié à fréquence régulière,
- compte-rendu après chaque échange,
- décisions traduites en actions concrètes dans le backlog.

Le mentor sert de support stratégique, de garde-fou méthodologique, et de relais d’expérience.

### 3.2 Objectif obligatoire - Evaluate and integrate new technologies

**Intention**

Évaluer les technologies de manière pragmatique, avec des preuves comparables, sans suivre les tendances sans justification.

**Plan d’action**

- veille technique mensuelle,
- benchmark comparatif par chantier majeur,
- POC ciblés pour valider ou invalider une option,
- décision formalisée après mesure.

**Mesurable**

- au moins 1 benchmark structuré par grand chantier (IA, backend, mobile),
- au moins 1 POC à impact décisionnel documenté.

### 3.3 Objectif obligatoire - Structure, document, and harden the project's technical architecture

**Intention**

Bâtir une architecture logicielle robuste, modulaire, sécurisée et entièrement documentée pour garantir l’évolutivité, la maintenabilité et la résilience du système.

**Plan d’action**

- maintenir une documentation technique exhaustive et à jour (README par composant, schémas d’architecture, guides de déploiement),
- appliquer des standards de qualité de code stricts (linters automatisés, conventions de nommage, CI sur chaque pull request),
- durcir la sécurité applicative (authentification JWT, validation des entrées, gestion sécurisée des secrets d'environnement) et fiabiliser la gestion d'erreurs,
- couvrir l’ensemble des modules critiques (API, algorithmes IA, services réseau mobile) par des tests unitaires et d’intégration.

**Mesurable**

- 100 % des composants disposent d’un README structuré et de pipelines de tests CI au vert,
- couverture de tests et conformité aux standards validées avant chaque livraison de jalon.

### 3.4 Objectif optionnel - Collaborate with technical experts

**Intention**

Améliorer la qualité des choix techniques en sollicitant des retours externes qualifiés.

**Plan d’action**

- échanger avec Quentin BRIAND notre mentor expert en IA,
- identifier les sujets nécessitant une revue experte,
- organiser des sessions de feedback ciblées,
- intégrer les retours dans les décisions d’architecture.

**Mesurable**

- au moins 2 revues externes significatives,
- traçabilité des actions issues des retours.

### 3.5 Objectif optionnel - Measure, test, and optimize technical performance

**Intention**

Piloter les optimisations techniques sur des mesures concrètes et vérifiables.

**Plan d’action**

- définir 2 à 3 KPI techniques clés (latence API, temps d’analyse, stabilité mobile),
- lancer des tests de charge, résilience et comparaison avant/après,
- implémenter des optimisations ciblées,
- mesurer à nouveau et documenter l’impact réel.

**Mesurable**

- chaque campagne d’optimisation doit produire un avant/après chiffré,
- les résultats doivent être visibles dans un tableau de suivi partagé.
