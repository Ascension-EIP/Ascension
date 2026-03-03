> **Last updated:** 23rd February 2026  
> **Version:** 1.0  
> **Authors:** Olivier POUECH and Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# Costing & Technical Sizing - Workshop Deliverable

---

## Table of Contents

- [Executive Summary (Résumé financier)](#executive-summary-résumé-financier)
- [1. Identification des Ressources](#1-identification-des-ressources)
  - [1.1 Infrastructure & Cloud (Hetzner)](#11-infrastructure-cloud-hetzner)
  - [1.2 Coûts de Publication & Branding (CAPEX)](#12-coûts-de-publication-branding-capex)
- [2. Benchmarks & Choix Stratégiques](#2-benchmarks-choix-stratégiques)
  - [2.1 Pourquoi Hetzner plutôt qu'AWS ?](#21-pourquoi-hetzner-plutôt-quaws)
  - [2.2 Stack Technique : L'optimisation au service du budget](#22-stack-technique-loptimisation-au-service-du-budget)
- [3. Architecture & Sizing (MVP)](#3-architecture-sizing-mvp)
- [4. Stratégie de Scaling](#4-stratégie-de-scaling)


---

## Executive Summary (Résumé financier)

L'objectif de cette étude est d'estimer les ressources nécessaires au lancement du MVP (100 utilisateurs) et d'anticiper les coûts de passage à l'échelle (10 000 utilisateurs).

|       **Phase**        | **CAPEX (Coûts uniques)** | **OPEX (Mensuel)** | **Coût / Utilisateur** |
| :--------------------: | :-----------------------: | :----------------: | :--------------------: |
|  **MVP (100 users)**   |           133 €           |        96 €        |         0.96 €         |
|  **Scale (1k users)**  |            0 €            |       231 €        |         0.23 €         |
| **Scale+ (10k users)** |            0 €            |       655 €        |         0.06 €         |

_Note : La rentabilité est atteinte dès la phase "Scale" avec un modèle Freemium / Premium (20€) / Infinity (30€) et un taux de conversion de 10%._

---

## 1. Identification des Ressources

### 1.1 Infrastructure & Cloud (Hetzner)

Nous avons privilégié **Hetzner (Allemagne)** pour son excellent rapport performance/prix et sa conformité stricte au RGPD (données biométriques stockées en UE).

- **API Backend (Rust Axum) :** Instance CX31 (4 vCPU, 8 GB RAM) – Gestion du flux et de la logique métier.
- **Database (PostgreSQL) :** Instance CX41 (4 vCPU, 16 GB RAM) – Haute performance pour les jointures complexes et le JSONB.
- **ML Workers (Python / pika + MediaPipe) :** Instance CX51 (8 vCPU, 16 GB RAM) – Analyse d'images intensive (MediaPipe/OpenCV).
- **Storage (S3-compatible) :** Hetzner Storage Box (1 TB) – Stockage des vidéos brutes et des analyses.

### 1.2 Coûts de Publication & Branding (CAPEX)

- **Apple Developer Program :** 99 € / an (Obligatoire pour iOS).
- **Google Play Console :** 22 € (Paiement unique).
- **Nom de domaine :** 12 € / an (https://www.google.com/url?sa=E&source=gmail&q=escalade-app.com).

---

## 2. Benchmarks & Choix Stratégiques

### 2.1 Pourquoi Hetzner plutôt qu'AWS ?

D'après notre benchmark financier (cf. onglet `Part2 - Benchmark`), AWS reviendrait à environ **60€/mois** pour une VM équivalente à la CX31 de Hetzner (**15€/mois**). Pour une équipe étudiante, Hetzner permet de diviser la facture infrastructure par 4 tout en garantissant une latence minimale en Europe.

### 2.2 Stack Technique : L'optimisation au service du budget

- **Rust (Axum) :** Choisi pour sa faible consommation mémoire (idle < 100 MB). Cela nous permet de faire tourner l’API et Nginx sur la même machine au début.
- **PostgreSQL :** Préféré à MongoDB pour la gestion rigoureuse des relations (analyses/utilisateurs) et son support natif du format JSONB pour stocker les squelettes 3D de MediaPipe

---

## 3. Architecture & Sizing (MVP)

Le déploiement initial repose sur une architecture conteneurisée (Docker) répartie sur 3 machines physiques virtuelles pour isoler les charges de travail critiques.

| **Machine** |         **Rôle**         | **CPU / RAM**  | **Stockage** |
| :---------: | :----------------------: | :------------: | :----------: |
| **Srv-API** | Nginx / API Rust         | 4 vCPU / 8 GB  |  80 GB SSD   |
| **Srv-DB**  |   PostgreSQL / Backup    | 4 vCPU / 16 GB | 500 GB NVMe  |
| **Srv-ML**  | 2 Workers Python (pika)  | 8 vCPU / 16 GB |  100 GB SSD  |

---

## 4. Stratégie de Scaling

Le passage de 100 à 1 000 utilisateurs multipliera le coût OPEX par environ 2.4, alors que le volume de données sera multiplié par 10.

- **Scaling Vertical :** Upgrade de la machine PostgreSQL (CX61) pour absorber les écritures.
- **Scaling Horizontal :** Ajout de nœuds de calcul ML Workers (Machine 4) pour traiter la file d'attente de vidéos sans augmenter la latence

---

_Consultez le fichier **`costs.xlsx`** pour le détail des calculs de TVA, les frais d'egress data et les projections de revenus._
