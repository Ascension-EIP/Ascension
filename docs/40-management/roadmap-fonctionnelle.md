# Roadmap fonctionnelle

> **Last updated:** 5th April 2026  
> **Version:** 1.3  
> **Authors:** Nicolas following a team meeting  
> **Status:** Done  
> {.is-success}

---

## Table of Contents

- [Roadmap fonctionnelle](#roadmap-fonctionnelle)
  - [Table of Contents](#table-of-contents)
  - [Règle importante sur les noms](#règle-importante-sur-les-noms)
  - [1. Livraison initiale (septembre 2026): Action Plan + BTP](#1-livraison-initiale-septembre-2026-action-plan--btp)
    - [Objectif de l'étape](#objectif-de-létape)
    - [Période et jalon](#période-et-jalon)
    - [Cadence de travail](#cadence-de-travail)
    - [Priorités de travail](#priorités-de-travail)
    - [Livrables attendus](#livrables-attendus)
    - [Critères de validation](#critères-de-validation)
  - [2. Exécution du BTP (septembre 2026 → juillet 2027)](#2-exécution-du-btp-septembre-2026--juillet-2027)
    - [Objectif de l'étape](#objectif-de-létape-1)
    - [Période et jalon](#période-et-jalon-1)
    - [Cadence de travail](#cadence-de-travail-1)
    - [Priorités de travail](#priorités-de-travail-1)
    - [Livrables attendus](#livrables-attendus-1)
    - [Critères de validation](#critères-de-validation-1)
  - [3. Passage GreenLight + livraison ATP (juillet 2027)](#3-passage-greenlight--livraison-atp-juillet-2027)
    - [Objectif de l'étape](#objectif-de-létape-2)
    - [Période et jalon](#période-et-jalon-2)
    - [Cadence de travail](#cadence-de-travail-2)
    - [Priorités de travail](#priorités-de-travail-2)
    - [Livrables attendus](#livrables-attendus-2)
    - [Critères de validation](#critères-de-validation-2)
  - [4. Exécution de l'ATP (août 2027 → mars 2028)](#4-exécution-de-latp-août-2027--mars-2028)
    - [Objectif de l'étape](#objectif-de-létape-3)
    - [Période et jalon](#période-et-jalon-3)
    - [Cadence de travail](#cadence-de-travail-3)
    - [Priorités de travail](#priorités-de-travail-3)
    - [Livrables attendus](#livrables-attendus-3)
    - [Critères de validation](#critères-de-validation-3)
  - [5. Après l'EIP (à partir de mars 2028)](#5-après-leip-à-partir-de-mars-2028)
    - [Date de départ](#date-de-départ)
    - [Décisions structurantes](#décisions-structurantes)
    - [Axes d'évolution possibles](#axes-dévolution-possibles)
    - [Recommandation de clôture EIP](#recommandation-de-clôture-eip)

---

## Règle importante sur les noms

- **Action Plan**: document qui explique **comment on travaille** (méthode, organisation, suivi), pas le détail fonctionnel du produit.
- **BTP (Beta Test Plan)**: document qui décrit **ce qu'on doit livrer pour le GreenLight**.
- **ATP (Alpha Test Plan)**: document qui décrit **ce qu'on doit livrer pour la phase alpha** jusqu'au jury de mars 2028.

---

## 1. Livraison initiale (septembre 2026): Action Plan + BTP

### Objectif de l'étape

Poser une base très propre dès septembre 2026 pour démarrer le travail produit dans de bonnes conditions, sans flou sur l'organisation, la technique, et l'administratif.

### Période et jalon

- Période: **avril 2026** à **septembre 2026**.
- Jalon: tout ce qui est administratif et préparatoire est livré avant le démarrage complet de l'exécution du BTP.

### Cadence de travail

- Charge prévue: **0 jours de travail officiel par semaine** (seulement quand on a le temps).
- Rythme de pilotage: **aucun, seulement via annonce sur le serveur Discord**.

### Priorités de travail

- Obtenir une **architecture globale propre** entre mobile, backend et IA.
- Finaliser une **CI/CD robuste** pour fiabiliser test, build, qualité et livraison.
- Avoir la **transition Rust → Go finie** dès cette étape (si ce n'est pas fini ici, ce sera prioritaire pendant l'exécution du BTP).
- Lancer une **refonte du mobile** (si ce n'est pas fini ici, ce sera prioritaire pendant l'exécution du BTP).
- Préparer un **GitHub Project / backlog à jour**, déjà paramétré pour guider le travail de septembre à août.
- Terminer les **formalités administratives**: Action Plan, BTP, vidéo promotionnelle, vidéo de présentation, et éléments équivalents attendus.
- Mettre en place un **registre des risques** clair et maintenu.

### Livrables attendus

- Action Plan livré (document méthode de travail).
- BTP livré (document périmètre produit GreenLight).
- Dossier administratif et communication prêt (vidéos et pièces demandées).
- CI/CD opérationnel, backlog prêt, registre des risques prêt.

### Critères de validation

- Les documents Action Plan et BTP sont validés et partageables.
- Le pipeline CI/CD tourne de façon fiable sur les parcours critiques.
- La migration Rust → Go est finie ou proche de la fin et planifiée jusqu'à finalisation.
- L'équipe peut démarrer l'exécution du BTP sans blocage organisationnel.

---

## 2. Exécution du BTP (septembre 2026 → juillet 2027)

### Objectif de l'étape

Construire et livrer tout ce qui est attendu par le BTP pour arriver au GreenLight avec une démonstration complète, compréhensible et solide.

### Période et jalon

- Période: **septembre 2026 à juillet 2027**.
- Jalon: en juillet 2027, le GreenLight vérifie le BTP et décide le **go / no-go**.

### Cadence de travail

- Charge prévue: **2 jours de travail par semaine**.
- Rythme de pilotage: **1 sprint + 1 suivi toutes les 6 semaines** pendant cette période.
- Capacité indicative: environ **90 jours de travail** sur la période.

### Priorités de travail

- Terminer la migration **Rust → Go** pour qu'elle soit stable et propre pendant l'exécution.
- Finaliser la **refonte mobile prioritaire** si elle n'était pas terminée en septembre 2026.
- Refaire l'IA de pose autour de **SAM3D** avec une base saine.
- Produire un fichier de sortie standardisé (biomécanique + posture) et garder la logique de conseils via modèle externe (type Gemini ou équivalent API).
- Ajouter une expérience **3D mobile** lisible (rotation, zoom, déplacement) avec des performances correctes sur Android/iOS cibles.
- Livrer un **mode fantôme MVP** fonctionnel de bout en bout, incluant le mode custom où l'utilisateur entoure les prises à utiliser.
- Assurer un **parcours utilisateur complet** (auth, profil, upload, analyse, résultats, historique minimal), y compris le paramétrage corporel et la reprise plus tard depuis le profil.
- Ajouter un **onboarding guidé** au premier lancement et des tutoriels rejouables depuis les paramètres.
- Appliquer une **accessibilité mobile forte** (contraste, taille, focus, labels, tests manuels guidés, checks automatisables, suivi WCAG 2.2 AA).
- Continuer le **pilotage technique EIP**: veille mensuelle, benchmark(s), PoC(s), décisions techniques argumentées, et boucle d'optimisation continue.

### Livrables attendus

- Version BTP exécutable avec une démonstration complète du parcours utilisateur.
- Architecture stabilisée et API conformes au périmètre prévu.
- Preuves techniques disponibles (veille, benchmark, PoC, optimisation avant/après, échanges experts documentés).
- KPI minimum définis: temps d'analyse, stabilité, taux de réussite parcours, score accessibilité.

### Critères de validation

- Le BTP est couvert par des fonctionnalités démontrables de bout en bout.
- Le GreenLight peut vérifier les preuves techniques et la qualité globale.
- Les points critiques (IA, mobile, backend, accessibilité) ne bloquent pas la suite.
- La décision go/no-go peut être prise sur des éléments mesurables et traçables.

---

## 3. Passage GreenLight + livraison ATP (juillet 2027)

### Objectif de l'étape

Passer le GreenLight avec un dossier BTP propre, puis livrer l'ATP pour lancer la phase suivante sans perte de temps.

### Période et jalon

- Période: **juillet 2027**.
- Jalons:
  - Passage du **GreenLight** (contrôle du BTP, décision go/no-go).
  - **Livraison de l'ATP** pour cadrer la phase août 2027 → mars 2028.

### Cadence de travail

- Charge prévue: **5 jours de travail par semaine**.
- Rythme de pilotage: continuité du suivi opérationnel pendant la période de revue et de livraison.

### Priorités de travail

- Préparer une démonstration claire pour éviter les incompréhensions pendant la revue GreenLight.
- Vérifier que les exigences BTP sont tracées avec des preuves simples à relire.
- Finaliser et rendre l'ATP dans la même fenêtre de temps.
- Aligner le backlog d'août 2027 à mars 2028 avec le contenu validé de l'ATP.

### Livrables attendus

- Compte-rendu GreenLight (go/no-go et remarques).
- ATP livré et partagé.
- Backlog ATP prêt pour démarrage immédiat en août 2027.

### Critères de validation

- Le GreenLight confirme que le BTP est correctement exécuté.
- L'ATP est rendu à temps et exploitable par l'équipe.
- La transition vers la phase ATP est fluide, sans zone grise sur les priorités.

---

## 4. Exécution de l'ATP (août 2027 → mars 2028)

### Objectif de l'étape

Transformer le MVP en version alpha solide et testable à plus grande échelle, puis présenter le tout au jury final de mars 2028.

### Période et jalon

- Période: **août 2027 à mars 2028**.
- Jalon: **jury final en mars 2028**.

### Cadence de travail

- Charge prévue: **2 jours de travail par semaine**.
- Rythme de pilotage: passage à **1 sprint + 1 suivi par mois**.
- Capacité indicative: environ **70 jours de travail** sur la période.

### Priorités de travail

- Livrer un **mode fantôme complet** avec meilleure fidélité de comparaison et workflow de sélection des prises plus avancé:
  - Détection automatique des prises avec sélection par clic.
  - Fallback manuel si une prise n'est pas détectée.
  - Choix de mode: Custom (manuel) ou Couleur détectée (rouge, bleu, etc.).
- Développer une **IA avancée de lecture des prises** (type, difficulté, exploitation) pour enrichir les conseils.
- Construire la **dimension communautaire** (comparaison entre amis, partage, progression sociale, paramètres de confidentialité).
- Déployer la **dimension coach** (suivi, objectifs, recommandations) et le mode de grimpe assistée en temps réel avec conseils vocaux, plus contraintes de sécurité/latence/fallback.
- Mettre en place des **fondations business** complètes (abonnements, premium, règles d'éligibilité, cycle complet de paiement, instrumentation activation/rétention/conversion/churn/usage).
- Continuer les revues techniques périodiques (performance, architecture, sécurité) avec corrections documentées.

### Livrables attendus

- Version alpha cohérente: analyse, progression, social, coaching, monétisation.
- Dossier ATP prêt pour le jury avec mesures de qualité et d'usage.
- Dossier technique EIP consolidé avec choix technos justifiés et résultats reproductibles.

### Critères de validation

- Le jury ATP peut valider une version stable, compréhensible et utile.
- Les métriques produit et techniques sont exploitables pour la suite.
- Les fonctions majeures ATP sont livrées avec un niveau de qualité acceptable.

---

## 5. Après l'EIP (à partir de mars 2028)

### Date de départ

- Démarrage: **après le jury ATP de mars 2028**.

### Décisions structurantes

- Décider collectivement de la suite: création d'entreprise, poursuite en side-project structuré, ou arrêt du projet.
- Évaluer les coûts d'exploitation réels et le potentiel de marché avant engagement long terme.

### Axes d'évolution possibles

- Finaliser les chantiers non terminés pendant l'EIP.
- Renforcer la fiabilité en production (observabilité, scalabilité, SLO, sécurité).
- Étendre le périmètre fonctionnel (coaching avancé, analytics, intégrations partenaires).

### Recommandation de clôture EIP

- Organiser une revue finale: bilan technique, bilan produit, bilan business.
- Décider sur la base d'indicateurs concrets (adoption, rétention, coût, stabilité, valeur perçue).
