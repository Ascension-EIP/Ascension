---
id: adc9e53d-256a-4f03-81f1-ef2f09c1955c
---

:::success
**Version:** 1.0\
**Original language:** French\
DON'T EDIT THIS FILE !
:::

---

# Bloc 1 — M1 — 01 Analyse des besoins

---

## Objectif du document

Formaliser l’analyse des besoins pour la modalité M1 (Bloc 1 RNCP), en s’appuyant sur des preuves déjà présentes dans le dépôt, sans extrapoler au-delà des artefacts existants.

---

## Périmètre et sources

Sources principales exploitées :

- `docs/compliance/rncp/block-1/besoin.md`
- `docs/product/prototype-pool/workshop/client-needs-and-functional-scope.md`
- `docs/product/prototype-pool/workshop/context-audit-compliance.md`
- `docs/product/prototype-pool/workshop/tech-func-specs.md`
- `docs/product/prototype-pool/workshop/presentation/oral_25-02_ppt_content.md`
- `docs/resources/rncp/rncp.md`

Ce document couvre le besoin client, le besoin utilisateur, la priorisation et l’intégration des exigences PSH attendues au Bloc 1.

---

## Méthodologie de recueil

Méthode retenue (déclarative + preuves repo) :

1. **Analyse documentaire** des ateliers produit (`docs/product/prototype-pool/workshop/*`).
2. **Consolidation des personas** et user stories depuis `client-needs-and-functional-scope.md`.
3. **Rapprochement avec le cadrage RNCP** (`docs/resources/rncp/rncp.md`, observables O1/O2).
4. **Validation de cohérence** avec les contraintes techniques et d’audit (`context-audit-compliance.md`).

Limite assumée : les comptes-rendus d’entretiens terrain sont mentionnés dans la documentation atelier, mais ne sont pas archivés ici sous forme de verbatim brut.

---

## Parties prenantes et besoins exprimés

### 1\. Parties prenantes identifiées

- **Utilisateurs finaux grimpeurs** (intermédiaires, experts) : progression technique, feedback objectif.
- **Équipe produit/tech Ascension** : faisabilité MVP à budget contraint.
- **Contexte réglementaire** : données vidéo corporelles, conformité RGPD.
- **Jury RNCP** : traçabilité de bout en bout entre besoin, spécification, et chiffrage.

### 2\. Besoins utilisateurs consolidés

| Segment | Besoin principal | Douleur actuelle | Réponse Ascension (cible) |
| --- | --- | --- | --- |
| Grimpeur intermédiaire | Comprendre ses erreurs de posture | Feedback humain coûteux et irrégulier | Analyse vidéo asynchrone + restitution exploitable |
| Grimpeur expert | Optimiser la séquence de mouvements | Difficulté à objectiver les micro-ajustements | Comparaison trajectoire + métriques biomécaniques |
| Utilisateur PSH (ex. malvoyance partielle) | Accéder aux résultats sans friction | Interfaces non vocalisées / contraste insuffisant | Contraintes WCAG 2.1 AA intégrées aux specs |

### 3\. Besoin business

- Délivrer un coaching technique à faible coût unitaire.
- Prioriser un **MVP réaliste** avant extensions avancées (ghost enrichi, routines personnalisées, etc.).

---

## Périmètre fonctionnel consolidé

Consolidation issue de `client-needs-and-functional-scope.md` et `tech-func-specs.md` :

### Must Have (MVP Bloc 1)

- Upload vidéo et démarrage d’analyse.
- Analyse squelette (pipeline `vision.skeleton`).
- Restitution des résultats d’analyse.

### Should / Could (hors MVP strict)

- Détection de prises avancée.
- Ghost mode enrichi.
- Routines d’entraînement personnalisées.

### Out of scope explicite (version actuelle)

- Marketplace de coaching humain.
- Intégration AR live.

---

## Exigences accessibilité (PSH)

Exigences prises en compte dès la phase besoin (O2) via les documents ateliers :

- Référence WCAG 2.1 AA dans `docs/product/prototype-pool/workshop/tech-func-specs.md`.
- Cas d’usage PSH cités dans `docs/product/prototype-pool/workshop/presentation/oral_25-02_ppt_content.md`.
- Besoin de navigation compatible lecteur d’écran + lisibilité (contraste, taille d’actions).

Décision de cadrage : l’accessibilité n’est pas un add-on de fin de projet, mais un critère d’acceptation fonctionnelle.

---

## Traçabilité RNCP M1 (O1, O2)

| Observable | Éléments de preuve | Couverture |
| --- | --- | --- |
| **O1** — analyse des besoins + échanges | Personas, user stories, backlog priorisé dans `client-needs-and-functional-scope.md` + méthode d’enquête dans `context-audit-compliance.md` | **Partielle à forte** (verbatim d’entretiens à mieux formaliser) |
| **O2** — prise en compte PSH | Exigences WCAG et contraintes PSH dans `tech-func-specs.md` + support oral atelier | **Partielle** (à renforcer par une matrice de conformité testable) |

---

## Points ouverts à sécuriser avant oral

- Ajouter une annexe “preuves d’échanges” (format court : date, profil, besoin exprimé, décision impactée).
- Transformer les exigences PSH en check-list de critères d’acceptation vérifiables écran par écran.
- Préparer une diapo de synthèse “besoin -> choix MVP -> compromis assumés”.
