:::success
**Version:** 1.0
:::

---

# ADR-001 : Choix de PostgreSQL 18 comme base de données hybride (relationnel + JSONB)

- **Date :** 2026-03-02
- **Statut :** Accepté
- **Périmètre :** Données / Backend (`apps/server`) / IA (`apps/ai`)
- **Références :** [Database Benchmark](../../../../developer/architecture/benchmark/database.md), [Database Schema](../../../../developer/architecture/specifications/database-schema.md)

---

## 1. Contexte et problème

La plateforme Ascension doit persister deux familles de données aux caractéristiques très différentes :

1. **Un socle métier strictement relationnel :** comptes utilisateurs, authentification, profils morphologiques, abonnements, quotas mensuels d'analyse, sessions d'escalade et relations sociales. Ces données exigent des garanties ACID (*Atomicity, Consistency, Isolation, Durability*), des clés étrangères et des jointures multi-tables fiables.
2. **De la télémétrie biomécanique semi-structurée :** séquences de 33 points clés (*keypoints*) extraits par MediaPipe à 30 images par seconde (environ 29 700 points de données pour une vidéo de 30 secondes), courbes d'angles articulaires, métriques calculées et conseils générés par l'intelligence artificielle.

L'équipe (5 développeurs maîtrisant déjà PostgreSQL, MySQL/MariaDB et MongoDB) devait trancher entre une base unique capable d'absorber les deux charges et une architecture polyglotte (une base SQL + une base NoSQL).

---

## 2. Options envisagées

| Critère | PostgreSQL 18 | MySQL 8.x / MariaDB | MongoDB (ou SQL + MongoDB) |
| --- | --- | --- | --- |
| **Intégrité relationnelle (ACID & clés étrangères)** | Complète et stricte | Complète (InnoDB) | Limitée en mono-nœud ; ACID multi-documents coûteux (Replica Set requis) |
| **Stockage semi-structuré (télémétrie IA)** | Natif via `JSONB` binaire + indexation GIN | JSON texte avec indexation limitée | Natif via BSON, très performant en écriture documentaire |
| **Jointures multi-tables complexes** | Optimiseur avancé très performant | Bon | Faible (`$lookup` verbeux et coûteux) |
| **Évolutivité IA (recherche vectorielle)** | Extension native `pgvector` | Plugins tiers requis | Atlas Vector Search (lié au cloud managé) |
| **Complexité opérationnelle** | Faible (1 seul conteneur) | Faible (1 seul conteneur) | Élevée en architecture polyglotte (2 moteurs, 2 sauvegardes, 2 migrations) |

---

## 3. Option choisie

**PostgreSQL 18** comme moteur de base de données unique pour l'ensemble de la plateforme, en combinant tables relationnelles normalisées et colonnes `JSONB` pour les sorties d'analyse biomécanique.

---

## 4. Raison

1. **Unification sans persistance polyglotte :** PostgreSQL couvre nativement les transactions critiques (abonnements, décrémentation concurrente des quotas) tout en stockant les payloads denses de télémétrie biomécanique dans des colonnes `JSONB` indexables (index GIN). Maintenir deux moteurs distincts (ex. MySQL + MongoDB) aurait doublé la charge de sauvegarde, de supervision et de migration pour une équipe de 5 personnes.
2. **Supériorité sur le requêtage mixte :** Par rapport à MySQL/MariaDB, le format binaire `JSONB` de PostgreSQL évite le re-parsing texte à chaque lecture et autorise des requêtes ciblées dans les structures imbriquées.
3. **Ouverture vers les évolutions IA :** La disponibilité de l'extension `pgvector` permet d'envisager ultérieurement la comparaison vectorielle de mouvements sans introduire de base vectorielle supplémentaire.

---

## 5. Conséquences acceptées

- **Croissance du volume de la base :** stocker des tableaux `JSONB` de plusieurs centaines de kilo-octets par analyse augmente la taille des tables et impose de surveiller le TOAST (*The Oversized-Attribute Storage Technique*), le *vacuum* et la politique de rétention.
- **Évolution de schéma JSONB non contrainte par le SGBD :** contrairement aux colonnes relationnelles, la structure interne des documents `JSONB` doit être validée côté applicatif (Go et Python) et versionnée pour éviter les régressions de désérialisation.
- **Montée en charge horizontale :** en cas de très forte volumétrie future, le partitionnement (*table partitioning*) ou l'externalisation des payloads bruts vers le stockage objet S3 devra être envisagé.
