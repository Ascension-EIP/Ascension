<!-- markdownlint-disable MD041 -->

> **Last updated:** 3rd April 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO
> **Status:** Done  
> {.is-success}

---

# Action Plan EIP - Ascension (Technical Track)

---

## Table of Contents

- [Action Plan EIP - Ascension (Technical Track)](#action-plan-eip---ascension-technical-track)
  - [Table of Contents](#table-of-contents)
  - [1. Context](#1-context)
    - [1.1 Origine du projet](#11-origine-du-projet)
    - [1.2 Problème identifié et solution proposée](#12-problème-identifié-et-solution-proposée)
    - [1.3 Vision produit jusqu'au jury GreenLight](#13-vision-produit-jusquau-jury-greenlight)
    - [1.4 Équipe et organisation](#14-équipe-et-organisation)
    - [1.5 Track EIP choisi et objectifs sélectionnés](#15-track-eip-choisi-et-objectifs-sélectionnés)
    - [1.6 Contributeurs externes et experts visés](#16-contributeurs-externes-et-experts-visés)
  - [2. Technical Specifications](#2-technical-specifications)
    - [2.1 Stack technique cible](#21-stack-technique-cible)
    - [2.2 Périmètre technique à livrer pour juillet 2027](#22-périmètre-technique-à-livrer-pour-juillet-2027)
    - [2.3 User stories GreenLight](#23-user-stories-greenlight)
    - [2.4 Plan de mesure, test et optimisation des performances](#24-plan-de-mesure-test-et-optimisation-des-performances)
    - [2.5 Stratégie de tests](#25-stratégie-de-tests)
    - [2.6 Jalons et planning (3 à 5 milestones)](#26-jalons-et-planning-3-à-5-milestones)
    - [2.7 Livrables techniques attendus pour validation](#27-livrables-techniques-attendus-pour-validation)
    - [2.8 Risques majeurs et réponses prévues](#28-risques-majeurs-et-réponses-prévues)
  - [3. Non-Technical Specifications](#3-non-technical-specifications)
    - [3.1 Intention de mentorat](#31-intention-de-mentorat)
    - [3.2 Sujet obligatoire de track: veille technologique active](#32-sujet-obligatoire-de-track-veille-technologique-active)
    - [3.3 Sujet complémentaire choisi: Collaborate with Technical Experts](#33-sujet-complémentaire-choisi-collaborate-with-technical-experts)
    - [3.4 Sujet complémentaire choisi: Measure, Test, and Optimize Technical Performance](#34-sujet-complémentaire-choisi-measure-test-and-optimize-technical-performance)
    - [3.5 Gouvernance, communication et suivi](#35-gouvernance-communication-et-suivi)
    - [3.6 Liste complète pour le jury GreenLight (Go / No Go)](#36-liste-complète-pour-le-jury-greenlight-go--no-go)

---

## 1. Context

### 1.1 Origine du projet

Ascension est un EIP technique porté par une équipe de 5 étudiants Epitech. Le projet est né d'un besoin terrain en escalade: beaucoup de grimpeurs stagnent sans coaching régulier, car le coaching humain coûte cher et reste difficile d'accès.

### 1.2 Problème identifié et solution proposée

Le problème principal est le manque d'outils de coaching autonome vraiment utiles. Les solutions existantes proposent surtout du contenu statique, mais peu d'analyse biomécanique personnalisée.

Ascension répond à ce problème avec une application mobile qui transforme un smartphone en coach d'escalade assisté par IA. L'application peut analyser des vidéos de montée, reconstruire le mouvement et générer des conseils ciblés. Avec le mode fantôme, elle peut donner une visualisation en temps réel de la trajectoire optimale à suivre. Ensuite, grâce au coaching personnalisé, elle permet de s'améliorer, de suivre sa progression et de la partager avec la communauté.

### 1.3 Vision produit jusqu'au jury GreenLight

Notre cible GreenLight (juillet 2027) est de livrer une démonstration complète, stable et compréhensible de bout en bout:

- Un parcours utilisateur complet (compte, profil, upload, analyse, résultats, historique).
- Une IA de pose reconstruite autour de SAM3D avec sortie standardisée.
- Une expérience 3D mobile fluide pour visualiser le mouvement.
- Un mode fantôme MVP fonctionnel et exploitable.
- Des preuves mesurées de qualité, performance, sécurité et accessibilité.

### 1.4 Équipe et organisation

L'équipe Ascension est composée de 5 profils complémentaires (mobile, backend, IA, infra, documentation). Le travail est organisé en monorepo avec trois applications principales: mobile (Flutter), API backend (Go) et workers IA (Python).

L'organisation projet est alignée avec la cadence EIP de Tek4, avec 2 jours par semaine dédiés et un suivi pédagogique régulier.

### 1.5 Track EIP choisi et objectifs sélectionnés

Ascension suit la **Technical Track**.

Objectifs obligatoires intégrés dans cet Action Plan:

- Evaluating and Integrating New Technologies (Technology Watch).
- Structure, Document, and Harden the Project's Technical Architecture.

Objectifs complémentaires sélectionnés:

- Collaborate with Technical Experts.
- Measure, Test, and Optimize Technical Performance.

### 1.6 Contributeurs externes et experts visés

Nous allons solliciter des experts externes ciblés selon les besoins techniques: architecture backend Go, IA vision/pose estimation, optimisation mobile 3D, sécurité et conformité.

Les échanges attendus prennent la forme de revues techniques et de discussions. Chaque échange devra produire une action concrète dans le backlog et une trace documentaire.

---

## 2. Technical Specifications

### 2.1 Stack technique cible

| Couche          | Technologie cible                     | Objectif                                                 |
|-----------------|---------------------------------------|----------------------------------------------------------|
| Mobile          | Flutter / Dart                        | Application iOS et Android unique, UX cohérente          |
| API             | Go (migration depuis Rust)            | Simplifier l'exploitation et stabiliser le socle backend |
| IA              | Python + MediaPipe + PyTorch + OpenCV | Pipeline d'analyse biomécanique reproductible            |
| Broker          | RabbitMQ                              | Découplage API/IA et traitement asynchrone               |
| Base de données | PostgreSQL                            | Stockage métier et résultats d'analyse                   |
| Stockage vidéo  | MinIO (S3 compatible)                 | Upload direct et gestion de cycle de vie                 |
| Observabilité   | Prometheus + Grafana + Loki           | Mesure continue des KPI techniques                       |

### 2.2 Périmètre technique à livrer pour juillet 2027

Le périmètre Action Plan pour le GreenLight couvre les blocs suivants.

1. **Pipeline IA SAM3D reconstruit**
Le traitement doit partir d'une base propre, produire un format de sortie standard et rester exploitable par le mobile et le backend.

2. **Visualisation 3D mobile**
L'utilisateur doit pouvoir lire, tourner et zoomer la reconstruction 3D sans latence bloquante sur appareils cibles.

3. **Mode fantôme MVP**
Le mode doit être utilisable sur un flux complet, avec sélection manuelle des prises (mode custom) avant lancement.

4. **Parcours produit complet**
Authentification, profil morphologique éditable, upload vidéo, analyse, résultat lisible, historique minimal et onboarding rejouable.

5. **Architecture, qualité et sécurité**
Documentation technique à jour, CI/CD robuste, tests sur modules critiques, gestion d'erreurs et sécurité de base en place.

### 2.3 User stories GreenLight

| ID    | User story                                                                                                      | Critère de validation                                         |
|-------|-----------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------|
| US-01 | En tant que grimpeur, je crée un compte et je me connecte sans blocage.                                         | Parcours inscription/connexion validé sur iOS et Android.     |
| US-02 | En tant que grimpeur, je renseigne mon profil morphologique (taille, poids, segments, membres absents/blessés). | Profil sauvegardé, modifiable, et réutilisé par l'analyse.    |
| US-03 | En tant que grimpeur, je peux sauter une étape de profil et la terminer plus tard.                              | Reprise depuis l'écran profil sans perte de données.          |
| US-04 | En tant que grimpeur, j'upload une vidéo puis je lance une analyse.                                             | Statut de job visible et résultat reçu sans erreur bloquante. |
| US-05 | En tant que grimpeur, je visualise ma reconstruction 3D avec rotation et zoom.                                  | Scène 3D interactive et lisible sur devices cibles.           |
| US-06 | En tant que grimpeur, j'utilise un mode fantôme MVP en sélectionnant mes prises.                                | Sélection manuelle + rendu comparatif disponible.             |
| US-07 | En tant que grimpeur, je reçois des conseils techniques générés depuis l'analyse.                               | Conseils cohérents et liés au contexte de la montée.          |
| US-08 | En tant qu'utilisateur, je retrouve mes analyses passées dans un historique.                                    | Historique minimal accessible et stable.                      |
| US-09 | En tant que nouvel utilisateur, je comprends l'app via onboarding guidé.                                        | Tutoriel premier lancement + rejouable dans paramètres.       |
| US-10 | En tant qu'équipe technique, nous suivons les KPI clés sur tableau de bord.                                     | Dashboard alimenté automatiquement à chaque release.          |
| US-11 | En tant qu'équipe technique, nous comparons avant/après les optimisations.                                      | Rapport de benchmark publié par itération majeure.            |
| US-12 | En tant que jury GreenLight, nous observons une démo continue et fiable.                                        | Démo complète validée selon le script officiel interne.       |

### 2.4 Plan de mesure, test et optimisation des performances

Nous appliquons une boucle continue: **mesurer -> tester -> optimiser -> re-mesurer**.

| KPI                                    | Base de mesure (T0)               | Cible GreenLight (juillet 2027)    | Outil de suivi           |
|----------------------------------------|-----------------------------------|------------------------------------|--------------------------|
| Temps d'analyse vidéo           | Mesure initiale en septembre 2026 | <= 240 s                           | Logs backend + Grafana   |
| Taux de jobs IA réussis                | Mesure initiale en septembre 2026 | >= 95 %                            | Metrics worker + alertes |
| Latence API               | Mesure initiale en septembre 2026 | <= 400 ms sur endpoints critiques  | Load tests + Prometheus  |
| Stabilité mobile (crash-free sessions) | Mesure initiale en septembre 2026 | >= 99 %                            | Outil crash reporting    |
| Fluidité scène 3D                      | Mesure initiale en septembre 2026 | >= 30 FPS moyen sur devices cibles | Profiling mobile         |

Les optimisations seront priorisées selon impact mesuré, risque produit, coût d'implémentation et délai jusqu'au jury.

### 2.5 Stratégie de tests

La stratégie de tests est organisée en quatre niveaux.

1. **Tests unitaires et validation de composants critiques**
Les modules sensibles (auth, pipeline IA, traitement résultats) doivent avoir des tests automatisés et reproductibles.

2. **Tests d'intégration et tests de parcours**
Les flux mobile + backend + IA sont testés sur des scénarios utilisateurs réalistes.

3. **Tests de charge, stress et résilience**
Nous simulons des pics de jobs IA, des interruptions de services et des erreurs réseau pour valider la robustesse.

4. **Tests comparatifs avant/après optimisation**
Chaque optimisation importante doit être accompagnée d'un comparatif chiffré et archivé.

### 2.6 Jalons et planning (3 à 5 milestones)

Nous définissons 5 milestones pour piloter la phase Action Plan vers le GreenLight.

| Milestone                                       | Période                | Objectifs principaux                                                       | Sortie attendue                    |
|-------------------------------------------------|------------------------|----------------------------------------------------------------------------|------------------------------------|
| M1 - Cadrage technique et métriques             | Septembre-Octobre 2026 | Baseline KPI, backlog priorisé, registre de risques, plan migration Go     | Dossier de cadrage validé          |
| M2 - Pipeline IA et backend stabilisés          | Novembre-Décembre 2026 | Pipeline SAM3D v1, contrats API stables, observabilité minimum             | Première chaîne technique complète |
| M3 - Expérience mobile et fantôme MVP           | Janvier-Mars 2027      | Scène 3D fonctionnelle, mode custom fantôme, parcours profil complet       | Démo interne fonctionnelle         |
| M4 - Industrialisation et répétition GreenLight | Avril-Mai 2027         | Optimisations performance, accessibilité WCAG 2.2 AA, rehearsal jury blanc | Démo quasi finale + preuves        |
| M5 - Finalisation jury                          | Juin-Juillet 2027      | Hardening final, freeze périmètre, dossier GreenLight complet              | Démo GreenLight prête              |

### 2.7 Livrables techniques attendus pour validation

Les livrables suivants sont obligatoires pour sécuriser la validation GreenLight.

- Action Plan publié et maintenu à jour.
- Roadmap détaillée avec jalons, responsables et dépendances.
- Architecture documentée (diagrammes, flux, choix techniques justifiés).
- README technique complet (installation, déploiement, commandes, variables, prérequis).
- Rapports de veille, benchmarks comparatifs et PoC argumentés.
- Tableaux de suivi KPI avec historique avant/après.
- Rapports de tests (unitaires, intégration, charge, résilience, accessibilité).
- Trace des optimisations réalisées avec mesure d'impact.
- Checklist sécurité/conformité minimale validée.

### 2.8 Risques majeurs et réponses prévues

| Risque                                                 | Impact | Probabilité | Réponse prévue                                                        |
|--------------------------------------------------------|--------|-------------|-----------------------------------------------------------------------|
| Dérive du périmètre avant juillet 2027                 | Élevé  | Moyen       | Priorisation stricte Must/Should/Could et gel de scope en M5          |
| Pipeline IA instable en production de démo             | Élevé  | Moyen       | Jeux de tests dédiés + fallback contrôlé + monitoring temps réel      |
| Migration backend incomplète                           | Moyen  | Moyen       | Plan incrémental avec critères de sortie par lot                      |
| Performance mobile insuffisante sur certains appareils | Élevé  | Moyen       | Profiling régulier + optimisation ciblée + liste devices de référence |
| Manque de preuves pour jury                            | Élevé  | Faible      | Dossier de preuves mis à jour à chaque milestone                      |

---

## 3. Non-Technical Specifications

### 3.1 Intention de mentorat

Le mentorat est un levier direct de réussite GreenLight. Notre objectif est d'utiliser chaque échange mentor pour débloquer une décision claire, réduire un risque et améliorer la qualité du projet.

Chaque session mentor doit se conclure par:

- une synthèse courte,
- des actions assignées,
- une date de vérification,
- une preuve d'implémentation.

### 3.2 Sujet obligatoire de track: veille technologique active

Notre intention est de maintenir une veille continue sur les technologies qui impactent directement Ascension: IA de pose, pipeline de traitement, performance mobile 3D, backend et observabilité.

Objectifs opérationnels:

- Produire des notes de veille mensuelles exploitables.
- Réaliser des comparatifs argumentés et reliés aux besoins du projet.
- Transformer la veille en décisions concrètes (adoption, rejet, report).

### 3.3 Sujet complémentaire choisi: Collaborate with Technical Experts

Notre objectif est d'obtenir des retours externes qualifiés sur les points les plus risqués du projet.

Plan d'action:

- Identifier des experts par domaine (IA, backend Go, mobile 3D, sécurité).
- Préparer des demandes précises avec contexte, question et livrable attendu.
- Organiser des échanges traçables (revue, call, thread technique).
- Convertir chaque échange en actions mesurables dans le backlog.

Preuves attendues:

- Fiches experts (profil, domaine, contact, date d'échange).
- Traces d'échanges (messages, captures, commentaires techniques).
- Notes de synthèse et décisions prises.
- Liste des changements réellement implémentés après retour expert.

### 3.4 Sujet complémentaire choisi: Measure, Test, and Optimize Technical Performance

Notre objectif est de ne jamais optimiser à l'intuition. Toute décision de performance doit être justifiée par une mesure et vérifiée après changement.

Plan d'action:

- Définir un petit set de KPI suivis en continu.
- Exécuter des tests réguliers (charge, stress, résilience, comparatifs).
- Publier les résultats avant/après dans un format lisible par l'équipe et le jury.
- Arbitrer les choix avec un compromis explicite entre qualité, coût, délai et performance.

Preuves attendues:

- Table de KPI et historique de mesures.
- Scripts ou configurations de tests versionnés.
- Dashboards et captures de suivi.
- Rapport d'optimisation avec impact quantifié.

### 3.5 Gouvernance, communication et suivi

Nous utilisons une gouvernance légère et régulière:

- Pilotage toutes les semaines avec avancement par milestone.
- Revue de risques tout les mois.
- Mise à jour documentaire continue (roadmap, décisions, preuves).
- Préparation progressive de la soutenance GreenLight (script, démo, annexes).

La communication interne et externe doit rester simple, factuelle et traçable.

### 3.6 Liste complète pour le jury GreenLight (Go / No Go)

Cette liste est la référence finale à valider avant la soutenance.

- [ ] Démo complète du parcours utilisateur sans rupture majeure.
- [ ] Pipeline IA SAM3D opérationnel avec format de sortie standard.
- [ ] Expérience 3D mobile fluide sur appareils cibles.
- [ ] Mode fantôme MVP utilisable en conditions de démonstration.
- [ ] Authentification, profil, upload, analyse, résultats et historique fonctionnels.
- [ ] Onboarding et tutoriels rejouables disponibles.
- [ ] KPI définis, instrumentés, suivis et interprétés.
- [ ] Rapports de tests charge, stress, résilience et comparatifs disponibles.
- [ ] Rapport avant/après optimisation avec gains mesurés.
- [ ] Dossier de veille technologique à jour avec benchmarks et décisions.
- [ ] Au moins un PoC majeur documenté et relié à une décision projet.
- [ ] Preuves de collaboration avec experts externes et impacts associés.
- [ ] Architecture, README, scripts et documentation technique à jour.
- [ ] CI/CD fiable avec contrôles qualité et gestion des erreurs.
- [ ] Checklist sécurité/conformité minimale validée.
- [ ] Registre des risques maintenu avec plans de mitigation.
- [ ] Storyline de soutenance GreenLight prête (message, démonstration, preuves).

La validation de cette checklist constitue la condition interne de passage en mode soutenance GreenLight.
