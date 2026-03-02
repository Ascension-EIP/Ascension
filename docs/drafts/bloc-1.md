---
title: bloc-1
description: 
published: true
date: 2026-03-02T10:41:04.851Z
tags: 
editor: markdown
dateCreated: 2026-02-11T20:40:56.361Z
---

> **Last updated:** 10th February 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Status:** In Progress  
> {.is-warning}

---

# Bloc 1

---

## Table of Contents

- [C1](#c1)


Bloc 1 :

- Le candidat présente une analyse des besoins clients ainsi que les échanges ayant permis son élaboration et couvrant
  l'intégralité du scope fonctionnel [C1]
- Les besoins identifiés tiennent compte des normes en vigueur concernant les usages des personnes en situation de handicap
  [C1]
- Le dossier du candidat contient un compte-rendu d'audit technique, fonctionnel et de sécurité de l'environnement
  d'éxécution du projet mettant en lumière les contraintes et opportunités du contexte opérationnel [C2]
- Le candidat est en mesure d'expliquer l'approche méthodologique mise en oeuvre pour réaliser l'audit : moyens
  d'investigation, collecte de retours utilisateurs, ... [C2]
- Le dossier du candidat présente un corpus de documentations des spécifications techniques et fonctionnelles définissant le
  périmètre du projet considérant les contraintes identifiées durant l'audit [C3]
- Les spécifications techniques et fonctionnelles présentées par le candidats prennent en considération les problématiques
  d'accessibilité numérique des personnes en situation de handicap [C3]
- Les documents présents dans le dossier du candidats respectent les recommandations techniques permettant l'accessilité
  aux personnes en situation de handicap [C2] [C3]
- Le dossier du candidat comporte une analyse financière des coûts de production et d'exploitation de la solution proposée en
  cherchant à optimiser les coûts et ressources au regard du budget transmis par le client [C4]
- Le chiffrage du projet présente différents scénarii en s'appuyant sur les benchmarks réalisés [C4]
- Le dossier du candidat comporte une étude prospective des voies d'évolution et de migration en s'appuyant sur l'audit
  technique réalisé [C5]
- Le candidat est capable de vulgariser à l'oral de manière synthétique son étude prospective des voies d'évolution et de
  migration [C5]

---

## C1

L'identification du besoin est née d'une problématique concrète rencontrée
au sein de notre équipe projet, composée majoritairement
de pratiquants réguliers d'escalade. Lors de nos sessions en salle, nous avons
constaté une difficulté récurrente : l'impossibilité d'analyser
objectivement notre propre technique pendant la grimpe. Cette observation empirique
nous a conduits à échanger avec d'autres grimpeurs et
à identifier un besoin plus large : l'accès limité à un feedback technique précis,
généralement réservé aux grimpeurs bénéficiant d'un coach personnel.

---

L'application respecte les normes WCAG 2.1 (Web Content Accessibility Guidelines) niveau AA, notamment :

-Contraste des couleurs : ratio minimum de 4.5:1 pour la lisibilité des textes et des résultats d'analyse
-Navigation vocale : compatibilité avec VoiceOver (iOS) et TalkBack (Android)
pour les utilisateurs malvoyants consultant leurs statistiques de progression
-Taille des éléments tactiles : boutons d'au moins 48x48px pour faciliter l'interaction
-Alternatives textuelles : descriptions audio des analyses vidéo pour les personnes malvoyantes
-Contrôle de la lecture vidéo : possibilité de mettre en pause, ralentir, pour les utilisateurs ayant
des troubles cognitifs ou de l'attention

Bien que l'activité d'escalade elle-même présente des contraintes physiques,
l'interface de consultation et d'analyse reste accessible au plus grand nombre, permettant
également aux coachs ou accompagnants de personnes en situation de handicap d'utiliser l'outil.
