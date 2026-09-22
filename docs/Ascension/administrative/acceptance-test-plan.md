---
id: 5a77e108-21d3-4916-8298-d97e6ac230f9
---

:::success
**Version:** 1.1
:::

---

# Ascension Acceptance Test Plan (ATP)

---

## 1\. Contexte du projet, objectifs et flux de travail

Ce document décrit le périmètre ATP d’Ascension, c’est-à-dire la phase qui suit le GreenLight et qui mène au jury final de mars 2028.

L’objectif de cette phase est de transformer un MVP crédible en version alpha solide, testable à plus grande échelle, intégrant l'analyse de pose 3D, l'expérience 3D mobile, la qualification automatique des prises, le coaching enrichi, la communauté avancée, l'assistance vocale temps réel et la monétisation.

Objectifs ATP :

- finaliser les fonctionnalités avancées prévues après le GreenLight,
- vérifier leur maturité sur des scénarios réels,
- présenter au jury ATP une version cohérente, stable, accessible et mesurable.

Flux utilisateur de référence dans l’alpha :

1. Préparer la voie (détection automatique des prises, qualification et correction manuelle).
2. Générer une bêta optimale sans grimpe sur photo ou analyser une vidéo avec reconstruction de posture 3D.
3. Manipuler la restitution dans une scène 3D mobile interactive.
4. Comparer sa montée réelle au fantôme complet avec retour biomécanique enrichi.
5. Recevoir des conseils contextualisés et suivre un programme d'entraînement adaptatif.
6. Interagir avec la communauté (partage d'analyses, progression sociale, paramétrage de confidentialité).
7. Utiliser le mode de grimpe assistée en temps réel avec guidage vocal.
8. Gérer son abonnement de bout en bout (Freemium, Premium, Infinity).

---

## 2\. Rôles utilisateurs

| Nom du rôle               | Description                                                                                             |
| ------------------------- | ------------------------------------------------------------------------------------------------------- |
| Grimpeur alpha            | Utilisateur principal avec accès au parcours avancé (analyse 3D, scène 3D, fantôme complet, coaching).  |
| Ami / membre communauté   | Utilisateur qui interagit via comparaison, partage et progression sociale.                              |
| Admin produit & technique | Suit la qualité, la sécurité, la performance, l'accessibilité et valide l’état de préparation jury ATP. |

---

## 3\. Tableau des fonctionnalités (organisé par parcours utilisateur)

Toutes les fonctionnalités listées ci-dessous font partie du scope ATP à démontrer.

| ID Fonctionnalité | Rôle utilisateur          | Nom de la fonctionnalité                              | Brève description                                                                                            |
| ----------------- | ------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| ATP-F01           | Grimpeur alpha            | Se connecter                                          | Accéder au compte et aux données avancées du profil.                                                         |
| ATP-F02           | Grimpeur alpha            | Détecter automatiquement les prises                   | Identifier les prises sur photo de voie avec segmentation et qualification.                                  |
| ATP-F03           | Grimpeur alpha            | Corriger manuellement les prises                      | Ajuster, ajouter ou supprimer des prises non détectées ou mal classées.                                      |
| ATP-F04           | Grimpeur alpha            | Choisir un mode de sélection des prises               | Basculer entre mode custom (manuel) et mode couleur détectée.                                                |
| ATP-F05           | Grimpeur alpha            | Générer une bêta sans grimpe                          | Produire une trajectoire optimale à partir de la voie qualifiée et du profil utilisateur.                    |
| ATP-F06           | Grimpeur alpha            | Extraire la posture via modèle 3D                     | Reconstruire la pose en 3D et générer les sorties biomécaniques standardisées.                               |
| ATP-F07           | Grimpeur alpha            | Manipuler la scène 3D mobile                          | Explorer interactivement la grimpe en 3D (rotation, zoom, déplacement fluide).                               |
| ATP-F08           | Grimpeur alpha            | Comparer sa montée au fantôme complet                 | Visualiser les écarts biomécaniques clés, moments critiques et recommandations associées.                    |
| ATP-F09           | Grimpeur alpha            | Recevoir des conseils enrichis                        | Obtenir un feedback technique contextualisé par IA croisant prises et biomécanique.                          |
| ATP-F10           | Grimpeur alpha            | Définir des objectifs de progression avancés          | Configurer niveau actuel, cible, calendrier et contraintes pour un coaching adaptatif.                       |
| ATP-F11           | Grimpeur alpha            | Générer et consigner des entraînements                | Recevoir des programmes sur mesure et enregistrer les séances pour suivi longitudinal.                       |
| ATP-F12           | Grimpeur alpha + Ami      | Partager une analyse et suivre la progression sociale | Publier une montée avec gestion fine de visibilité et suivre sa dynamique collective.                        |
| ATP-F13           | Grimpeur alpha + Ami      | Comparer les performances entre amis                  | Comparer les métriques et indicateurs clés au sein de la communauté.                                         |
| ATP-F14           | Grimpeur alpha            | Lancer le mode de grimpe assistée                     | Activer l’assistance en direct avec guidage vocal pendant l'effort.                                          |
| ATP-F15           | Grimpeur alpha            | Gérer l’abonnement de bout en bout                    | Souscrire, renouveler, changer d’offre (Freemium/Premium/Infinity), annuler et gérer les échecs de paiement. |
| ATP-F16           | Grimpeur alpha            | Bénéficier d'une accessibilité universelle            | Utiliser l'ensemble des modules alpha avec conformité WCAG 2.2 AA / RGAA vérifiée.                           |
| ATP-F17           | Admin produit & technique | Mesurer les KPI produit, business et qualité          | Suivre activation, rétention, conversion, churn, latence système et SLOs.                                    |

---

## 4\. Tableau des critères de succès

Période de validation ATP : août 2027 -> mars 2028.

| ID Fonctionnalité | Critères clés de succès                                                 | Indicateur / métrique                                                 | Résultat obtenu      |
| ----------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------------- | -------------------- |
| ATP-F01           | La connexion donne accès au parcours alpha sans rupture.                | 40 essais, 0 blocage critique.                                        | Achieved (40/40).    |
| ATP-F02           | La détection automatique propose une base exploitable.                  | 30 photos, précision macro >= 80%.                                    | Not achieved (0/30). |
| ATP-F03           | La correction manuelle permet de finaliser la voie rapidement.          | 30 corrections, temps médian <= 90 s.                                 | Not achieved (0/30). |
| ATP-F04           | Le choix de mode (custom/couleur) est clair et fiable.                  | 30 bascules, 0 perte de sélection.                                    | Not achieved (0/30). |
| ATP-F05           | La bêta sans grimpe se génère et reste lisible.                         | 25 générations, p95 < 12 s.                                           | Not achieved (0/25). |
| ATP-F06           | La reconstruction de pose 3D est stable et cohérente.                   | 30 vidéos, 0 artefact aberrant, format standardisé validé.            | Not achieved (0/30). |
| ATP-F07           | La scène 3D mobile est fluide et réactive.                              | FPS médian >= 30, 0 crash sur smartphones de référence.               | Not achieved (0/2).  |
| ATP-F08           | La comparaison fantôme complète produit des écarts actionnables.        | 25 comparaisons, >= 85% jugées utiles par testeurs.                   | Not achieved (0/25). |
| ATP-F09           | Les conseils enrichis sont cohérents avec le contexte de voie.          | 25 analyses, >= 90% retours validés par revue interne.                | Not achieved (0/25). |
| ATP-F10           | L’utilisateur peut paramétrer des objectifs de coaching sans confusion. | 30 parcours, >= 90% complétés sans aide externe.                      | Not achieved (0/30). |
| ATP-F11           | Les séances générées sont exploitables et alimentent le suivi.          | 50 logs, 100% visibles dans l’historique.                             | Not achieved (0/50). |
| ATP-F12           | Le partage respecte le format et les droits choisis.                    | 30 partages, 0 fuite de confidentialité.                              | Not achieved (0/30). |
| ATP-F13           | La comparaison entre amis est lisible et actualisée en direct.          | 20 comparaisons, actualisation < 5 s.                                 | Not achieved (0/20). |
| ATP-F14           | Le mode assisté reste utile et sûr pendant l’effort.                    | 20 sessions, latence vocale p95 < 1.5 s, pertes de tracking gérées.   | Not achieved (0/20). |
| ATP-F15           | Le cycle abonnement complet fonctionne sur tous les cas critiques.      | 30 parcours (souscription/changement/annulation), >= 90% sans accroc. | Not achieved (0/30). |
| ATP-F16           | L'application globale satisfait aux exigences WCAG 2.2 AA.              | Audit de conformité complet, taux global >= 90%, 0 bloquant.          | Not achieved (0/1).  |
| ATP-F17           | Les KPI business, produit et techniques sont instrumentés et suivis.    | 100% des événements clés tracés, dashboard jury à jour.               | Not achieved.        |

---

## 5\. Hors périmètre EIP

Pour garder un ATP réaliste, les points ci-dessous restent hors scope du jury final :

- expansion multi-pays avec adaptation réglementaire complète,
- catalogue partenaires salles à grande échelle,
- optimisation extrême de coût pour très forte volumétrie.

Ces sujets relèvent de la phase post-EIP et de la stratégie de lancement long terme.
