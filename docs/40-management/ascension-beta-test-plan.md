<!-- markdownlint-disable MD041 -->

> **Last updated:** 6th April 2026  
> **Version:** 1.1  
> **Authors:** Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# Ascension Beta Test Plan (BTP)

---

## Table of Contents

- [Ascension Beta Test Plan (BTP)](#ascension-beta-test-plan-btp)
  - [Table of Contents](#table-of-contents)
  - [1. Project context, objectives and workflow](#1-project-context-objectives-and-workflow)
  - [2. User roles](#2-user-roles)
  - [3. Feature table (organized by user flow)](#3-feature-table-organized-by-user-flow)
  - [4. Success criteria table](#4-success-criteria-table)
  - [5. Out of beta scope](#5-out-of-beta-scope)

---

## 1. Project context, objectives and workflow

Ascension est une application mobile qui aide les grimpeurs à progresser grâce à une analyse biomécanique assistée par IA.

Ce BTP définit le périmètre exact de la beta présentée au GreenLight. Le scope est volontairement limité aux fonctionnalités qui peuvent être montrées de bout en bout, de manière stable et compréhensible.

Objectifs de cette beta :

- démontrer un parcours utilisateur complet,
- démontrer la valeur du produit sur un cas réel,
- mesurer la maturité technique avec des critères simples et vérifiables.

Flux utilisateur de référence dans la beta :

1. Se connecter et préparer le profil.
2. Envoyer une vidéo.
3. Lancer l’analyse IA.
4. Suivre la progression.
5. Lire les résultats.
6. Explorer la reconstruction 3D.
7. Utiliser le mode fantôme MVP.
8. Générer un mode fantôme via photo de voie.

---

## 2. User roles

| Role name                 | Description                                                                                   |
|:--------------------------|:----------------------------------------------------------------------------------------------|
| Grimpeur beta             | Utilisateur principal mobile. Il suit le parcours complet d’analyse et de restitution.        |
| Admin technique Ascension | Suit la stabilité de la campagne beta, surveille KPI et incidents, valide la qualité globale. |
| Reviewer GreenLight       | Vérifie la cohérence entre scope promis, démonstration réelle et résultats observés.          |

---

## 3. Feature table (organized by user flow)

Toutes les fonctionnalités listées ci-dessous sont démontrées pendant la soutenance GreenLight.

| Feature ID | User role                 | Feature name                            | Short description                                                                |
|:-----------|:--------------------------|:----------------------------------------|:---------------------------------------------------------------------------------|
| BTP-F01    | Grimpeur beta             | Se connecter                            | Ouvrir une session utilisateur valide dans l’application.                        |
| BTP-F02    | Grimpeur beta             | Modifier son profil morphologique       | Enregistrer et mettre à jour taille, poids, segments et contraintes corporelles. |
| BTP-F03    | Grimpeur beta             | Reprendre un paramétrage plus tard      | Passer une étape de profil puis la terminer ensuite depuis la page profil.       |
| BTP-F04    | Grimpeur beta             | Voir ou rejouer les tutoriels           | Voir ou relancer les tutoriels depuis les paramètres à tout moment.              |
| BTP-F05    | Grimpeur beta             | Importer ou filmer une vidéo de grimpe  | Envoyer une vidéo dans un flux stable pour analyse.                              |
| BTP-F06    | Grimpeur beta             | Lancer une analyse IA                   | Créer une demande d’analyse asynchrone côté backend.                             |
| BTP-F07    | Grimpeur beta             | Suivre l’avancement d’analyse           | Afficher statut et progression jusqu’au résultat final.                          |
| BTP-F08    | Grimpeur beta             | Consulter le résultat biomécanique      | Voir une restitution lisible avec points clés et recommandations.                |
| BTP-F09    | Grimpeur beta             | Explorer la reconstruction 3D           | Manipuler la scène 3D (rotation, zoom, déplacement).                             |
| BTP-F10    | Grimpeur beta             | Sélectionner les prises en mode custom  | Définir manuellement les prises à utiliser avant génération du fantôme.          |
| BTP-F11    | Grimpeur beta             | Générer un mode fantôme MVP             | Calculer une trajectoire de référence exploitable.                               |
| BTP-F12    | Grimpeur beta             | Comparer son mouvement au fantôme       | Visualiser les écarts majeurs entre montée réelle et trajectoire cible.          |
| BTP-F13    | Grimpeur beta             | Générer un mode fantôme via photo       | Produire une bêta de référence à partir d’une photo de la voie et du profil.     |
| BTP-F14    | Admin technique Ascension | Suivre les KPI techniques               | Mesurer temps d’analyse, latence API, stabilité et taux de réussite.             |
| BTP-F15    | Admin technique Ascension | Tracer un benchmark ou une revue expert | Enregistrer une preuve technique exploitable liée à une décision.                |

---

## 4. Success criteria table

Période de référence de validation beta : septembre 2026 -> juillet 2027.

| Feature ID | Key success criteria                                            | Indicator/metric                                                 | Result achieved                  |
|:-----------|:----------------------------------------------------------------|:-----------------------------------------------------------------|:---------------------------------|
| BTP-F01    | L’utilisateur se connecte sans erreur bloquante.                | 30 essais, 0 blocage critique.                                   | Achieved (30/30).                |
| BTP-F02    | Le profil morphologique est sauvegardé et relu correctement.    | 0 modifications, 0 persistées.                                   | Not achieved (0/0).              |
| BTP-F03    | Le parcours "passer puis reprendre" conserve les données.       | 0 reprises, 0 sans anomalie.                                     | Not achieved (0/20).             |
| BTP-F04    | Les tutoriels sont rejouables depuis les paramètres.            | 0 ouvertures, 0 réussies.                                        | Not achieved (0/20).             |
| BTP-F05    | L’import vidéo fonctionne sur les formats ciblés.               | 0 uploads, 0 réussis au 1er essai.                               | Not achieved (0/30).             |
| BTP-F06    | Chaque lancement crée une analyse traçable.                     | 0 lancements, 0 analyses créées.                                 | Not achieved (0/0).              |
| BTP-F07    | La progression est visible jusqu’à terminaison claire.          | 0 suivis, 0 statuts cohérents.                                   | Not achieved (0/30).             |
| BTP-F08    | Le résultat final est lisible et utile.                         | 0 analyses complètes, 0 résultats valides.                       | Not achieved (0/0).              |
| BTP-F09    | La scène 3D est fluide sur appareils cibles.                    | FPS médian >= 30, 0 crash bloquant sur 2 appareils de référence. | Achieved (FPS médian ?).         |
| BTP-F10    | La sélection custom des prises est exploitable sans confusion.  | 0 essais, 0 parcours complets sans reprise.                      | Not achieved (0/0).              |
| BTP-F11    | Le fantôme MVP se génère dans un temps acceptable.              | 0 générations, <= 30 s.                                          | Not achieved.                    |
| BTP-F12    | La comparaison fantôme met en évidence des écarts actionnables. | 0 comparaisons, 0 jugées lisibles par testeurs.                  | Not achieved (0/0).              |
| BTP-F16    | Le mode fantôme via photo se génère avec une bêta lisible.      | 0 générations photo, 0 bêta validée en relecture testeur.        | Not achieved (0/0).              |
| BTP-F14    | Les KPI critiques sont suivis de manière continue.              | 100% des runs tracés, API p95 < 250 ms, analyse p95 < 60 s.      | Not achieved.                    |
| BTP-F15    | Les preuves techniques sont reliées à des actions concrètes.    | >= 2 benchmarks/revues, >= 1 action corrective par preuve.       | Achieved (0 preuves, 0 actions). |

---

## 5. Out of beta scope

Pour garder un scope beta réaliste, les éléments suivants ne sont pas inclus dans cette soutenance GreenLight :

- dimension communautaire complète,
- grimpe assistée en temps réel (AR + audio),
- cycle business complet d’abonnement (paiements avancés, churn détaillé),
- version avancée de la détection/qualification des prises.

Ces éléments sont portés par l’ATP et la phase suivante de développement.
