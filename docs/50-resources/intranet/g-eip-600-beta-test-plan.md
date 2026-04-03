<!-- markdownlint-disable MD041 -->

> **Last updated:** 3rd April 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# G-EIP-600 - Beta Test Plan Ascension

---

## Table of Contents

- [G-EIP-600 - Beta Test Plan Ascension](#g-eip-600---beta-test-plan-ascension)
  - [Table of Contents](#table-of-contents)
  - [1. Contexte, objectifs et fonctionnement du projet](#1-contexte-objectifs-et-fonctionnement-du-projet)
  - [2. User roles](#2-user-roles)
  - [3. Feature table (organisee par user flow)](#3-feature-table-organisee-par-user-flow)
  - [4. Success criteria table](#4-success-criteria-table)
  - [5. Hors perimetre beta](#5-hors-perimetre-beta)
  - [6. Conclusion](#6-conclusion)

---

## 1. Contexte, objectifs et fonctionnement du projet

Ascension est un projet EIP technique qui transforme un smartphone en coach d'escalade avec une analyse biomecanique par IA.

La beta vise une demonstration Greenlight claire, stable et utile. Le scope ci-dessous contient uniquement les fonctionnalites qui seront montrees et testees pendant la soutenance.

Le fonctionnement general est le suivant:

- L'utilisateur mobile se connecte et prepare son profil.
- Il envoie une video d'escalade.
- Le backend cree une demande d'analyse.
- Le worker IA traite la video de facon asynchrone.
- Le mobile recupere le resultat, la reconstruction 3D et le mode fantome MVP.

Architecture utilisee dans la beta:

- Mobile: Flutter.
- API: serveur Ascension (Rust Axum en transition vers Go).
- IA: workers Python (MediaPipe + pipeline SAM3D).
- Messaging: RabbitMQ.
- Stockage: MinIO compatible S3.

Alignement EIP technique (objectifs complementaires retenus):

- Collaborer avec des experts techniques externes et tracer les decisions.
- Mesurer, tester et optimiser la performance avec des KPI concrets.

---

## 2. User roles

Les roles suivants sont utilises dans les tests beta.

| Role name | Description |
| :-- | :-- |
| Grimpeur beta | Utilisateur principal de l'application mobile. Il s'inscrit, envoie une video, lance l'analyse et lit le resultat. |
| Admin technique Ascension | Membre de l'equipe qui pilote les tests, suit les KPI techniques, et gere les actions d'optimisation. |
| Expert technique externe | Intervenant externe (ingenieur/CTO/contributeur) qui relit un point technique cible et valide des pistes d'amelioration. |

---

## 3. Feature table (organisee par user flow)

Toutes les fonctionnalites ci-dessous seront montrees pendant la presentation beta.

| Feature ID | User role | Feature name | Short description |
| :-- | :-- | :-- | :-- |
| F1 | Grimpeur beta | Creer un compte | Un utilisateur peut creer un compte avec email et mot de passe. |
| F2 | Grimpeur beta | Se connecter | Un utilisateur peut ouvrir une session avec ses identifiants. |
| F3 | Grimpeur beta | Configurer son profil morphologique | L'utilisateur peut renseigner taille, poids, longueur des bras et etat des membres. |
| F4 | Grimpeur beta | Reprendre son parametrage plus tard | L'utilisateur peut passer une etape de profil puis la terminer ensuite depuis la page profil. |
| F5 | Grimpeur beta | Relire les tutoriels | L'utilisateur peut revoir l'onboarding depuis les parametres. |
| F6 | Grimpeur beta | Importer une video d'escalade | L'utilisateur envoie une video via un flux d'upload stable. |
| F7 | Grimpeur beta | Lancer une analyse IA | L'utilisateur declenche une analyse asynchrone de sa video. |
| F8 | Grimpeur beta | Suivre la progression d'analyse | L'utilisateur voit le statut et la progression de 0 a 100. |
| F9 | Grimpeur beta | Consulter le resultat biomecanique | L'utilisateur lit les points clefs de posture et les conseils generes. |
| F10 | Grimpeur beta | Explorer la reconstruction 3D | L'utilisateur manipule la scene 3D (rotation, zoom, deplacement). |
| F11 | Grimpeur beta | Selectionner les prises en mode custom | L'utilisateur entoure manuellement les prises utiles avant le mode fantome. |
| F12 | Grimpeur beta | Generer un mode fantome MVP | L'application calcule un chemin de mouvement de reference et l'affiche. |
| F13 | Grimpeur beta | Comparer son mouvement au fantome | L'utilisateur visualise les ecarts entre sa montee et la trajectoire de reference. |
| F14 | Admin technique Ascension | Mesurer les KPI techniques | L'equipe suit latence, temps d'analyse, taux de succes et stabilite pendant la campagne beta. |
| F15 | Admin technique Ascension + Expert technique externe | Enregistrer une revue expert et une action | L'equipe documente un retour expert externe et lie une action technique concrete. |

---

## 4. Success criteria table

Campagne de test reference: 24th March 2026 -> 1st April 2026.

| Feature ID | Key success criteria | Indicator/metric | Result achieved |
| :-- | :-- | :-- | :-- |
| F1 | Un nouvel utilisateur peut creer son compte sans erreur bloquante. | 25 essais, 0 erreur bloquante. | Achieved (25/25). |
| F2 | Un utilisateur peut se connecter et garder une session valide. | 30 connexions, 0 deconnexion inattendue en 30 min. | Achieved (30/30). |
| F3 | Le profil morphologique est complet et sauvegarde correctement les valeurs. | 20 profils completes, 19 sauvegardes conformes. | Partially achieved (19/20). |
| F4 | Le parcours "passer maintenant / finir plus tard" fonctionne sans perte de donnees. | 15 reprises de parcours, 15 reprises reussies. | Achieved (15/15). |
| F5 | Les tutoriels peuvent etre relances depuis les parametres. | 20 ouvertures, 20 affichages complets. | Achieved (20/20). |
| F6 | Une video peut etre importee et reste disponible pour l'analyse. | 20 uploads, 19 succes complets, 1 echec reseau recupere au 2e essai. | Partially achieved (19/20 au 1er essai). |
| F7 | Une demande d'analyse cree bien un job en file et un identifiant de suivi. | 20 lancements, 20 jobs crees. | Achieved (20/20). |
| F8 | Le statut d'analyse est visible jusqu'a 100% ou echec explicite. | 20 analyses suivies, 20 statuts coherents. | Achieved (20/20). |
| F9 | Le resultat final affiche un resume biomecanique lisible avec conseils. | 18 analyses terminees, 18 resultats affiches sans crash. | Achieved (18/18). |
| F10 | La scene 3D reste fluide et manipulable sur les mobiles cibles. | 2 appareils cibles, FPS median >= 30, 0 crash. | Achieved (FPS median 33). |
| F11 | Le mode custom permet de selectionner manuellement les prises utiles. | 15 essais, 14 selections completes sans correction manuelle supplementaire. | Partially achieved (14/15). |
| F12 | Le mode fantome MVP se genere et s'affiche pour un parcours complet. | 12 essais, 10 generations completes en moins de 8 s. | Partially achieved (10/12). |
| F13 | La vue de comparaison met en evidence les ecarts de mouvement. | 12 comparaisons, 11 affichages lisibles et exploitables. | Partially achieved (11/12). |
| F14 | Les KPI techniques clefs sont mesures a chaque run beta. | 100% des runs traces, p95 API < 250 ms, p95 analyse < 60 s. | Achieved (API p95 182 ms, analyse p95 57 s). |
| F15 | Chaque revue expert externe produit une decision actionnable tracee. | 2 revues externes, 2 comptes rendus, 4 actions planifiees, 3 actions appliquees. | Achieved (2/2 revues, 3/4 actions deja executees). |

---

## 5. Hors perimetre beta

Pour rester conforme a l'attendu G-EIP-600, les points ci-dessous ne sont pas inclus dans la demo beta Greenlight:

- Dimension communautaire complete (partage social avance, classement, comparaison entre amis).
- Mode de grimpe assistee AR en temps reel avec conseils vocaux en direct.
- Detection automatique avancee des prises (version BTP complete).
- Parcours business complet d'abonnement (upgrade/downgrade/paiement echec complet).

Ces sujets sont planifies pour les phases suivantes du roadmap (BTP et post-EIP).

---

## 6. Conclusion

Ce beta test plan couvre un parcours utilisateur complet et testable, du compte utilisateur jusqu'a l'analyse IA et la comparaison en mode fantome.

Il inclut aussi les deux objectifs complementaires du track technique EIP:

- collaboration avec des experts externes,
- boucle continue mesurer -> tester -> optimiser.

Le scope est volontairement limite et demonstrable, afin de garantir une presentation Greenlight claire, verifiable et credible.
