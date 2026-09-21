---
id: 0069f35f-0ad8-4bf6-8f0b-c3607ff33f1a
---

:::success
**Version:** 1.0\
**Original language:** French
:::

---

# Grille Tarifaire et Offres d'Abonnement Ascension

---

## Table des matières

- [Grille Tarifaire et Offres d'Abonnement Ascension](#grille-tarifaire-et-offres-dabonnement-ascension)
  - [Table des matières](#table-des-mati%C3%A8res)
  - [1\. Vision et modèle économique](#1-vision-et-mod%C3%A8le-%C3%A9conomique)
  - [2\. Grille comparative des offres](#2-grille-comparative-des-offres)
  - [3\. Détail des niveaux d'abonnement](#3-d%C3%A9tail-des-niveaux-dabonnement)
    - [3.1 Freemium (Découverte)](#31-freemium-d%C3%A9couverte)
    - [3.2 Premium (Progression active)](#32-premium-progression-active)
    - [3.3 Infinity (Haute performance & Intensif)](#33-infinity-haute-performance--intensif)
  - [4\. Justification technique et dimensionnement](#4-justification-technique-et-dimensionnement)
    - [4.1 Coûts de calcul GPU et inférence IA](#41-co%C3%BBts-de-calcul-gpu-et-inf%C3%A9rence-ia)
    - [4.2 Gestion de la priorité serveur via RabbitMQ](#42-gestion-de-la-priorit%C3%A9-serveur-via-rabbitmq)
    - [4.3 Stockage objet et bande passante](#43-stockage-objet-et-bande-passante)
  - [5\. Cycle de vie et gestion des quotas](#5-cycle-de-vie-et-gestion-des-quotas)

---

## 1\. Vision et modèle économique

Le modèle économique d'Ascension repose sur un système d'abonnement SaaS B2C freemium à paliers clairs, conçu pour :

1. **Garantir l'accessibilité :** Permettre à tout grimpeur de tester et d'utiliser l'analyse biomécanique gratuitement sans barrière à l'entrée.
2. **Couvrir les coûts d'infrastructure :** Répercuter fidèlement les coûts d'inférence GPU, de stockage vidéo S3 (MinIO) et de bande passante réseau à mesure que la fréquence d'utilisation augmente.
3. **Valoriser les fonctionnalités à fort impact :** Réserver le Mode Fantôme (calcul de trajectoire optimale par cinématique inverse) et la priorité de traitement sur les workers IA aux utilisateurs investis dans leur progression.

---

## 2\. Grille comparative des offres

| Caractéristique | Freemium | Premium | Infinity |
| --- | --- | --- | --- |
| **Tarif mensuel** | **Gratuit (0 €)** | **20 € / mois** | **30 € / mois** |
| **Analyses vidéo / mois** | **10** | **30** | **100** |
| **Mode Fantôme (utilisations / mois)** | ❌ *(0)* | **30** | **100** |
| **Routines d'entraînement personnalisées** | **5 max** | **Illimitées** | **Illimitées** |
| **Priorité serveur (file d'attente IA)** | ❌ *(Standard)* | ❌ *(Standard)* | ✅ *(Prioritaire)* |
| **Publicités intégrées** | ✅ *(Oui)* | ❌ *(Non)* | ❌ *(Non)* |

---

## 3\. Détail des niveaux d'abonnement

### 3.1 Freemium (Découverte)

L'offre Freemium s'adresse aux grimpeurs occasionnels découvrant l'analyse vidéo ou souhaitant un suivi ponctuel de leurs ascensions.

- **Analyses vidéo :** 10 vidéos analysées par mois calendaire (extraction squelettique 2D, détection des prises et conseils techniques de base).
- **Mode Fantôme :** Non accessible.
- **Routines d'entraînement :** Possibilité de créer et suivre jusqu'à 5 routines d'entraînement personnalisées.
- **Expérience utilisateur :** Présence d'encarts promotionnels et publicitaires discrets.
- **File de traitement :** Traitement sur la file standard asynchrone des workers IA.

### 3.2 Premium (Progression active)

L'offre Premium à **20 € / mois** est pensée pour les grimpeurs réguliers (1 à 2 séances par semaine) qui souhaitent accélérer leur apprentissage grâce au retour visuel direct.

- **Analyses vidéo :** 30 vidéos analysées par mois (soit environ 7 à 8 blocs ou voies analysés chaque semaine).
- **Mode Fantôme :** 30 générations de parcours fantôme par mois, permettant de superposer la trajectoire optimale calculée par cinématique inverse sur la vidéo du grimpeur.
- **Routines d'entraînement :** Création et gestion illimitées de routines et programmes d'entraînement.
- **Expérience utilisateur :** Aucune publicité, interface épurée dédiée à la pratique.
- **File de traitement :** Traitement standard fiable.

### 3.3 Infinity (Haute performance & Intensif)

L'offre Infinity à **30 € / mois** cible les compétiteurs, grimpeurs quotidiens, entraîneurs et passionnés exigeants ayant un volume d'ascensions élevé.

- **Analyses vidéo :** 100 vidéos analysées par mois (large marge couvrant les séances quotidiennes et les essais multiples).
- **Mode Fantôme :** 100 générations de trajectoires fantômes par mois.
- **Routines d'entraînement :** Création et gestion illimitées de routines.
- **Priorité serveur :** Les requêtes d'analyse sont envoyées sur une file RabbitMQ haute priorité (`x-max-priority`), garantissant un traitement en tête de file par les workers GPU même en période de forte affluence.
- **Expérience utilisateur :** Sans publicité.

---

## 4\. Justification technique et dimensionnement

### 4.1 Coûts de calcul GPU et inférence IA

Chaque analyse vidéo mobilise un pipeline lourd composé de :

1. Détection de pose et squelettisation 2D (MediaPipe Pose, 33 points-clés par frame).
2. Reconstruction et correction biomécanique 3D.
3. Analyse des prises de la voie (OpenCV + PyTorch).
4. Pour le Mode Fantôme : résolution cinématique inverse et recherche de chemin optimal.

Plafonner les quotas à **10 (Freemium)**, **30 (Premium)** et **100 (Infinity)** protège l'infrastructure contre les abus tout en garantissant des coûts d'inférence prévisibles et maîtrisés.

### 4.2 Gestion de la priorité serveur via RabbitMQ

Le backend Go publie les messages de tâches d'analyse dans RabbitMQ :

- Les utilisateurs **Infinity** bénéficient d'un champ de priorité élevée (`Priority: 10`) sur le message AMQP.
- Les utilisateurs **Freemium** et **Premium** sont traités avec la priorité standard (`Priority: 1`).
- Cela garantit aux utilisateurs Infinity un temps de retour minimal lors des sessions en direct à la salle d'escalade.

### 4.3 Stockage objet et bande passante

Les vidéos d'escalade brutes sont directement transférées depuis le smartphone vers MinIO via des URL pré-signées S3. Les quotas d'analyse évitent l'accumulation incontrôlée de volumétries vidéo non monétisées.

---

## 5\. Cycle de vie et gestion des quotas

1. **Compteurs mensuels :** La table `quota_usages` enregistre la consommation réelle (`analyses_count`, `ghosts_count`) sur la période en cours.
2. **Plafonds stricts :** Le middleware de contrôle (`Quota Middleware`) vérifie avant chaque upload vidéo ou demande de Mode Fantôme que le quota du forfait (`monthly_analysis_quota`, `monthly_ghost_quota`) n'est pas dépassé.
3. **Gestion des abonnements :** La transition entre offres (souscription, mise à niveau, rétrogradation, résiliation) est synchronisée via les webhooks Stripe et tracée dans `subscription_events`.
