> **Last updated:** 4th March 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# Référentiel National de Certification Professionnelle (RNCP)

---

## Table of Contents

- [Vue d'ensemble](#vue-densemble)
- [Modalités d'évaluation](#modalités-dévaluation)
- [Bloc 1 — Cadrer un projet logiciel](#bloc-1--cadrer-un-projet-logiciel)
- [Bloc 2 — Concevoir une architecture logicielle](#bloc-2--concevoir-une-architecture-logicielle)
- [Bloc 3 — Architecture pour applications lourdes](#bloc-3--architecture-pour-applications-lourdes)
- [Bloc 4 — Architecture pour applications web](#bloc-4--architecture-pour-applications-web)
- [Bloc 5 — Assurance qualité](#bloc-5--assurance-qualité)
- [Bloc 6 — Mise en production](#bloc-6--mise-en-production)
- [Bloc 7 — Pilotage de projet](#bloc-7--pilotage-de-projet)

---

## Vue d'ensemble

### Référentiel des blocs de compétences

| Bloc de compétences | Référentiel d'activités | Référentiel de compétences                                             |
| :------------------ | :---------------------- | :--------------------------------------------------------------------- |
| Bloc 1              | A1, A2                  | A1 → `C1, C2` — A2 → `C3, C4, C5`                                      |
| Bloc 2              | A3, A4, A5, A6          | A3 → `C6, C7` — A4 → `C8, C9` — A5 → `C10, C11, C12` — A6 → `C13, C14` |
| Bloc 3              | A7, A8                  | A7 → `C15, C16, C17` — A8 → `C18, C19`                                 |
| Bloc 4              | A9, A10                 | A9 → `C20, C21, C22` — A10 → `C23, C24`                                |
| Bloc 5              | A11, A12                | A11 → `C25, C26, C27` — A12 → `C28, C29`                               |
| Bloc 6              | A13, A14                | A13 → `C30, C31, C32` — A14 → `C33, C34`                               |
| Bloc 7              | A15, A16                | A15 → `C35, C36` — A16 → `C37, C38, C39, C40`                          |

### Correspondance modalités / observables

| Modalité d'évaluation | Critères d'évaluation / Observables |
| :-------------------- | :---------------------------------- |
| M1                    | O1 à O11                            |
| M2                    | O12 à O29                           |
| M3                    | O30 à O51                           |
| M4                    | O40 à O59                           |
| M5                    | O52 à O69                           |
| M6                    | O63 à O71                           |
| M7                    | O72 à O79                           |

---

## Vue d'ensemble

---

## Modalités d'évaluation

Les évaluations certificatives sont réalisées au cours des 3 dernières années d'étude, sous la forme de soutenances de projets préalablement identifiés comme des marqueurs de l'acquisition des compétences professionnelles visées.

Chaque soutenance débute par une **présentation (10 à 20 min)** du projet par le candidat, destinée à s'assurer qu'il répond précisément à l'ensemble des attendus du référentiel. Le candidat s'appuie nécessairement sur un support de présentation en français ou en anglais. Cette présentation est suivie d'un **temps d'échange (20 à 30 min)** avec le jury afin de s'assurer de l'acquisition des compétences.

---

## Bloc 1 — Cadrer un projet logiciel

**1. Cadrer un projet de conception et développement d'une solution logicielle**

### Activités

**A1. Identification du besoin client interne ou externe en solution logicielle ou web**

- Recueil des besoins client
- Définition des priorités stratégiques avec le client ou la direction stratégique de l'organisation
- Analyse de l'existant (système d'information, logiciels, applications...)

**A2. Traduction technique du besoin fonctionnel**

- Analyse de faisabilité technique de la solution
- Rédaction des spécifications techniques et fonctionnelles
- Chiffrage du projet
- Respect du cahier des charges
- Anticipation des risques

### Compétences

- **C1** — Recenser les besoins du client et des utilisateurs en observant et en échangeant avec les parties prenantes afin de cerner les usages prévus, notamment pour les personnes en situation de handicap.
- **C2** — Réaliser un audit technique, fonctionnel et de sécurité de l'environnement dans lequel s'inscrit le projet (infrastructure, système d'information, ressources humaines, ...) afin de proposer les solutions les plus adaptées au contexte, en analysant les solutions déjà en place et leurs effets.
- **C3** — Rédiger les spécifications techniques et fonctionnelles à partir des résultats de l'audit, afin de couvrir tous les besoins clients, en décrivant précisément tous les aspects techniques (spécifications techniques) et humains (spécifications fonctionnelles).
- **C4** — Chiffrer le projet en calculant les éléments financiers de la solution technique et en réalisant un benchmark des solutions existantes afin de cadrer les prévisions budgétaires.
- **C5** — Prévoir les impacts techniques et fonctionnels de la solution préconisée, afin de sécuriser des pistes de mitigation le cas échéant, en s'assurant de sa bonne intégration dans l'environnement d'exploitation du client.

### Modalité d'évaluation — M1

**Mise en situation professionnelle : Cadrage du projet** *(projet de groupe suivi d'une soutenance orale)*

Le candidat doit :

- Présenter de manière claire et organisée l'étude de l'existant dans le cadre proposé.
- Présenter les échanges avec les utilisateurs qui permettent de cerner les besoins et usages (sondages, questionnaires, interviews, observations de terrain...).
- Rédiger les spécifications techniques et fonctionnelles du projet.
- Réaliser un benchmark des solutions proches du projet et l'utiliser pour établir une fourchette fine de chiffrage budgétaire de la solution.
- Modéliser l'architecture technique existante et y intégrer les éléments de solution proposés.
- Structurer le projet en entités testables et livrables indépendamment les unes des autres.
- Modéliser la chaîne opérationnelle dans laquelle la solution doit s'intégrer et y porter les zones de risque potentiels de rupture de chaîne.

### Observables

- **O1**: Le candidat présente une analyse des besoins clients ainsi que les échanges ayant permis son élaboration et couvrant l'intégralité du scope fonctionnel. `[C1]`
- **O2**: Les besoins identifiés tiennent compte des normes en vigueur concernant les usages des personnes en situation de handicap. `[C1]`
- **O3**: Le dossier du candidat contient un compte-rendu d'audit technique, fonctionnel et de sécurité de l'environnement d'exécution du projet mettant en lumière les contraintes et opportunités du contexte opérationnel. `[C2]`
- **O4**: Le candidat est en mesure d'expliquer l'approche méthodologique mise en œuvre pour réaliser l'audit : moyens d'investigation, collecte de retours utilisateurs, ... `[C2]`
- **O5**: Le dossier du candidat présente un corpus de documentations des spécifications techniques et fonctionnelles définissant le périmètre du projet considérant les contraintes identifiées durant l'audit. `[C3]`
- **O6**: Les spécifications techniques et fonctionnelles présentées par le candidat prennent en considération les problématiques d'accessibilité numérique des personnes en situation de handicap. `[C3]`
- **O7**: Les documents présents dans le dossier du candidat respectent les recommandations techniques permettant l'accessibilité aux personnes en situation de handicap. `[C2]` `[C3]`
- **O8**: Le dossier du candidat comporte une analyse financière des coûts de production et d'exploitation de la solution proposée en cherchant à optimiser les coûts et ressources au regard du budget transmis par le client. `[C4]`
- **O9**: Le chiffrage du projet présente différents scénarii en s'appuyant sur les benchmarks réalisés. `[C4]`
- **O10**: Le dossier du candidat comporte une étude prospective des voies d'évolution et de migration en s'appuyant sur l'audit technique réalisé. `[C5]`
- **O11**: Le candidat est capable de vulgariser à l'oral de manière synthétique son étude prospective des voies d'évolution et de migration. `[C5]`

---

## Bloc 2 — Concevoir une architecture logicielle

**2. Concevoir une architecture logicielle**

### Activités

**A3. Veille technologique**

- Suivi des tendances et évolutions technologiques pertinentes pour le projet et évaluation de leur applicabilité et de leur impact
- Suivi de l'actualité relative à la sécurité des systèmes (failles de sécurité, ...)
- Évaluation des outils, frameworks et technologies émergentes

**A4. Prototypage**

- Conception d'une solution logicielle ou web adaptée à la problématique
- Recommandation de solutions créatives et innovantes
- En web : design d'interface
- Adaptation et paramétrage des progiciels retenus
- Prise en compte des contraintes (réglementaires, de sécurité, de trafic, temporelles, d'usage…)
- Prise en compte de l'accessibilité numérique

**A5. Résolution de problèmes algorithmiques complexes**

- Identification des problématiques techniques
- Analyse des pistes de résolution
- Choix des patrons de conception adaptés aux problèmes posés
- Conception de solutions spécifiques pour résoudre un problème nouveau
- Prise en compte des contraintes de complexité algorithmique

**A6. Définition des modèles de données**

- Sélection des solutions de persistance de la donnée
- Adaptation aux contraintes techniques et fonctionnelles
- Prise en compte des enjeux de sécurité
- Sélection des structures de données adaptées
- Prise en compte de la complexité algorithmique

### Compétences

- **C6** — Mettre en place une veille légale et réglementaire prenant en compte les besoins des PSH en menant des recherches fréquentes sur les usages liés aux technologies, en recensant les aspects légaux et réglementaires parus et en participant régulièrement aux rencontres de la communauté professionnelle afin de minimiser la dette technique pour les aspects couverts par le projet.
- **C7** — Réviser régulièrement les protocoles existants, notamment au regard des nouvelles failles de sécurité identifiées afin de contribuer à l'utilisation de standards technologiques élevés au sein de l'entreprise, en impulsant une application régulière des nouveaux usages et outils à l'entreprise.
- **C8** — Présenter une solution technique créative, en collaboration avec l'équipe projet et ses différentes expertises, en prenant en considération les différentes contraintes apportées par le client (économique, RSE, …) ou imposées par l'environnement technique dans le but de résoudre la problématique exposée.
- **C9** — Sélectionner une hypothèse d'architecture et l'urbanisme de la solution logicielle ou web, afin de garantir l'intégration et la pérennité d'une solution, en prenant en compte le reste de l'écosystème technique présent au sein de l'entreprise ainsi que l'accessibilité numérique de la solution.
- **C10** — Traduire les spécifications techniques et fonctionnelles en un système cohérent de composants logiciels en mobilisant son expertise et en s'appuyant sur l'état de l'art en termes d'architecture logicielle afin de produire une solution technique adaptée au besoin du client.
- **C11** — Segmenter chaque problème complexe en un ensemble de sous-problèmes afin d'obtenir des tâches atomiques dans un objectif de performance, d'adaptabilité et de maintenabilité en fonction des besoins du client.
- **C12** — Identifier des solutions existantes ou originales afin de répondre à chaque problème posé en tenant compte des contraintes de performance et de scalabilité de la solution et de son environnement d'exécution.
- **C13** — Sélectionner les solutions de persistance de données (fichier texte ou binaire, format de fichier structuré, base de données...) en s'appuyant sur son expertise et celle de l'équipe projet et en mobilisant l'état de l'art afin de s'adapter aux contraintes techniques, fonctionnelles et de sécurité de l'application en terme de stockage de données.
- **C14** — Sélectionner les structures de données répondant aux contraintes de l'application en tenant compte de leur complexité algorithmique et spatiale (tableaux, listes, sets, tables de hachage...) dans un objectif de performance, de maintenabilité et d'évolutivité de l'application.

### Modalité d'évaluation — M2

**Mise en situation professionnelle : Conception du projet** *(projet de groupe suivi d'une soutenance orale)*

Le candidat doit :

- Présenter plusieurs solutions créatives à partir d'une problématique fournie.
- Identifier de nouveaux usages et outils possibles au sein de l'infrastructure technique existante.
- Mettre en place une veille technique et de sécurité autour des technologies connexes au projet.
- Mettre en place une veille légale et réglementaire pour les aspects couverts par le projet, qui prenne en compte les besoins des PSH.
- Démontrer l'exploration de différentes solutions techniques et défendre les arbitrages réalisés.
- Justifier de ses choix d'architecture et d'implémentation.

### Observables

- **O12**: Le dossier du candidat contient une étude comparative et qualitative des différentes technologies possibles dans le domaine. `[C6]`
- **O13**: L'étude comparative permet d'identifier aisément les technologies permettant de répondre aux besoins des personnes en situation de handicap. `[C6]`
- **O14**: La soutenance présente une étude récente des failles de sécurité des technologies benchmarkées. `[C7]`
- **O15**: Le candidat est en mesure de démontrer sa connaissance de l'actualité de la sécurité informatique sur les domaines relatifs au projet. `[C7]`
- **O16**: Le dossier du candidat présente ses différents travaux de prototypage, ayant permis la réalisation du projet dans le respect des contraintes définies. `[C8]`
- **O17**: Le candidat est capable d'argumenter des avantages et inconvénients de chacun des prototypes présentés. `[C8]`
- **O18**: L'architecture présentée par le candidat s'appuie sur des bonnes pratiques (monolithe, micro-service, ...) permettant de répondre aux exigences techniques et fonctionnelles du projet. `[C9]`
- **O19**: Le candidat est en mesure de soutenir son choix d'architecture et de démontrer son intégration dans l'écosystème technique. `[C9]`
- **O20**: Le dossier du candidat inclut une implémentation respectant l'architecture présentée. `[C10]`
- **O21**: L'implémentation présentée par le candidat respecte les bonnes pratiques en vigueur (clean-code, mobilisation des paradigmes de programmation appropriés, design-patterns, ...). `[C10]`
- **O22**: Le code présenté dans le dossier du candidat est organisé de manière rationnelle et claire. `[C11]`
- **O23**: La segmentation du code présenté par le candidat répond aux objectifs fixés (performance, adaptabilité, maintenabilité). `[C11]`
- **O24**: Le code présenté dans le dossier du candidat implémente des algorithmes existants optimaux pour la résolution de problèmes connus lorsqu'ils existent. `[C12]`
- **O25**: Le code proposé par le candidat intègre des solutions originales dans le cas où des algorithmes ad-hoc ne sont pas disponibles. `[C12]`
- **O26**: Les choix techniques de persistance de données sont cohérents avec les besoins du projet en considération des contraintes techniques, fonctionnelles et de sécurité. `[C13]`
- **O27**: Le candidat est en mesure de justifier de ses choix technologiques entre différentes solutions adaptées aux contraintes de l'application. `[C13]`
- **O28**: Le code implémenté dans le dossier du candidat présente des structures de données adaptées aux contraintes du projet et aux choix technologiques réalisés. `[C14]`
- **O29**: Le candidat est en mesure de justifier de la pertinence de ses choix de structures de données au regard des objectifs de performance, de maintenabilité et d'évolutivité de l'application. `[C14]`

---

## Bloc 3 — Architecture pour applications lourdes

**3. Créer une architecture logicielle pour des applications "lourdes"**

### Activités

**A7. Implémentation des interactions avec le système d'information**

- Gestion des entrées et sorties (ex : traitement et lecture de fichier, IHM)
- Gestion de la communication réseau (ex : connexion à des logiciels tiers, choix des protocoles de type TCP, UDP, HTTP...)
- Vérification de l'intégrité des données traitées
- Respect des normes de conformité et de sécurité

**A8. Mise en place de fonctionnalités complexes avec traitement autonome**

- Rédaction d'un code optimisé (C, C++, Python, Java...)
- Traitement de tâches à forts besoins en ressources
- Utilisation optimisée des ressources
- Recours à des algorithmes spécifiques (chiffrement de données...)
- Veille aux caractéristiques : scalabilité, évolutivité, performance, sécurité et maintenabilité

### Compétences

- **C15** — Concevoir les interfaces (GUI, TUI, CLI, …) afin de garantir une bonne expérience utilisateur dans le respect des conventions d'UI et d'UX spécifiques aux modalités d'interactions concernées, en optimisant les vues et en respectant les critères reconnus d'accessibilité.
- **C16** — Vérifier l'intégrité des données traitées en s'appuyant sur les techniques de vérification de données et dans le respect des normes de conformité et de sécurité afin de s'assurer que la donnée n'a pas été corrompue et de prévenir ainsi les dysfonctionnements du logiciel.
- **C17** — Sélectionner les solutions techniques adaptées (protocoles, formats de fichiers...) en utilisant des composants logiciels tiers (bibliothèque) afin de proposer des implémentations permettant l'interopérabilité avec d'autres systèmes.
- **C18** — Rédiger le code à l'aide du langage informatique adapté au logiciel en implémentant les solutions techniques précédemment identifiées, afin de concrétiser la vision et la valeur du produit par le client.
- **C19** — Intégrer l'usage de codes tiers au code produit en s'appuyant sur la documentation et en suivant les instructions relatives aux solutions retenues afin d'optimiser le temps de production et l'efficacité ainsi que la maintenabilité du code.

### Modalité d'évaluation — M3

**Mise en situation professionnelle : Mise en place d'une solution logicielle** *(projet de groupe suivi d'une soutenance orale)*

Le candidat doit :

- Réaliser plusieurs UI/UX qui respectent les normes d'accessibilité en vigueur et les différents documents de conception.
- Rédiger les composants logiciels nécessaires à rendre la solution fonctionnelle en respectant les critères de lisibilité, de maintenabilité et de réutilisabilité du code ainsi que la stabilité de ladite solution.

### Observables

- **O30**: La solution présentée comporte diverses interfaces (graphiques et/ou textuelles) réfléchies afin d'optimiser l'expérience utilisateur. `[C15]`
- **O31**: Les interfaces implémentées intègrent les exigences techniques et ergonomiques en matière d'accessibilité numérique. `[C15]`
- **O32**: Le code implémenté dans le dossier du candidat contient les vérifications nécessaires pour garantir l'intégrité des données traitées et la stabilité de la solution. `[C16]`
- **O33**: Le candidat est capable d'expliquer les moyens mis en œuvre garantissant l'intégrité et/ou la confidentialité des données traitées. `[C16]`
- **O34**: La solution s'appuie sur un ensemble de normes et de composants tiers existants et reconnus comme robustes. `[C17]`
- **O35**: Le candidat est capable de justifier de la pertinence de sa sélection de composants tiers au vu de l'environnement technologique. `[C17]`
- **O36**: Le dossier du candidat contient un code opérationnel répondant aux exigences fonctionnelles identifiées lors du recueil des besoins utilisant des langages de programmation adaptés à l'environnement d'exécution de l'application. `[C18]`
- **O37**: Le code de la solution respecte les bonnes pratiques en matière de conventions de formatage et de nommage pour les langages utilisés. `[C18]`
- **O38**: Le code de la solution implémente les appels nécessaires à l'intégration des composants tiers sélectionnés. `[C19]`
- **O39**: Le code de la solution traite de manière adéquate les cas d'erreur déclarés par ces composants tiers. `[C19]`

---

## Bloc 4 — Architecture pour applications web

**4. Créer une architecture logicielle pour des applications web**

### Activités

**A9. Pilotage du développement du front-end**

- Rédaction et vérification de code optimisé (HTML, CSS, JavaScript…)
- Développement d'interfaces utilisateurs (UI, UX)
- Responsive design et prise en compte de l'accessibilité numérique
- Optimisation du site pour les utilisateurs et les moteurs de recherche (SEO)
- Utilisation de frameworks et de bibliothèques (React, Flutter, Vue.js...)

**A10. Pilotage du développement du back-end**

- Rédaction et vérification de code optimisé (Java, Python, PHP, Node.js, SQL…)
- Utilisation de frameworks ou bibliothèques (Spring, Django, Laravel, Express.js, ORM…)
- Écriture et utilisation de scripts
- Création de l'infrastructure numérique (serveur)
- Respect des normes de conformité et de sécurité
- Gestion des bases de données

### Compétences

- **C20** — Concevoir les interfaces web en ayant recours aux langages dédiés (HTML, CSS, Javascript, ...) afin de garantir une bonne expérience utilisateur (UI/UX), en optimisant les vues et en respectant les critères reconnus d'accessibilité.
- **C21** — Rédiger le code à l'aide du langage informatique adapté au type d'application web, en implémentant les solutions techniques précédemment identifiées, afin de concrétiser la vision et la valeur du produit par le client.
- **C22** — Simplifier le développement de l'architecture web en utilisant des frameworks et des bibliothèques pour gérer l'état de l'application et encourager la réutilisation de composants.
- **C23** — Rédiger le code à l'aide des langages de programmation adaptés au développement back-end en utilisant des frameworks ou des bibliothèques pour accélérer le développement et fournir des fonctionnalités avancées.
- **C24** — Mettre en place les mesures de sécurité identifiées lors de l'audit pour protéger l'application web contre les attaques, gérer les sessions utilisateurs, les erreurs et exceptions en utilisant des composants logiciels identifiés comme sûrs et en les intégrant en suivant les bonnes pratiques afin de garantir le niveau de sécurité exigé par le projet.

### Modalité d'évaluation — M4

**Mise en situation professionnelle : Mise en place d'une solution web** *(projet de groupe suivi d'une soutenance orale)*

Le candidat doit :

- Réaliser plusieurs UI/UX qui respectent les normes d'accessibilité en vigueur et les différents documents de conception.
- Rédiger les composants logiciels nécessaires à rendre la solution fonctionnelle en respectant les critères de lisibilité, de maintenabilité et de réutilisabilité du code ainsi que la stabilité de ladite solution.

### Observables

- **O40**: La solution présentée comporte diverses interfaces graphiques réfléchies afin d'optimiser l'expérience utilisateur. `[C20]`
- **O41**: Les interfaces graphiques implémentées intègrent les exigences techniques et ergonomiques en matière d'accessibilité numérique. `[C20]`
- **O42**: Le candidat est en mesure de justifier ses choix ergonomiques et l'agencement de ses interfaces graphiques. `[C20]`
- **O43**: Le dossier du candidat contient un code opérationnel répondant aux exigences fonctionnelles identifiées lors du recueil des besoins en matière d'interface web. `[C21]`
- **O44**: Le code côté client de la solution respecte les bonnes pratiques en matière de conventions de formatage et de nommage pour les langages web utilisés. `[C21]`
- **O45**: Le code de la solution utilise des composants tiers facilitant l'implémentation d'interfaces web. `[C22]`
- **O46**: Le code de la solution traite de manière adéquate les cas d'erreur en les présentant de manière claire et didactique à l'utilisateur. `[C22]`
- **O47**: Le dossier du candidat contient un code côté serveur opérationnel répondant aux exigences fonctionnelles identifiées lors du recueil des besoins. `[C23]`
- **O48**: Le code côté serveur de la solution respecte les bonnes pratiques en termes d'utilisation des ressources (requêtes optimisées en base de données, durée de vie de la donnée, ...). `[C23]`
- **O49**: Le code côté serveur de la solution respecte les bonnes pratiques en matière de conventions de formatage et de nommage pour les langages web utilisés. `[C23]`
- **O50**: Le code de la solution répond aux bonnes pratiques en termes de sécurité de la session utilisateur (chiffrement des données confidentielles, sécurisation de la connexion, authentification ...). `[C24]`
- **O51**: Le code de la solution comprend une gestion des erreurs robuste garantissant la stabilité et la sécurité de l'application (vérification des codes HTTP des requêtes REST, protection contre les injections, ...). `[C24]`

---

## Bloc 5 — Assurance qualité

**5. Définir et piloter la politique d'assurance qualité d'un projet de développement d'une solution logicielle**

### Activités

**A11. Élaboration de la politique de test**

- Intégration du processus qualité tout au long de la vie du projet
- Définition des protocoles et scénarii de tests (unitaires, fonctionnels, d'intégration, de performance)
- Détection des erreurs et traitement des dysfonctionnements
- Analyse de résultats et rapports de tests
- Audit de sécurité et gestion de vulnérabilité

**A12. Élaboration de normes et de processus qualité relatifs à l'usage informatique**

- Définition des normes de documentation, d'écriture de code, compte rendu d'activité…
- Prise en compte de l'accessibilité pour les personnes en situation de handicap
- Mise en place d'activités de contrôle qualité

### Compétences

- **C25** — Définir un protocole de tests et piloter ses différentes phases, afin de garantir la qualité pendant le développement et avant la livraison finale, en scénarisant et paramétrant la phase de tests.
- **C26** — Sélectionner les outils, scripts et frameworks les plus adaptés à l'implémentation du protocole de test afin d'atteindre les objectifs définis par la politique de test, en mobilisant son expertise et celle de l'équipe projet.
- **C27** — Tester la solution en termes de charge et de fonctionnalités, afin de proposer des correctifs adéquats au bon moment, en écrivant les tests nécessaires (unitaires, fonctionnels, d'intégration, de performance) et en auditant l'infrastructure en matière de sécurité.
- **C28** — Élaborer une stratégie d'assurance qualité en définissant les normes et processus de qualité et en tenant compte des normes d'accessibilité pour les personnes en situation de handicap afin d'assurer un suivi par l'équipe de développement.
- **C29** — Mettre en œuvre les activités spécifiques nécessaires à l'évaluation de la qualité de la solution logicielle en s'appuyant sur les outils adaptés (revues de code, audits, tests de conformités aux normes, revues de documentation, ...) dans l'objectif de répondre aux objectifs définis par la stratégie d'assurance qualité.

### Modalité d'évaluation — M5

**Mise en situation professionnelle : Définir et piloter la politique d'assurance qualité** *(projet de groupe suivi d'une soutenance orale)*

Le candidat doit :

- Soutenir la cohérence de la politique de test établie et attester de sa mise en place concrète.
- Illustrer (par le biais d'outils de gestion de versions notamment) les différentes phases d'intégration successives pour arriver à la livraison de la solution.
- Documenter (en français ou en anglais) les choix qui sous-tendent la rédaction du code et les phases de déploiement, à destination de nouveaux venus sur le projet.
- Attester du bon respect des normes et processus qualité spécifiés préalablement (CR d'audit, résultats d'outil d'analyse statique de code, taux de couverture des tests ...).

### Observables

- **O52**: Le dossier du candidat présente une documentation complète présentant la politique de test mise en œuvre en cohérence avec les attendus liés au projet. `[C25]`
- **O53**: Le candidat est capable de défendre les choix réalisés au cours de la définition de sa politique de test. `[C25]`
- **O54**: Le protocole de test présenté fait appel à des composants existants adaptés aux cas d'usage et répondant aux exigences définies dans la politique de test. `[C26]`
- **O55**: Le candidat est en mesure d'argumenter de la pertinence des choix de composants existants réalisés par l'équipe projet ou par lui-même. `[C26]`
- **O56**: Le code de la solution contient l'ensemble des tests correspondant au protocole décrit. `[C27]`
- **O57**: L'implémentation des tests couvre de manière exhaustive les scénarios qu'ils décrivent. `[C27]`
- **O58**: Le dossier du candidat contient une référence documentaire décrivant une stratégie d'assurance qualité cohérente. `[C28]`
- **O59**: La stratégie d'assurance qualité présentée intègre les normes d'accessibilité numérique pour les personnes en situation de handicap. `[C28]`
- **O60**: Le candidat est capable d'exposer la pertinence de la stratégie d'assurance qualité qu'il a élaborée. `[C29]`
- **O61**: Le dossier du candidat contient les preuves (compte-rendus, artéfacts, tickets, ...) prouvant les actions mettant en œuvre la stratégie décrite. `[C29]`
- **O62**: Le candidat est capable de montrer que les correctifs exigés par l'application de la stratégie d'assurance qualité ont été mis en œuvre (présentation de l'historique de modification du code). `[C29]`

---

## Bloc 6 — Mise en production

**6. Piloter la mise en production d'un projet de développement d'une solution logicielle**

### Activités

**A13. Gestion du déploiement technique de la solution logicielle ou web**

- Mise en place des ressources nécessaires à la mise en production du projet (serveurs, services cloud...)
- Respect des bonnes pratiques d'administration système et réseau (mots de passe, configuration du réseau et des machines pour éviter les vulnérabilités, clés de chiffrement…)

**A14. Conseil aux parties prenantes d'un projet de solution logicielle ou web**

- Sensibilisation aux bonnes pratiques de sécurité
- Veille au respect des réglementations sur la protection des données (RGPD)
- Stratégie de livraison
- Dialogue avec les différents services de l'organisation (ventes, marketing, opérations…)
- Documentation des processus
- Communication technique et intelligible

### Compétences

- **C30** — Sélectionner les technologies et services adaptés pour l'hébergement ou déploiement de la solution en termes de dimensionnement et de disponibilité, en prenant en considération les contraintes du client (budget, sécurité, scalabilité, qualité de service).
- **C31** — Implémenter les systèmes d'automatisation nécessaires à garantir la fiabilité du déploiement et la disponibilité de la solution ainsi qu'à optimiser le processus de mise à jour du projet en définissant précisément les tâches à automatiser, les interactions avec les autres systèmes, ainsi que les contraintes techniques et les performances attendues.
- **C32** — Faire appliquer les normes de sécurité en vigueur en respectant les bonnes pratiques d'administration système et réseau pour prémunir la solution déployée contre les intrusions ou les attaques par déni de service.
- **C33** — Rédiger la documentation à toutes les étapes de développement en garantissant l'évolution possible de la solution dans le temps et selon les besoins afin de pérenniser la solution et de permettre sa reprise ultérieure par une autre équipe, dans le respect de la réglementation en vigueur.
- **C34** — Communiquer avec les collaborateurs et les clients afin de garantir la collaboration entre les différents acteurs du projet, en partageant les éléments (avancées, blocages, demandes, livraisons) en sa possession de manière structurée et en adaptant la documentation pour permettre son appropriation par tout type de public, y compris en situation de handicap.

### Modalité d'évaluation — M6

**Mise en situation professionnelle : Mise en production du projet** *(projet de groupe suivi d'une soutenance orale)*

Le candidat doit :

- Rédiger des notices à visée préventive à destination des utilisateurs du SI en vulgarisant les risques ainsi que les conseils et consignes.
- Réaliser des tests d'intrusion pour tester la robustesse du code d'une solution donnée.
- Présenter un compte-rendu reprenant les préconisations de renforcement de la sécurité suite aux résultats des tests d'intrusion.
- Exposer la solution de déploiement du projet et son automatisation partielle ou complète.

### Observables

- **O63**: Le dossier du candidat contient un document présentant une solution d'hébergement ou de déploiement répondant aux besoins de la solution. `[C30]`
- **O64**: Le candidat est capable de justifier ses choix au regard des contraintes exposées par le client (budget, sécurité, scalabilité, qualité de service). `[C30]`
- **O65**: Le dossier du candidat contient une procédure détaillant la mise en œuvre des technologies et services sélectionnés dans le cas concret de la solution. `[C31]`
- **O66**: Le candidat est en mesure de démontrer que la procédure de déploiement de la solution est fonctionnelle et permet d'assurer la disponibilité de l'application. `[C31]`
- **O67**: La documentation présentée par le candidat contient les éléments démontrant la prise en compte des bonnes pratiques en matière de sécurité des systèmes d'information. `[C32]`
- **O68**: Le candidat est capable d'attester de l'implémentation des solutions de sécurisation de l'infrastructure applicative. `[C32]`
- **O69**: Le dossier du candidat présente un ensemble documentaire détaillant les choix technologiques, d'architecture et d'implémentation. `[C33]`
- **O70**: Le candidat est en mesure d'argumenter que ses choix technologiques, d'architecture et d'implémentation garantissent la pérennité de l'application dans le temps. `[C33]`
- **O71**: Le dossier du candidat contient des éléments attestant d'échanges réguliers entre les parties prenantes au projet à travers différents moyens de communication dont le candidat devra justifier les choix. `[C34]`
- **O72**: Le candidat est capable lors de la soutenance de présenter l'ensemble du projet de manière à se rendre compréhensible à un auditoire non technique. `[C34]`
- **O73**: Le candidat est capable lors de la soutenance d'engager un échange technique approfondi avec un expert du domaine. `[C34]`
- **O74**: Les documents présents dans le dossier du candidat respectent les recommandations techniques permettant l'accessibilité aux personnes en situation de handicap. `[C33]` `[C34]`

---

## Bloc 7 — Pilotage de projet

**7. Piloter un projet de conception et développement d'une solution logicielle**

### Activités

**A15. Gestion de projet informatique complexe**

- Planification et priorisation des tâches
- Suivi des délais
- Choix d'une méthodologie adaptée (agile, ITIL...)
- Interface avec les designers, développeurs et autres parties prenantes

**A16. Management d'équipes projet multidisciplinaires en contexte international**

- Définition des objectifs
- Animation de réunions de travail
- Communication en langue anglaise professionnelle
- Assignation des responsabilités et promotion du développement des compétences
- Prise en charge des collaborateurs en situation de handicap
- Maîtrise des contraintes techniques et organisationnelles d'une équipe multi-site

### Compétences

- **C35** — Définir l'ensemble des phases techniques du projet et les tâches à prévoir, afin d'anticiper les écarts techniques et de prévenir les résistances au déploiement de la solution dans les délais prévus.
- **C36** — Allouer les ressources (humaines et matérielles) au projet afin de l'insérer dans un portefeuille de projets informatiques, en tenant compte des besoins sur le projet et de la charge de l'ensemble du portefeuille.
- **C37** — Identifier les ressources humaines nécessaires au projet (en présence ou à trouver/développer), afin de respecter scrupuleusement le cahier des charges, en précisant les contraintes de temps, d'effort et de spécificités du projet.
- **C38** — Monitorer l'avancement du projet et son équipe afin de garantir sa performance, sa cohérence et son bien-être, en mettant en place les outils et méthodes nécessaires au bon déroulement du projet et en proposant des outils et aménagements spécifiques pour les membres de l'équipe en situation de handicap temporaire ou permanent.
- **C39** — Diffuser les informations au sein de l'équipe en utilisant les moyens mis à disposition par l'entreprise (réunion présentielle ou distancielle, messagerie interne, email, ...) et en respect des exigences définies par la politique de sécurité du client, afin de garantir la bonne compréhension des missions par tous les membres de l'équipe, en tenant compte des éventuels besoins particuliers des personnes en situation de handicap.
- **C40** — Collaborer dans un contexte international en utilisant l'anglais comme langue de travail, en présentiel et en distanciel, afin d'intégrer des équipes interculturelles.

### Modalité d'évaluation — M7

**Mise en situation professionnelle : Pilotage du projet et de l'équipe** *(projet de groupe suivi d'une soutenance orale)*

Le candidat doit :

- Arbitrer l'ordre de développement des éléments stratégiques du projet.
- Définir les tâches et les responsabilités générées par la gestion du projet.
- Proposer une solution de collaboration à mettre en œuvre au sein du projet.
- Utiliser les outils de gestion de projets en réponse aux choix stratégiques arrêtés.
- Présenter les éléments nécessaires au recrutement d'une équipe professionnellement alignée avec les attentes du projet (fiches de poste, connaissances et compétences requises, durée prévue des missions...).
- Proposer un tableau de bord reprenant les indicateurs de suivi du travail de l'équipe.
- Documenter et rendre disponibles les outils et les contenus collaboratifs présentiels (compte-rendus de réunion, ...) et distanciels (documents partagés, dépôts Git, ...), où les échanges sont menés en anglais.
- Rendre accessibles les informations et documents nécessaires au bon fonctionnement de l'équipe à tous les membres, notamment les PSH.

### Observables

- **O75**: Le dossier du candidat doit inclure une planification détaillée des différentes tâches de production en tenant compte de leurs éventuelles interdépendances et des contraintes de temps. `[C35]`
- **O76**: Le candidat est capable de défendre ses choix d'ordonnancement des différentes tâches en considération des interdépendances éventuelles. `[C35]`
- **O77**: Le dossier du candidat doit présenter les ressources humaines et matérielles allouées pour la réalisation optimale des tâches planifiées en considération des contraintes de disponibilité desdites ressources. `[C36]`
- **O78**: Le candidat est en mesure de justifier de l'affectation optimale des ressources humaines et matérielles sur les tâches, en considération des priorités internes et externes au projet et de la charge estimée pour leur bonne réalisation. `[C36]`
- **O79**: Le candidat doit justifier des compétences attendues pour chacune des ressources humaines au regard du contexte technologique et organisationnel du projet. `[C37]`
- **O80**: La présentation du candidat expose le processus d'identification et de recrutement des membres de l'équipe projet et présente le rôle de chacun au regard de ses compétences. `[C37]`
- **O81**: La présentation du candidat démontre l'usage d'un ou plusieurs outils de pilotage de l'équipe de développement tout au long du cycle de vie du projet. `[C38]`
- **O82**: Les métriques remontées par le ou les outils de pilotage montrent une maîtrise du rythme d'avancement du projet et de la gestion des aléas. `[C38]`
- **O83**: La présentation du candidat doit exposer les différents moyens de communication mis en place et utilisés par l'équipe projet. `[C39]`
- **O84**: Le candidat peut argumenter que les différents moyens de communication utilisés respectent les exigences de confidentialité du projet et du respect de la vie privée de l'équipe. `[C39]`
- **O85**: La présentation du candidat met en lumière la prise en compte des besoins spécifiques des personnes en situation de handicap. `[C38]` `[C39]`
- **O86**: Le dossier contient des documentations techniques ou organisationnelles rédigées en anglais. `[C40]`
- **O87**: Le candidat est en mesure de réaliser sa présentation et d'interagir avec le jury à l'oral en anglais. `[C40]`