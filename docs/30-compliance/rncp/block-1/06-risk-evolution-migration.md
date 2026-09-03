> **Last updated:** 16th March 2026  
> **Version:** 1.0  
> **Authors:** Darius (Docs), Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# Bloc 1 — M1 — 06 Risques, évolutions et migration

---

## Table des matières

- [Bloc 1 — M1 — 06 Risques, évolutions et migration](#bloc-1--m1--06-risques-évolutions-et-migration)
  - [Table des matières](#table-des-matières)
  - [Objectif](#objectif)
  - [Registre des risques prioritaires](#registre-des-risques-prioritaires)
  - [Zones de rupture de chaîne opérationnelle](#zones-de-rupture-de-chaîne-opérationnelle)
  - [Stratégie d’évolution (24–36 mois)](#stratégie-dévolution-2436-mois)
    - [Horizon 0–12 mois](#horizon-012-mois)
    - [Horizon 12–24 mois](#horizon-1224-mois)
    - [Horizon 24–36 mois](#horizon-2436-mois)
  - [Stratégie de migration technique](#stratégie-de-migration-technique)
  - [Plan de mitigation et gouvernance](#plan-de-mitigation-et-gouvernance)
  - [Vulgarisation orale (O11) — trame 90 secondes](#vulgarisation-orale-o11--trame-90-secondes)
  - [Traçabilité RNCP M1 (O10, O11)](#traçabilité-rncp-m1-o10-o11)

---

## Objectif

Présenter une étude prospective réaliste sur les risques et les voies d’évolution/migration, en s’appuyant sur l’audit existant et le code implémenté.

Sources :

- `docs/10-product/prototype-pool/workshop/impacts-risks.md`
- `docs/10-product/prototype-pool/workshop/context-audit-compliance.md`
- `apps/ai/src/worker.py`
- `apps/server/src/inbound/http.rs`
- `apps/server/migrations/*.sql`

---

## Registre des risques prioritaires

| Risque                           | Impact                            | Probabilité    | Niveau      | Mitigation clé                                                     |
|:---------------------------------|:----------------------------------|:---------------|:------------|:-------------------------------------------------------------------|
| Précision modèle IA insuffisante | Qualité feedback dégradée         | Moyenne/haute  | Élevé       | Dataset métier + validation utilisateur + indicateurs de confiance |
| Indisponibilité RabbitMQ/DB      | Blocage du flux d’analyse         | Moyenne        | Élevé       | Queue durable, retry, supervision, procédure de reprise            |
| Fuite de données sensibles       | Risque légal et réputationnel     | Faible/moyenne | Élevé       | Durcissement secrets, chiffrement, revue d’accès, conformité RGPD  |
| Dette accessibilité PSH          | Non-conformité et exclusion usage | Moyenne        | Moyen/élevé | Check-list WCAG/RGAA, recettes PSH dédiées                         |
| Écart docs vs implémentation     | Défaut de pilotage                | Moyenne        | Moyen       | Sync documentaire continue et revues croisées                      |

---

## Zones de rupture de chaîne opérationnelle

Chaîne cible : Upload -> Queue -> Worker -> DB -> Restitution.

Points de rupture :

1. **Upload impossible** (URL invalide, erreur storage).
2. **Job non consommé** (queue/broker indisponible).
3. **Traitement IA échoué** (erreur librairie, format vidéo).
4. **Écriture DB impossible** (connexion/timeouts).
5. **Restitution incomplète** (résultat absent, hints nuls).

Mesures déjà visibles :

- `vision.skeleton` durable, messages persistants.
- Retry de connexion RabbitMQ côté worker.
- Passage explicite en `failed` avec `nack requeue=False` pour éviter boucle infinie.

---

## Stratégie d’évolution (24–36 mois)

### Horizon 0–12 mois

- Stabiliser le flux vidéo-analyse en production pédagogique.
- Renforcer observabilité (SLA internes, alerting exploitable).
- Industrialiser la recette accessibilité mobile.

### Horizon 12–24 mois

- Monter en charge via scaling workers.
- Clarifier séparation “features socle” vs “features premium”.
- Durcir gouvernance RGPD (rétention, journalisation, suppression).

### Horizon 24–36 mois

- Évolution infra vers orchestration plus robuste selon trafic.
- Migrations DB additives-first avec rollback maîtrisé.
- Versionnement API/contrats pour éviter les ruptures client.

---

## Stratégie de migration technique

Principes :

- **Additive first** sur schéma DB (colonnes/tables ajoutées avant bascule).
- **Compatibilité ascendante** API durant transition.
- **Feature flags** pour activer progressivement les nouvelles capacités.
- **Plan de retour arrière** documenté par lot.

Exemple déjà présent dans l’existant :

- Ajouts incrémentaux `progress` puis `hints` dans `analyses` via migrations dédiées.

---

## Plan de mitigation et gouvernance

- Revue mensuelle des risques (technique, sécurité, conformité, PSH).
- Propriétaire identifié par risque (Lead, DevOps, Mobile, AI, Docs).
- Décisions d’architecture tracées par écrit avant implémentation structurante.
- Mise à jour documentaire synchronisée après chaque changement majeur.

---

## Vulgarisation orale (O11) — trame 90 secondes

“Notre stratégie d’évolution repose sur une chaîne asynchrone simple : upload, mise en file, traitement IA, restitution. Les risques principaux sont la qualité du modèle IA, la disponibilité de l’infrastructure et la conformité des données sensibles. On les traite avec des mesures concrètes déjà visibles dans le code (queue durable, gestion explicite des échecs, migrations incrémentales) et avec un plan d’évolution en 3 horizons. L’objectif n’est pas de promettre une perfection immédiate, mais de démontrer une trajectoire maîtrisée, mesurable et compatible avec nos contraintes de budget et d’accessibilité.”

---

## Traçabilité RNCP M1 (O10, O11)

| Observable                                      | Éléments de preuve                                                       | Couverture |
|:------------------------------------------------|:-------------------------------------------------------------------------|:-----------|
| **O10** — étude prospective évolution/migration | registre de risques + feuille de route + stratégie de migration additive | **Forte**  |
| **O11** — capacité à vulgariser                 | trame orale courte, orientée décision/risque/mitigation                  | **Forte**  |
