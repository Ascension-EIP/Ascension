---
id: faba3336-1801-474d-bce1-68c099223e66
---

:::success
**Version:** 1.0
:::

---

# ADR-003 : Découplage des pipelines IA (Pose 2D vidéo vs Mode Fantôme photo) et recentrage du périmètre BTP/ATP

- **Date :** 2026-09-26
- **Statut :** Accepté *(Révision de la décision d'idéation de février–mars 2026)*
- **Périmètre :** Architecture IA (`apps/ai`) / Modèle de données (`apps/server`) / Produit & Mobile (`apps/mobile`)
- **Références :** [Product & Technical Scope Pivot Audit](../../../../developer/architecture/audits/product-scope-pivot-audit.md), [Architecture Diagrams](../architecture-and-data-diagrams.md), [Database Schema](../../../../developer/architecture/specifications/database-schema.md)

---

## 1. Contexte et problème

Lors de la phase d'idéation et du *Prototype Pool* (février–mars 2026), l'architecture fonctionnelle et IA d'Ascension avait été imaginée comme un ensemble fortement couplé avant validation complète des contraintes de vision par ordinateur, de pathfinding et de rendu mobile :

- le **Mode Fantôme** devait fonctionner aussi bien sur une photo que sur une vidéo d'escalade (en supposant qu'une image de mur vide pouvait être extraite automatiquement de la vidéo), projeter un avatar fantôme sur la vidéo de l'utilisateur pour calculer une *« beta optimale »*, et permettre une **comparaison directe vidéo-vs-fantôme** (`ghost_id`) ;
- l'analyse **Pose 2D**, la reconstruction **Pose 3D**, la qualification avancée des prises et l'**AR Audio en temps réel** étaient regroupés sans phasage réaliste entre les jalons BTP (*Beta Test Plan* / Greenlight) et ATP (*Acceptance Test Plan*) ;
- la notion de **session d'escalade** (`climbing_sessions`) n'existait pas encore comme conteneur métier regroupant plusieurs ascensions lors d'une séance en salle.

À mesure que les développements IA, backend et mobile ont mûri — puis à la suite du premier suivi de mentoring technique du **11 septembre 2026** mettant en garde contre la surcharge de périmètre — l'équipe a constaté que cette architecture couplée était fragile et non livrable dans les délais de l'EIP.

---

## 2. Options envisagées

| Critère | Option 1 : Conserver le modèle couplé initial *(idéation)* | Option 2 : Découpler en 4 workflows distincts + phasage BTP/ATP | Option 3 : Abandonner le Mode Fantôme pour ne garder que la Pose 2D |
| --- | --- | --- | --- |
| **Faisabilité vision par ordinateur** | Faible (extraction de mur vide sur vidéo tenue à la main et recalage de perspective très fragiles) | **Élevée** (photo dédiée sans grimpeur pour le Mode Fantôme, vidéo dédiée pour la Pose 2D) | Élevée |
| **Pertinence mathématique du pathfinding** | Problématique (*« beta optimale »* mal définie en escalade) | **Maîtrisée** (calcul d'une *beta faisable* adaptée à la morphologie, affichée en images étape par étape) | Sans objet |
| **Validité des comparaisons (F05)** | Invalide (comparer une vidéo dynamique à des étapes synthétiques sous des angles différents) | **Cohérente** (comparaison stricte vidéo-vs-vidéo entre grimpeurs sur le même mur) | Cohérente |
| **Différenciation produit & point dur EIP** | Élevée mais irréaliste à livrer | **Préservée** (Mode Fantôme conservé comme point dur maîtrisé en BTP ; 3D et AR Audio isolés en ATP) | Perdue (perte de la proposition de valeur principale) |
| **Risque calendrier BTP / Greenlight** | Critique | **Maîtrisé** | Faible |

---

## 3. Option choisie

Adoption d'une **architecture découplée en 4 types d'analyses distincts** associés à un conteneur transversal **Sessions d'escalade (`climbing_sessions`)**, avec phasage strict entre BTP et ATP :

1. **Pose 2D sur vidéo (BTP / Greenlight) :** extraction de 33 points clés MediaPipe, métriques numériques, conseils coach LLM, et **comparaison sociale vidéo-vs-vidéo** sur le même mur (`public` / `friends`).
2. **Mode Fantôme strictement sur photo (BTP / Greenlight) :** photo de voie sans grimpeur, détection et regroupement des prises par couleur/groupe (avec sélection manuelle possible), calcul d'une **beta faisable** (et non « optimale ») rendue sous forme d'**images étape par étape**. Aucune exécution sur vidéo, aucun overlay vidéo et aucune liaison vers `comparisons`.
3. **Pose 3D sur vidéo (ATP) :** reconstruction de posture 3D et scène mobile interactive 3D reportées après la stabilisation du pipeline 2D.
4. **AR Audio temps réel (ATP — incertain pour la fin d'EIP) :** guidage vocal en direct sur téléphone fixe (accessibilité), conditionné à la validation latence/précision et à la capacité calendrier.
5. **Sessions d'escalade (`climbing_sessions`) :** regroupement automatique des analyses d'une séance en salle avec durée et statistiques agrégées.

---

## 4. Raison (ce qui a fait changer l'équipe d'avis)

1. **Alerte de surcharge technique au Mentoring #1 (11 sept. 2026) et validation terrain au Mentoring #2 (29 sept. 2026) :** les essais sur photo de voie ont confirmé qu'isoler les prises et décomposer la trajectoire en étapes sur une image fixe était fiable, alors que le recalage sur vidéo en mouvement introduisait des erreurs bloquantes.
2. **Cohérence biomécanique :** en escalade, il n'existe pas une unique « beta optimale » universelle (elle dépend du style, de la force et de la prise de risque) ; viser une **beta faisable adaptée à la morphologie** rend le problème traitable, mesurable et utile pour le grimpeur.
3. **Sécurisation du jalon BTP / Greenlight :** découpler la 2D et le Mode Fantôme photo de la 3D et du temps réel AR permet de livrer un produit de bout en bout stable, testable et démontrable, tout en conservant la feuille de route ATP.

---

## 5. Conséquences acceptées

- **Dette de migration SQL et code à résorber :** la migration `20260918214857_create_comparaisons_table.up.sql` référence encore une colonne héritée `ghost_id` (en plus d'une coquille sur `comparaisons`) et devra être alignée par une migration dédiée sur `base_analysis_id` / `compared_analysis_id` avant l'implémentation des handlers de comparaison.
- **Effort de réconciliation documentaire :** l'audit de novembre 2026 a nécessité la mise à jour coordonnée de l'ensemble de la documentation vivante (architecture, spécifications API/BDD, pipelines IA, roadmaps) tout en laissant intactes les archives figées (`prototype-pool`, `rncp`, comptes-rendus datés).
- **Périmètre BTP réduit sur la 3D et le temps réel :** la visualisation 3D interactive et le mode AR Audio ne seront pas disponibles pour le jalon BTP, et la livraison de l'AR Audio avant la soutenance finale reste explicitement marquée comme incertaine.
- **Complément d'API à exposer :** les endpoints CRUD complets pour `climbing_sessions` et les payloads de sélection de groupes de prises du Mode Fantôme doivent être alignés côté Go et OpenAPI.
