<!-- markdownlint-disable MD041 -->

> **Last updated:** 20th April 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Original language:** French  
> **Status:** Done  
> {.is-success}

---

# Retour d'Expérience (REX): Piscine de Prototypage

Ce document dresse le bilan de notre expérience durant la "Prototyping Pool". Entre découvertes techniques majeures et frustration organisationnelle, voici le ressenti de l'équipe Ascension sur ces cinq semaines intensives.

---


## Table of Contents

- [Retour d'Expérience (REX): Piscine de Prototypage](#retour-dexpérience-rex-piscine-de-prototypage)
  - [Table of Contents](#table-of-contents)
  - [1. Contexte](#1-contexte)
  - [2. Ce qui nous a plu (Points Positifs)](#2-ce-qui-nous-a-plu-points-positifs)
    - [Évolution de la vision produit](#évolution-de-la-vision-produit)
    - [Validation et pivot technique](#validation-et-pivot-technique)
    - [Découverte de nouvelles technologies](#découverte-de-nouvelles-technologies)
    - [Accompagnement pédagogique](#accompagnement-pédagogique)
    - [IA \& Prompt Engineering](#ia--prompt-engineering)
  - [3. Ce qui nous a moins plu (Points Négatifs)](#3-ce-qui-nous-a-moins-plu-points-négatifs)
    - [La course contre la montre et la "contrainte" de l'IA](#la-course-contre-la-montre-et-la-contrainte-de-lia)
    - [Une organisation parfois floue](#une-organisation-parfois-floue)
    - [La lourdeur administrative](#la-lourdeur-administrative)
  - [4. Notre ressenti (Comment on l'a vécu)](#4-notre-ressenti-comment-on-la-vécu)
    - [Entre stress et satisfaction](#entre-stress-et-satisfaction)
    - [Le sentiment d'un changement de paradigme](#le-sentiment-dun-changement-de-paradigme)
    - [Le besoin de décompression](#le-besoin-de-décompression)
  - [Conclusion](#conclusion)

---

## 1. Contexte

La piscine s'est déroulée en deux phases distinctes :

1.  **Phase de cadrage (3 semaines) :** Focus total sur l'administratif, les benchmarks, la documentation stratégique et la définition de la stack technique.
    
2.  **Phase de POC (2 semaines) :** Développement d'un prototype fonctionnel de bout en bout pour valider notre flux de données.
    
3.  **Finalisation :** Soutenance du bloc RNCP 1 une semaine après la fin de la piscine.
    

---

## 2. Ce qui nous a plu (Points Positifs)

### Évolution de la vision produit

On est partis d'idées de fonctionnalités un peu floues pour arriver à un projet structuré. Ce temps "forcé" de réflexion nous a permis d'améliorer nos features (notamment le Mode Fantôme) et de confronter nos choix techniques à la réalité du marché via l'étude de terrain.

### Validation et pivot technique

Le POC a rempli son rôle de "crash test". On a codé les premières briques en **Rust** pour se rendre compte, à l'usage, que ce n'était pas le choix le plus optimal pour notre vélocité et nos besoins actuels. Ce moment nous a permis de pivoter sereinement vers **Go** avant d'attaquer le développement concrêt.

### Découverte de nouvelles technologies

L'obligation de sortir un prototype complet nous a poussés à mettre les mains dans des outils qu'on ne maîtrisait pas : **RabbitMQ** pour la gestion des queues, **MinIO** pour le stockage S3, et l'intégration de **MediaPipe**. Le repo est maintenant propre et bien setup grâce à **moonrepo**.

### Accompagnement pédagogique

L'équipe pédagogique a été très présente. Pouvoir échanger de vive voix et obtenir des retours directs a été un vrai plus pour ajuster le tir en temps réel.

### IA & Prompt Engineering

Les objectifs nous ont poussés à intégrer l'IA au cœur de notre architecture. On a énormément progressé en **prompt engineering**. On est conscients que notre métier évolue et cette piscine nous a forcés à adopter une posture d'architecte "AI-augmented".

---

## 3. Ce qui nous a moins plu (Points Négatifs)

### La course contre la montre et la "contrainte" de l'IA

C'est sans doute le point le plus frustrant de cette piscine. On nous demandait un POC fonctionnel en seulement deux semaines sur des technos et des langages qu'on découvrait totalement. Avec des follow-ups tous les deux jours, on a vite compris que si on ne produisait pas un résultat "waouh" immédiatement, on passait pour des retardataires. Cette pression constante nous a enfermés dans une impasse : il est physiquement impossible de monter en compétence proprement sur du Rust ou du RabbitMQ tout en livrant une architecture complète en si peu de temps.

Résultat, on s'est sentis **contraints d'utiliser l'IA à outrance**. Ce n'était plus une aide, c'était devenu une obligation pour ne pas couler face aux attentes. On a fini par produire du code "sous perfusion" de LLM pour satisfaire les exigences des encadrants qui en demandaient toujours plus. Le constat est d'ailleurs flagrant : certains groupes qui ont poussé l'utilisation de l'IA à l'extrême ont carrément fini leur projet de bout en bout en deux semaines. De notre côté, nous n'étions pas pour cette approche au départ, car nous valorisons la compréhension de ce que nous produisons. Mais face aux contraintes actuelles et à l'évolution de l'école (qui semble délaisser l'expertise technique pure pour la réalisation rapide) nous avons été bien obligés de nous adapter pour rester compétitifs.

Le revers de la médaille est amer : on se retrouve aujourd'hui avec une base de code qu'on n'a pas pris le temps de mûrir et un besoin vital de **refactoriser pas mal de fichiers (~ 70%)** généré à la va-vite. On a eu l'impression que la pédagogie privilégiait la vitesse de démo et le "produit fini" plutôt que la réelle maîtrise technique et la qualité de l'ingénierie que l'on attend d'un étudiant en Technical Track. C'est paradoxal de nous pousser à être des experts tout en nous forçant à devenir des "copier-coller" d'IA pour tenir des délais irréalistes.

### Une organisation parfois floue

Le flux d'informations était assez irrégulier. Certaines consignes arrivaient au compte-gouttes, notamment sur les modalités précises de la review finale, ce qui a ajouté un stress évitable à une période déjà chargée.

### La lourdeur administrative

On ne va pas se mentir : passer trois semaines sur de la doc et de la paperasse administrative, c'est frustrant pour des profils techniques. On comprend la nécessité de ces documents pour le RNCP et la structure du projet, mais le ratio temps passé sur de la documentation et de l'administratif vs temps passé dans à coder était parfois décourageant.

---

## 4. Notre ressenti (Comment on l'a vécu)

### Entre stress et satisfaction

L'équipe s'est très bien organisée. L'ambiance dans le groupe est restée excellente malgré la charge. Cependant, chaque follow-up agissait comme une douche froide : on pensait être dans les clous, et on ressortait avec une liste de suggestions et de demandes ("Et l'AR ?", "Et l'accessibilité pour les handicapés ?") qui augmentait le périmètre du projet de manière exponentielle.

### Le sentiment d'un changement de paradigme

On sent que l'école évolue : l'accent n'est plus mis sur la formation d'experts en développement pure, mais sur des "product makers" capables de livrer extrêmement vite en utilisant tous les outils disponibles (IA en tête). C'est efficace, mais on a parfois eu l'impression de sacrifier la maîtrise technique profonde sur l'autel de la rapidité de démonstration.

### Le besoin de décompression

Après la présentation finale, un temps d'arrêt a été indispensable. Ce surplus d'informations et de conseils (parfois contradictoires) nous avait un peu fait perdre de vue nos objectifs réels. On a profité de l'après-piscine pour se recentrer, poser un **Action Plan** clair et un **Beta Test Plan** réaliste.

---

## Conclusion

Cette piscine a été un mal nécessaire. Elle nous a permis de solidifier les fondations d'Ascension et de valider notre stack technique (quitte à en changer). On en ressort avec un projet qui tient la route, une équipe soudée, mais aussi une petite fatigue face à la méthodologie "full IA" imposée par les délais. On est maintenant prêts à attaquer la phase de développement réelle, avec plus de recul sur notre produit.
