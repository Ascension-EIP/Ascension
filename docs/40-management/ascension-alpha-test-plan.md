<!-- markdownlint-disable MD041 -->

> **Last updated:** 6th April 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO    
> **Status:** Done  
> {.is-success}

---

# Ascension Alpha Test Plan (ATP)

---

## Table of Contents

- [Ascension Alpha Test Plan (ATP)](#ascension-alpha-test-plan-atp)
  - [Table of Contents](#table-of-contents)
  - [1. Project context, objectives and workflow](#1-project-context-objectives-and-workflow)
  - [2. User roles](#2-user-roles)
  - [3. Feature table (organized by user flow)](#3-feature-table-organized-by-user-flow)
  - [4. Success criteria table](#4-success-criteria-table)
  - [5. Out of alpha scope](#5-out-of-alpha-scope)

---

## 1. Project context, objectives and workflow

Ce document décrit le périmètre ATP d’Ascension, c’est-à-dire la phase qui suit le GreenLight et qui mène au jury final de mars 2028.

L’objectif de cette phase est de transformer un MVP crédible en version alpha solide, testable à plus grande échelle, avec des fonctionnalités avancées de coaching, de comparaison, de communauté et de monétisation.

Objectifs ATP :

- finaliser les fonctionnalités avancées prévues après le GreenLight,
- vérifier leur maturité sur des scénarios réels,
- présenter au jury ATP une version cohérente, stable et mesurable.

Flux utilisateur de référence dans l’alpha :

1. Préparer la voie (prises auto + correction).
2. Générer et comparer la bêta complète.
3. Recevoir des conseils enrichis.
4. Travailler avec des routines personnalisées.
5. Utiliser les fonctions sociales et de confidentialité.
6. Utiliser le mode de grimpe assistée.
7. Utiliser le cycle complet d’abonnement.

---

## 2. User roles

| Role name | Description |
| :-- | :-- |
| Grimpeur alpha | Utilisateur principal avec accès au parcours avancé (analyse, fantôme complet, coaching). |
| Ami / membre communauté | Utilisateur qui interagit via comparaison, partage et feedback social. |
| Admin produit & technique | Suit la qualité, la sécurité, la performance, et valide l’état de préparation jury ATP. |

---

## 3. Feature table (organized by user flow)

Toutes les fonctionnalités listées ci-dessous font partie du scope ATP à démontrer.

| Feature ID | User role | Feature name | Short description |
| :-- | :-- | :-- | :-- |
| ATP-F01 | Grimpeur alpha | Se connecter | Accéder au compte et aux données avancées du profil. |
| ATP-F02 | Grimpeur alpha | Détecter automatiquement les prises | Identifier les prises sur photo de voie avec pré-annotation. |
| ATP-F03 | Grimpeur alpha | Corriger manuellement les prises | Ajuster les prises non détectées ou mal classées. |
| ATP-F04 | Grimpeur alpha | Choisir un mode de sélection des prises | Basculer entre mode custom et mode couleur détectée. |
| ATP-F05 | Grimpeur alpha | Générer une bêta sans grimpe | Produire une trajectoire optimale à partir de la voie et du profil utilisateur. |
| ATP-F06 | Grimpeur alpha | Comparer sa montée au fantôme complet | Visualiser écarts clés, moments critiques, recommandations associées. |
| ATP-F07 | Grimpeur alpha | Recevoir des conseils enrichis | Obtenir un feedback technique contextualisé et priorisé. |
| ATP-F08 | Grimpeur alpha | Définir des objectifs de progression | Configurer niveau actuel, niveau cible et contraintes personnelles. |
| ATP-F09 | Grimpeur alpha | Générer des séances personnalisées | Recevoir des routines adaptées à l’historique et aux objectifs. |
| ATP-F10 | Grimpeur alpha | Enregistrer une séance d’entraînement | Logger les séances réalisées pour suivi longitudinal. |
| ATP-F11 | Grimpeur alpha + Ami / membre communauté | Partager une analyse | Publier une montée avec contrôle de visibilité. |
| ATP-F12 | Grimpeur alpha + Ami / membre communauté | Comparer les performances entre amis | Afficher des indicateurs de progression sociale. |
| ATP-F13 | Grimpeur alpha | Régler la confidentialité des contenus | Choisir privé, amis ou public par type de contenu. |
| ATP-F14 | Grimpeur alpha | Lancer le mode de grimpe assistée | Activer l’assistance en temps réel avec conseils vocaux. |
| ATP-F15 | Grimpeur alpha | Gérer l’abonnement de bout en bout | Souscrire, renouveler, changer d’offre, annuler et gérer un échec de paiement. |
| ATP-F16 | Admin produit & technique | Mesurer les KPI produit et business | Suivre activation, rétention, conversion premium, churn et qualité technique. |

---

## 4. Success criteria table

Période de validation ATP : août 2027 -> mars 2028.

| Feature ID | Key success criteria | Indicator/metric | Result achieved |
| :-- | :-- | :-- | :-- |
| ATP-F01 | La connexion donne accès au parcours alpha sans rupture. | 40 essais, 0 blocage critique. | Achieved (40/40). |
| ATP-F02 | La détection automatique propose une base exploitable. | 30 photos, précision macro >= 80%. | Partially achieved (82% global, variabilité forte selon éclairage). |
| ATP-F03 | La correction manuelle permet de finaliser la voie rapidement. | 30 corrections, temps médian <= 90 s. | Achieved (temps médian 74 s). |
| ATP-F04 | Le choix de mode (custom/couleur) est clair et fiable. | 30 bascules, 0 perte de sélection. | Achieved (30/30). |
| ATP-F05 | La bêta sans grimpe se génère et reste lisible. | 25 générations, p95 < 12 s. | Achieved (p95 10.9 s). |
| ATP-F06 | La comparaison fantôme complète produit des écarts actionnables. | 25 comparaisons, 22 jugées utiles par testeurs. | Partially achieved (22/25). |
| ATP-F07 | Les conseils enrichis sont cohérents avec le contexte de voie. | 25 analyses, 23 retours validés par revue interne. | Partially achieved (23/25). |
| ATP-F08 | L’utilisateur peut définir et modifier ses objectifs sans confusion. | 30 parcours, 29 complétés sans aide externe. | Achieved (29/30). |
| ATP-F09 | Les routines générées sont exploitables et adaptées au profil. | 25 générations, 21 validées comme pertinentes. | Partially achieved (21/25). |
| ATP-F10 | Les séances loguées alimentent correctement le suivi. | 50 logs, 50 visibles dans l’historique. | Achieved (50/50). |
| ATP-F11 | Le partage respecte le format et les droits choisis. | 30 partages, 29 conformes au paramétrage. | Partially achieved (29/30). |
| ATP-F12 | La comparaison entre amis est lisible et à jour. | 20 comparaisons, actualisation < 5 s. | Achieved (latence moyenne 2.8 s). |
| ATP-F13 | Les réglages de confidentialité sont respectés sans fuite. | 40 changements, 0 fuite de contenu détectée. | Achieved (40/40). |
| ATP-F14 | Le mode assisté reste utile et sûr pendant l’effort. | 20 sessions, latence vocale p95 < 1.5 s, 2 pertes de tracking gérées. | Partially achieved. |
| ATP-F15 | Le cycle abonnement complet fonctionne sur les cas principaux. | 30 parcours (souscription/changement/annulation), 27 réussis sans intervention manuelle. | Partially achieved (27/30). |
| ATP-F16 | Les KPI business et qualité sont instrumentés et suivis. | 100% des événements clés tracés, dashboard hebdo mis à jour. | Achieved. |

---

## 5. Out of alpha scope

Pour garder un ATP réaliste, les points ci-dessous restent hors scope du jury final :

- expansion multi-pays avec adaptation réglementaire complète,
- catalogue partenaires salles à grande échelle,
- fonctionnalités hardware externes (lunettes AR, capteurs tiers dédiés),
- optimisation extrême de coût pour très forte volumétrie (> phase beta+).

Ces sujets relèvent de la phase post-EIP et de la stratégie de lancement long terme.
