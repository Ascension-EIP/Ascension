---
id: c67906b8-513d-45a3-bf70-99bd604b7f2c
---

# Avancement globale sur le projet

Entre le 9 et le 27 novembre 2026, l'équipe a poursuivi la stratégie validée lors du dernier suivi : construire d'abord une chaîne fonctionnelle de bout en bout avant d'affiner chaque brique.

Les avancées majeures de cette période portent sur :

- **IA & Mode Fantôme :** mise en place complète du pipeline de **détection et segmentation des prises** (YOLO26-seg en ONNX) et d'une **première version fonctionnelle du pipeline de pathfinding** (plan du mur, profondeur métrique, recherche de séquence, reconstruction de posture), tous deux connectés à RabbitMQ et PostgreSQL.
- **Mobile & Analyse de pose :** implémentation partielle de l'**analyse de pose 2D sur mobile** (enregistrement vidéo, lecteur avec superposition du squelette MediaPipe, statistiques, suivi de traitement en temps réel) et ajout de l'authentification biométrique.
- **Backend & Infrastructure :** ajout des routes **sessions d'escalade**, **contraintes corporelles** et **social (amis / fil d'actualité)**, mise en production du stockage objet **S3 (OVHcloud)**, déploiement **Coolify** de l'API et du worker IA avec sauvegardes automatisées, et lancement du workflow de veille **n8n**.
- **Qualité & CI/CD :** forte augmentation de la couverture de tests (Go, Python, Flutter), intégration **SonarQube** et vérifications automatisées sur les issues GitHub.

## 2\. Avancement par objectif EIP

### 2.1 Objectif obligatoire 1 — Veille technologique et résolution du point dur

> *« Track what's out there and use it to crack your project's hard problem »*

Dispositif de veille et journal de recherche

- **Workflow n8n déployé (`feat/n8n-technology-watch`) :** le service n8n est opérationnel sur Coolify avec son workflow de veille automatisé et son guide d'infrastructure dédié. Conformément aux ajustements techniques, Google Scholar a été remplacé par **OpenAlex** dans la documentation du dispositif de veille.
- **Journal de recherche :** la structure et le gabarit normalisé des fiches de veille ont été mis en place dans la documentation (`research-logs/`).
- **Point d'attention :** les fiches individuelles d'analyse d'articles (objectif : au moins 20 fiches réparties d'octobre à mai) restent à alimenter régulièrement par l'équipe.

Détection des prises (`feat/holds`)

- **Modèle & inférence :** intégration d'un modèle **YOLO26-seg** exporté au format **ONNX** (`onnxruntime` sur CPU) permettant de segmenter les prises et les volumes sur une photo de mur, puis d'extraire et nommer la couleur dominante de chaque prise.
- **Intégration backend/worker :** définition des contrats JSON Schema (`hold_detect_request`, `hold_detect_result`), consommation de la file RabbitMQ `holds.detect`, et stockage des prises détectées ainsi que de l'état des jobs dans PostgreSQL (migration dédiée).
- **Outillage & tests :** déplacement du projet d'entraînement sous `apps/ai/training/holds` (fusion de datasets Roboflow, export ONNX), ajout des commandes CLI `holds-detect` et `holds-colors-eval`, et couverture par tests unitaires et fonctionnels.

Pathfinding — Mode Fantôme (`feat/ai-pathfinding`)

- **Pipeline complet v1 :** implémentation de la chaîne `_4_pathfinding` dans le worker Python :
  1. Estimation du plan du mur (`_0_wall.py`).
  2. Estimation de profondeur métrique (`_1_depth.py`, avec script de téléchargement du modèle).
  3. Recherche de séquence / bêta (`_2_beta.py`), bornée par nombre d'états étendus et rendue déterministe pour les tests.
  4. Reconstruction de posture (`_3_pose.py`).
  5. Orchestration complète (`_4_pathfinding.py`) et handler RabbitMQ dédié.
- **Contrats & base de données :** ajout des schémas partagés (`climber_morphology`, `pathfinding_compute_request`, `pathfinding_result`), gestion des marques départ/arrivée et pieds libres, renommage des tables `ghosts` vers `pathfindings` en base de données.
- **Tests & documentation :** ajout de tests unitaires, CLI et end-to-end, ainsi que de la documentation détaillée du pipeline et des modules worker.

---

### 2.2 Objectif obligatoire 2 — Structurer, documenter et fiabiliser l'architecture technique

> *« Structure, document and make your technical architecture reliable »*

Backend Go (`apps/server`)

- **Nouvelles fonctionnalités métier :**
  - CRUD des **sessions d'escalade** (`feat/climbing-sessions-crud`).
  - Gestion des **contraintes corporelles utilisateur** (`feat/user-body-constraints`) pour le profil morphologique.
  - Socle **social / communauté** (`feat/friendships-and-feed`) : gestion des amitiés, recherche d'utilisateurs et fil d'actualité.
- **Fiabilisation des analyses & conseils IA :**
  - Création d'une table dédiée `advices` (`feat/new-table-for-advice`), mise à jour du CRUD analyses et ajout d'un job cron de nettoyage des conseils bloqués/expirés.
  - Alignement du contrat de messages RabbitMQ entre l'API Go et le worker IA (`fix/analysis-worker-contract`).
  - Standardisation des routes API (suppression des trailing slashes) et des variables d'environnement (`storage` / `queue`).

Application Mobile Flutter (`apps/mobile`)

- **Analyse de pose 2D (`feat/mobile-pose-analysis`) :**
  - Écran d'enregistrement vidéo et aperçu avant envoi.
  - Vue de suivi en temps réel des étapes de traitement avec télémétrie.
  - Lecteur vidéo d'analyse intégrant la superposition du squelette MediaPipe, les onglets de statistiques biométriques et les conseils générés par l'IA, ainsi que la gestion des erreurs de lecture.
  - Connexion à l'API distante pour les sessions d'escalade.
- **UI/UX & sécurité (`feat/mobile-interface-improvements`) :**
  - Refonte de l'écran de sélection d'analyse et mise à jour des traductions FR/EN.
  - Ajout de l'**authentification biométrique** (Android et iOS) avec stockage sécurisé des identifiants.
  - Migration de la configuration d'environnement vers `--dart-define-from-file` et ajout d'un profil de lancement production.

Infrastructure, Stockage S3 & CI/CD

- **Stockage objet S3 (`feat/s3-object-storage`) :** intégration complète avec OVHcloud Object Storage en production (RustFS en local), correction des politiques d'accès et des URLs présignées de téléversement/téléchargement.
- **Déploiement & exploitation :** configurations Coolify pour l'API Go et le worker IA, mise en place des sauvegardes automatisées sur le VPS (`feat/vps-backups`), alertes Discord Coolify et rédaction des runbooks de production et de restauration.
- **Qualité & CI :** ajout de tests unitaires et d'intégration (PostgreSQL, RabbitMQ, S3 sur le serveur ; PostgreSQL, holds et pathfinding sur l'IA ; widgets et logique sur le mobile), configuration de la couverture **SonarQube** et ajout de workflows GitHub Actions pour contrôler la *Definition of Done* et les dates des issues fermées.
- **Point d'attention :** le journal des décisions techniques (ADR, avec le passage de Rust à Go en première entrée) reste à formaliser dans la documentation.

---

### 2.3 Objectif complémentaire C — Collaborer avec des experts techniques

> *« Work with technical experts »*

- **Suivi Lionel Reveret (INRIA) :**
  - Mise en relation envoyée par Ilyes le 9 novembre 2026 avec le questionnaire préparatoire en appui.
  - Création d'un **registre centralisé des échanges avec les experts** (`expert-outreach-and-exchanges.md`).
  - Relance intermédiaire à J+3 envoyée par Nicolas à Ilyes le 13 novembre 2026 pour signaler l'absence de réponse.
- **Points restants / blocage :**
  - Aucune réponse reçue de Lionel Reveret à ce jour.
  - Élargissement des prises de contact à d'autres chercheurs/experts issus de la littérature et finalisation de la note des 2 à 3 sujets à challenger avant fin décembre.

---

### 2.4 Objectif complémentaire D — Mesurer, tester et optimiser les performances techniques

> *« Measure, test and optimize technical performance »*

- **Avancement :**
  - Cadrage documenté des livrables et échéances dans `complementary-D/readme.md` (choix de l'axe et des 2 à 3 indicateurs attendus avant fin décembre).
  - Premières instrumentations déjà présentes dans le code : commande `holds-colors-eval` (évaluation de la classification couleur des prises), télémétrie temps réel du traitement d'analyse côté mobile, et recherche bêta bornée par états étendus côté pathfinding.
- **Points restants :**
  - Arrêter formellement par écrit l'axe de mesure principal et les 2 à 3 indicateurs définitifs avec leurs formules, outils de mesure et valeurs cibles (ex. latence de traitement vidéo/pathfinding, mAP / justesse du nombre de prises détectées, tests de charge API).
