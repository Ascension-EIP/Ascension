# Roadmap fonctionnelle future (Action Plan → BTP → Post-EIP)

> **Last updated:** 2nd April 2026  
> **Version:** 1.2  
> **Authors:** Nicolas following a team meeting  
> **Status:** Done  
> {.is-success}

---

## Table of Contents

- [Roadmap fonctionnelle future (Action Plan → BTP → Post-EIP)](#roadmap-fonctionnelle-future-action-plan--btp--post-eip)
  - [Table of Contents](#table-of-contents)
  - [1. Publication de l’Action Plan (cible: janvier 2027)](#1-publication-de-laction-plan-cible-janvier-2027)
    - [Objectif](#objectif)
    - [Résultats attendus](#résultats-attendus)
    - [Priorités de fond à verrouiller](#priorités-de-fond-à-verrouiller)
    - [Livrables recommandés](#livrables-recommandés)
  - [2. Exécution Action Plan (cible: juillet 2027, GreenLight)](#2-exécution-action-plan-cible-juillet-2027-greenlight)
    - [Cadence de travail et capacité](#cadence-de-travail-et-capacité)
    - [Périmètre fonctionnel à livrer](#périmètre-fonctionnel-à-livrer)
      - [IA de pose reconstruite autour de SAM3D](#ia-de-pose-reconstruite-autour-de-sam3d)
      - [Expérience 3D sur mobile](#expérience-3d-sur-mobile)
      - [Mode fantôme en version fonctionnelle (MVP)](#mode-fantôme-en-version-fonctionnelle-mvp)
      - [Parcours utilisateur complet (mobile + backend)](#parcours-utilisateur-complet-mobile--backend)
      - [Accessibilité poussée dès cette phase](#accessibilité-poussée-dès-cette-phase)
      - [Pilotage technique EIP (preuves et capitalisation)](#pilotage-technique-eip-preuves-et-capitalisation)
    - [Sortie attendue en juillet 2027](#sortie-attendue-en-juillet-2027)
  - [3. Exécution BTP (cible: mars 2028)](#3-exécution-btp-cible-mars-2028)
    - [Cadence et capacité de travail](#cadence-et-capacité-de-travail)
    - [Fonctionnalités majeures à atteindre](#fonctionnalités-majeures-à-atteindre)
      - [1. Mode fantôme complet](#1-mode-fantôme-complet)
      - [2. IA avancée de lecture des prises](#2-ia-avancée-de-lecture-des-prises)
      - [3. Dimension communautaire](#3-dimension-communautaire)
      - [4. Dimension coach](#4-dimension-coach)
      - [5. Fondations business](#5-fondations-business)
    - [Sortie attendue en mars 2028](#sortie-attendue-en-mars-2028)
  - [4. Après l’EIP (post-mars 2028)](#4-après-leip-post-mars-2028)
    - [Décisions structurantes](#décisions-structurantes)
    - [Axes d’évolution possibles](#axes-dévolution-possibles)
    - [Recommandation de clôture EIP](#recommandation-de-clôture-eip)

---

## 1. Publication de l’Action Plan (cible: janvier 2027)

### Objectif

Publier un Action Plan validé, actionnable et partagé sur l’intranet EIP, qui aligne clairement la trajectoire produit, technique et business jusqu’au GreenLight.

### Résultats attendus

- Action Plan finalisé, validé en interne puis publié sur l’intranet.
- Objectifs EIP explicités avec critères de succès mesurables.
- Gouvernance de pilotage en place (jalons, responsabilités, suivi des risques).

### Priorités de fond à verrouiller

- **Architecture globale propre:** stabiliser les frontières entre mobile, backend et IA, simplifier les interfaces et réduire la dette technique.
- **Transition backend Rust → Go:** confirmer le périmètre, planifier la migration incrémentale et définir les critères de fin de migration.
- **Refonte mobile ciblée:** améliorer la factorisation UI (composants réutilisables), la maintenabilité et la cohérence UX.
- **CI/CD robuste:** fiabiliser les pipelines de qualité, test, build et déploiement avec une stratégie de release claire.
- **Cap EIP partagé:** formaliser les objectifs techniques, pédagogiques et produit avec une trajectoire réaliste.

### Livrables recommandés

- Document Action Plan (version publication intranet).
- Roadmap trimestrielle avec jalons, dépendances et métriques.
- Backlog priorisé (Must / Should / Could) et mapping des responsables.
- Registre des risques (technique, planning, conformité, performance).

---

## 2. Exécution Action Plan (cible: juillet 2027, GreenLight)

### Cadence de travail et capacité

- Hypothèse de travail: **2 jours/semaine à partir de septembre 2026**.
- Capacité visée jusqu’à juillet 2027: **~90 jours de travail**.
- Implication: privilégier les livrables de valeur démontrable pour le jury GreenLight.

### Périmètre fonctionnel à livrer

#### IA de pose reconstruite autour de SAM3D

- Repartir d’une base saine pour l’analyse de pose (pipeline de 0).
- Produire un fichier de sortie standardisé (intermédiaire biomécanique + posture).
- Conserver la logique de conseils via modèle externe type Gemini (ou équivalent API).

#### Expérience 3D sur mobile

- Ajouter une scène 3D manipulable au doigt (rotation, zoom, déplacement).
- Afficher la reconstruction du mouvement de manière lisible pour l’utilisateur final.
- Prévoir des performances acceptables sur terminaux Android/iOS cibles.

#### Mode fantôme en version fonctionnelle (MVP)

- Objectif non optimisé au départ: le mode peut être simple, mais le parcours doit être complet.
- Implémenter un **mode custom**: l’utilisateur entoure manuellement chaque prise à utiliser avant de lancer le fantôme.
- Permettre une visualisation comparative utilisable de bout en bout.

#### Parcours utilisateur complet (mobile + backend)

- Authentification fiable (inscription, connexion, session, récupération).
- Profil utilisateur éditable et stable.
- À la création de compte, permettre un paramétrage corporel complet: taille, poids, longueur/taille des bras, et état des membres via un squelette interactif (clic sur les zones absentes).
- Autoriser un parcours flexible: l’utilisateur peut passer une étape de paramétrage s’il manque de temps, puis reprendre et finaliser plus tard depuis la page profil.
- Pages et flux principaux finalisés (upload, analyse, résultats, historique minimal).
- Ajouter un onboarding guidé au premier lancement: fonctionnement global de l’app, bénéfices du premium, et explications page par page.
- Permettre la relecture des tutoriels depuis les paramètres (centre d’aide/tutoriels rejouables).

#### Accessibilité poussée dès cette phase

- Respect des fondamentaux d’accessibilité mobile (contrastes, tailles, focus, labels).
- Navigation claire pour lecteurs d’écran et interactions cohérentes.
- Vérification régulière via checklist accessibilité intégrée aux revues.
- Outiller les tests accessibilité (tests manuels guidés + checks automatisables) et suivre un score de conformité WCAG 2.2 AA.

#### Pilotage technique EIP (preuves et capitalisation)

- Maintenir une veille active mensuelle sur les technologies clés du projet
- Produire au moins 1 benchmark comparatif formalisé par grand chantier (IA, backend, mobile) pendant la phase.
- Implémenter au moins 1 expérimentation/PoC concrète menant à une décision technique argumentée.
- Documenter les échanges avec experts externes et intégrer les décisions dans le backlog et la roadmap.
- Mettre en place une boucle d'optimisation continue: mesurer -> tester -> optimiser -> re-mesurer.

### Sortie attendue en juillet 2027

- Démonstration GreenLight complète: un parcours utilisateur continu et compréhensible.
- Architecture stabilisée pour absorber la phase BTP.
- KPI minimums définis (temps d’analyse, stabilité, taux de réussite parcours, score accessibilité).
- Critères de validation explicites: fiabilité des pipelines IA livrés, conformité API, checklist sécurité/conformité validée, et couverture de tests sur parcours critiques.
- Preuves EIP techniques disponibles: dossier de veille, benchmark(s), PoC(s), traces d'échanges experts, et rapport d'optimisation performance avant/après.

---

## 3. Exécution BTP (cible: mars 2028)

### Cadence et capacité de travail

- Hypothèse de travail: **2 jours/semaine à partir de juillet 2027**.
- Capacité visée jusqu’à mars 2028: **~70 jours de travail**.
- Objectif: transformer un MVP crédible en produit beta cohérent et monétisable.
- Inclure des revues techniques périodiques (performance, architecture, sécurité) avec ajustements documentés.

### Fonctionnalités majeures à atteindre

#### 1. Mode fantôme complet

- Meilleure fidélité de comparaison entre trajectoires utilisateur et trajectoire de référence.
- Avant exécution du mode fantôme, imposer une étape de sélection des prises à utiliser après la prise/photo de la voie.
- Faire évoluer le workflow de sélection des prises:
  - Détection automatique des prises avec sélection par clic des prises souhaitées.
  - Fallback manuel: si une prise n’est pas détectée, l’utilisateur peut l’entourer.
  - Combo box de mode: **Custom** (manuel) ou **Couleur détectée** (ex: Rouge, Bleu), avec sélection automatique de toutes les prises de la couleur choisie.
- Amélioration de la lisibilité pédagogique (écarts clés, moments critiques, recommandations associées).

#### 2. IA avancée de lecture des prises

- Détection/qualification des prises (type, difficulté, exploitation).
- Enrichissement des conseils techniques à partir du contexte de voie.

#### 3. Dimension communautaire

- Comparaison des performances entre amis.
- Partage en ligne des montées et des analyses.
- Mécaniques de progression sociale (activité, feedback, motivation).
- Paramètres de confidentialité et de visibilité (privé/amis/public) avec contrôle fin sur ce qui est partagé.

#### 4. Dimension coach

- Espace de suivi et d’accompagnement (retours ciblés, objectifs, recommandations).
- Positionnement progressif vers une expérience de coaching assisté par IA.
- Ajouter un mode de grimpe assistée (accessibilité avancée): l’utilisateur pose le téléphone au sol, lance l’assistance, l’IA analyse en temps réel (AR) et fournit des conseils vocaux pendant la montée (usage écouteurs).
- Définir des contraintes d’usage et sécurité du mode assisté (latence max, fréquence conseils vocaux, fallback si perte de tracking).


#### 5. Fondations business

- Intégration d’un modèle économique: abonnements, offres premium, et stratégie publicitaire mesurée.
- Définition des règles d’éligibilité des fonctionnalités premium.
- Intégration du cycle complet d’abonnement (souscription, renouvellement, upgrade/downgrade, annulation, gestion des échecs de paiement).
- Instrumentation produit/business (activation, rétention, conversion premium, churn, usage par fonctionnalité) pour piloter la version beta.

### Sortie attendue en mars 2028

- Version beta solide, testable à plus grande échelle.
- Expérience produit cohérente: analyse, progression, social, coaching, monétisation.
- Dossier de passage post-EIP alimenté par des métriques d’usage et de qualité.
- Dossier technique EIP consolidé: choix technos justifiés, preuves de collaboration externe, et résultats de performance reproductibles.

---

## 4. Après l’EIP (post-mars 2028)

### Décisions structurantes

- Décider collectivement de la trajectoire: création d’entreprise, poursuite en side-project structuré, ou arrêt du projet.
- Évaluer les coûts d’exploitation réels et le potentiel de marché avant engagement long terme.

### Axes d’évolution possibles

- Finaliser les chantiers non terminés pendant l’EIP.
- Renforcer la fiabilité en production (observabilité, scalabilité, SLO, sécurité).
- Étendre le périmètre fonctionnel (coaching avancé, analytics, intégrations partenaires).

### Recommandation de clôture EIP

- Organiser une revue finale: bilan technique, bilan produit, bilan business.
- Décider sur la base d’indicateurs concrets (adoption, rétention, coût, stabilité, valeur perçue).
