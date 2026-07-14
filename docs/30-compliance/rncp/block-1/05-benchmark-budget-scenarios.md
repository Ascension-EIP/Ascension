> **Last updated:** 16th March 2026  
> **Version:** 1.0  
> **Authors:** Darius (Docs), Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# Bloc 1 — M1 — 05 Benchmark, budget et scénarios

---

## Table des matières

- [Bloc 1 — M1 — 05 Benchmark, budget et scénarios](#bloc-1--m1--05-benchmark-budget-et-scénarios)
  - [Table des matières](#table-des-matières)
  - [Objectif](#objectif)
  - [Sources et hypothèses](#sources-et-hypothèses)
  - [Benchmark des options techniques](#benchmark-des-options-techniques)
  - [Structure des coûts](#structure-des-coûts)
    - [CAPEX (ponctuel)](#capex-ponctuel)
    - [OPEX (mensuel)](#opex-mensuel)
  - [Scénarios budgétaires](#scénarios-budgétaires)
  - [Leviers d’optimisation](#leviers-doptimisation)
  - [Point accessibilité (PSH) dans le budget](#point-accessibilité-psh-dans-le-budget)
  - [Traçabilité RNCP M1 (O8, O9)](#traçabilité-rncp-m1-o8-o9)
  - [Calendrier de développement (Horizon 3 ans)](#calendrier-de-développement-horizon-3-ans)

---

## Objectif

Présenter un chiffrage cohérent avec le benchmark et proposer plusieurs scénarios d’exploitation, conformément aux observables O8/O9.

---

## Sources et hypothèses

Sources utilisées :

- `docs/10-product/prototype-pool/workshop/costs.md`
- `docs/10-product/prototype-pool/workshop/costs.xlsx`
- `docs/10-product/prototype-pool/workshop/context-audit-compliance.md`
- `docker-compose.yml` (structure technique réelle)

Hypothèse de méthode : les montants sont repris comme **estimations atelier** et doivent être revalidés avant engagement contractuel (prix cloud, volumétrie, egress, support).

---

## Benchmark des options techniques

Comparatif synthétique (atelier) :

- **Hébergement** : Hetzner retenu face à AWS pour un ratio coût/performance plus favorable au stade MVP.
- **Backend** : Rust/Axum pour efficacité runtime.
- **IA** : Python + MediaPipe/OpenCV pour rapidité de prototypage et écosystème ML.
- **Stockage objet** : MinIO/S3-compatible pour découpler upload et traitement.

Justification repo : ce choix est cohérent avec l’implémentation actuelle (`apps/server`, `apps/ai`, `docker-compose.yml`).

---

## Structure des coûts

### CAPEX (ponctuel)

- Frais de publication stores.
- Branding/domaines.
- Outillage initial.

### OPEX (mensuel)

- Compute API/DB/worker.
- Stockage vidéo + transferts.
- Exploitation (monitoring, sauvegardes, maintenance).

---

## Scénarios budgétaires

Valeurs reprises de `costs.md` (estimations atelier) :

| Scénario           | CAPEX | OPEX mensuel | Coût par utilisateur (indiqué) |
|:-------------------|------:|-------------:|-------------------------------:|
| MVP (100 users)    | 133 € |         96 € |                         0,96 € |
| Scale (1k users)   |   0 € |        231 € |                         0,23 € |
| Scale+ (10k users) |   0 € |        655 € |                         0,06 € |

Lecture recommandée à l’oral :

- Ce sont des **ordres de grandeur** utiles au cadrage.
- Le coût unitaire baisse avec la montée en charge (mutualisation infra).
- Le besoin de gouvernance FinOps augmente avec la volumétrie.

---

## Leviers d’optimisation

- Upload direct S3-compatible (évite transit vidéo via API).
- Pipeline asynchrone (dimensionnement indépendant API/worker).
- Politique de rétention des médias et nettoyage automatique.
- Priorisation des fonctionnalités pour limiter les coûts hors valeur immédiate.

---

## Point accessibilité (PSH) dans le budget

Le budget doit réserver une enveloppe explicite pour :

- audit accessibilité (design + implémentation),
- corrections UI (contraste, focus, alternatives textuelles),
- recette PSH (lecteurs d’écran iOS/Android).

Sans ligne budgétaire dédiée, le risque est de traiter la conformité trop tard et à coût majoré.

---

## Traçabilité RNCP M1 (O8, O9)

| Observable                           | Éléments de preuve                                           | Couverture                            |
|:-------------------------------------|:-------------------------------------------------------------|:--------------------------------------|
| **O8** — analyse financière          | `costs.md`, `costs.xlsx`, cohérence avec architecture réelle | **Forte**                             |
| **O9** — scénarios appuyés benchmark | comparaison provider + 3 scénarios de charge                 | **Forte** (à revalider régulièrement) |

## Calendrier de développement (Horizon 3 ans)
- **0–12 mois: Consolidation.** On stabilise l'analyse vidéo et on s'assure que l'application est parfaitement utilisable par les personnes en situation de handicap (PSH).
- **12–24 mois : Montée en puissance.** On augmente la capacité de nos serveurs pour accueillir plus de grimpeurs et on renforce la protection des données personnelles.
- **24–36 mois : Maturité.** On passe à une gestion automatisée des serveurs et on met en place un système de versions pour que les anciennes applications continuent de fonctionner même après une mise à jour.