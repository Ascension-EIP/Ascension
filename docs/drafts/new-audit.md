> **Last updated:** 10th February 2026  
> **Version:** 1.0  
> **Authors:** Lou PELLEGRINO  
> **Status:** In Progress (to finish and translate)  
> {.is-warning}

---

# Compte-rendu d'audit technique, fonctionnel et de sécurité

---

## Table of Contents

- [Environnement d'exécution du projet](#environnement-dexécution-du-projet)
- [3. Audit technique](#3-audit-technique)
  - [3.1 Environnement d’exécution](#31-environnement-dexécution)
  - [3.2 Stack technique](#32-stack-technique)
  - [3.3 Architecture](#33-architecture)
  - [3.4 Exploitabilité](#34-exploitabilité)
- [4. Audit fonctionnel](#4-audit-fonctionnel)
  - [4.1 Compréhension du besoin](#41-compréhension-du-besoin)
  - [4.2 Adéquation solution / besoin](#42-adéquation-solution-besoin)
  - [4.3 Parcours utilisateurs](#43-parcours-utilisateurs)
- [5. Audit sécurité](#5-audit-sécurité)
  - [5.1 Sécurité de l’infrastructure](#51-sécurité-de-linfrastructure)
  - [5.2 Gestion des accès](#52-gestion-des-accès)
  - [5.3 Sécurité applicative (niveau projet)](#53-sécurité-applicative-niveau-projet)
  - [5.4 Conformité](#54-conformité)


---

## Environnement d'exécution du projet

Le dossier du candidat contient un **compte-rendu d'audit technique, fonctionnel et de sécurité** de l'environnement d'exécution du projet, mettant en lumière les **contraintes et opportunités du contexte opérationnel**. [C2]

Le candidat est en mesure d'expliquer **l'approche méthodologique** mise en œuvre pour réaliser l'audit :

- moyens d'investigation
- collecte de retours utilisateurs
- analyse documentaire
  […] [C2]

---

## 3. Audit technique

### 3.1 Environnement d’exécution

- **Hébergement** : Self-hosted VPS au début du projet puis server donnée par epitech
- **VM / Containers** : Docker et Kubernetes
- **Environnements** : main (qui fait office de prod) et dev (pour les tests et le developpement) -> sachant qu'on travaille sur des sous branch de dev
- **Scalabilité prévue** : rien de prévu pour le moment, on verra à l’usage

---

### 3.2 Stack technique

- **Backend** : Rust
- **Frontend** : Mobile Android / iOS (Flutter)
- **IA** : Python
- **Base de données** : PostgreSQL
- **API backend** : REST
- **Middleware** :
  - API Gateway
  - Broker : RabbitMQ
  - Reverse proxy : Nginx
  - Object Storage : MinIO (self-hosted)

- **Dépendances critiques** : ??

---

### 3.3 Architecture

- **Type** : Microservices
- **Schéma d’architecture (logique et physique)** : ??
- **Flux entre composants** : ??
- **Points de défaillance uniques (SPOF)** : ??

---

### 3.4 Exploitabilité

- **Déploiement (CI/CD)** : ??
- **Monitoring (logs, métriques, alertes)** : Prometheus (métriques) + Grafana (dashboards & alertes) + Loki (logs centralisés)

- **Sauvegardes et restauration** : ??
- **Stratégie de montée de version** : ??

---

## 4. Audit fonctionnel

### 4.1 Compréhension du besoin

- **Objectifs métiers** : ??
- **Cas d’usage principaux** :
  - Analyse du mouvement et des erreurs de l’utilisateur
  - Mode Fantôme basé sur la morphologie de l’utilisateur
  - Génération de routines basée sur la data

- **Contraintes réglementaires ou métier** : ??

---

### 4.2 Adéquation solution / besoin

- Les fonctionnalités prévues couvrent-elles les besoins ?
- **Dépendances critiques externes** :
  - Librairies Python pour le scan vidéo

- **Performances attendues** :
  - Reconnaissance des prises (le plus jouable)
  - Mode Fantôme (mise en situation de notre IA personnelle)
  - Mode analyse (application sur la vidéo des erreurs et forces)
  - Génération de routines (le plus galère)

---

### 4.3 Parcours utilisateurs

- **Typologie des utilisateurs** : user, admin
- **Droits et rôles** : user, admin

**Scénarios clés** :

- **Nominal** : ?? (pipeline si tout fonctionne)
- **Dégradé** : ?? (pipeline si un composant n’est plus accessible)

---

## 5. Audit sécurité

### 5.1 Sécurité de l’infrastructure

- **Segmentation réseau** : ??
- **Pare-feu / security groups** :
  - iptables (SSH, HTTPS uniquement)

- **Exposition Internet** :
  - Cloudflared tunnel

- **Chiffrement des données** :
  - TLS (repos / transit)
  - Chiffrement inter-microservices ?? (paraît inutile)

---

### 5.2 Gestion des accès

- **Authentification (SSO, MFA)** : ??
- **Gestion des rôles** : admin, user
- **Principe du moindre privilège** : admin, user
- **Comptes techniques** : admin ??

---

### 5.3 Sécurité applicative (niveau projet)

- **Gestion des secrets** :
  - ?? (service dédié ? Signal ?)

- **Protection API** :
  - Middleware avec authentification

- **Journalisation des actions sensibles** :
  - Logs

- **Prévention OWASP Top 10** :
  - Au moins au niveau design ??

---

### 5.4 Conformité

- **RGPD (si données personnelles)** : blk on est pas des fdp
- **Traçabilité** : blk on est pas des fdp
- **Conservation des logs** : ??
