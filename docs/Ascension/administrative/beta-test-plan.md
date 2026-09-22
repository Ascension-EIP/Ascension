---
id: 399207b7-e3a6-4697-97d9-382552ba3060
---

:::success
**Version:** 1.2
:::

---

# Ascension Beta Test Plan (BTP)

---

## 1\. Contexte du projet, objectifs et flux de travail

Ascension est une application mobile qui aide les grimpeurs à progresser grâce à une analyse biomécanique assistée par IA.

Ce BTP définit le périmètre exact de la beta présentée au GreenLight. Le scope est volontairement centré sur les fonctionnalités qui peuvent être montrées de bout en bout, de manière stable et compréhensible.

Objectifs de cette beta :

- démontrer un parcours utilisateur complet et accessible,
- démontrer la valeur du produit sur un cas réel (analyse 2D, fantôme MVP, routines de base, communauté),
- mesurer la maturité technique avec des critères simples et vérifiables (qualité, performance, accessibilité).

Flux utilisateur de référence dans la beta :

1. Se connecter, découvrir les tutoriels et configurer son profil morphologique.
2. Envoyer une vidéo de grimpe ou prendre une photo de voie.
3. Lancer l’analyse IA 2D.
4. Suivre la progression jusqu'au résultat final.
5. Consulter les résultats biomécaniques, le score global et les conseils techniques.
6. Sélectionner les prises en mode custom et utiliser le mode fantôme MVP (comparaison vidéo ou trajectoire sur photo).
7. Définir ses objectifs et générer des routines d'entraînement personnalisées.
8. Partager une séance et comparer ses performances avec ses amis.

---

## 2\. Rôles utilisateurs

| Nom du rôle               | Description                                                                                                       |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Grimpeur beta             | Utilisateur principal mobile. Il suit le parcours complet d’analyse, de fantôme, de coaching et d'échange social. |
| Ami / membre communauté   | Utilisateur qui interagit avec le grimpeur via la comparaison de performances et le partage d'analyses.           |
| Admin technique Ascension | Suit la stabilité de la campagne beta, surveille KPI, accessibilité et incidents, valide la qualité globale.      |
| Reviewer GreenLight       | Vérifie la cohérence entre scope promis, démonstration réelle et résultats observés.                              |

---

## 3\. Tableau des fonctionnalités (organisé par parcours utilisateur)

Toutes les fonctionnalités listées ci-dessous sont démontrées pendant la soutenance GreenLight.

| ID Fonctionnalité | Rôle utilisateur          | Nom de la fonctionnalité                           | Brève description                                                                                             |
| ----------------- | ------------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| BTP-F01           | Grimpeur beta             | Se connecter                                       | Ouvrir une session utilisateur valide dans l’application.                                                     |
| BTP-F02           | Grimpeur beta             | Modifier son profil morphologique                  | Enregistrer et mettre à jour taille, poids, segments et contraintes corporelles.                              |
| BTP-F03           | Grimpeur beta             | Reprendre un paramétrage plus tard                 | Passer une étape de profil puis la terminer ensuite depuis la page profil sans perte de données.              |
| BTP-F04           | Grimpeur beta             | Voir ou rejouer les tutoriels                      | Suivre l'onboarding au premier lancement et relancer les tutoriels depuis les paramètres.                     |
| BTP-F05           | Grimpeur beta             | Importer ou filmer une vidéo de grimpe             | Envoyer une vidéo dans un flux stable pour analyse asynchrone.                                                |
| BTP-F06           | Grimpeur beta             | Lancer une analyse IA 2D                           | Créer une demande d’analyse asynchrone (MediaPipe Pose, format standardisé).                                  |
| BTP-F07           | Grimpeur beta             | Suivre l’avancement d’analyse                      | Afficher statut et progression jusqu’au résultat final.                                                       |
| BTP-F08           | Grimpeur beta             | Consulter le résultat biomécanique et les conseils | Voir une restitution lisible avec posture 2D, points clés et recommandations personnalisées.                  |
| BTP-F09           | Grimpeur beta             | Consulter le score global et la progression        | Suivre son score par session et visualiser l'évolution de ses performances dans l'historique.                 |
| BTP-F10           | Grimpeur beta             | Sélectionner les prises en mode custom             | Définir manuellement les prises à utiliser sur photo avant génération du fantôme.                             |
| BTP-F11           | Grimpeur beta             | Générer un mode fantôme MVP                        | Calculer une trajectoire de référence exploitable à partir des prises custom.                                 |
| BTP-F12           | Grimpeur beta             | Comparer son mouvement au fantôme                  | Visualiser les écarts majeurs entre montée réelle et trajectoire cible.                                       |
| BTP-F13           | Grimpeur beta             | Générer un mode fantôme via photo                  | Produire une bêta de référence sans grimpe à partir d’une photo de la voie et du profil.                      |
| BTP-F14           | Grimpeur beta             | Définir des objectifs et générer des routines      | Configurer son niveau cible, recevoir des séances types adaptées et consigner ses entraînements.              |
| BTP-F15           | Grimpeur beta + Ami       | Partager une analyse et comparer les performances  | Publier une montée avec gestion de la visibilité (privé, amis, public) et comparer ses résultats entre amis.  |
| BTP-F16           | Grimpeur beta             | Naviguer avec les critères d'accessibilité mobile  | Utiliser l'application avec contrastes conformes, police dynamique et lecteur d'écran (TalkBack / VoiceOver). |
| BTP-F17           | Admin technique Ascension | Suivre les KPI techniques et l'accessibilité       | Mesurer temps d’analyse, latence API, stabilité, taux de réussite et score d'accessibilité WCAG 2.2 AA.       |
| BTP-F18           | Admin technique Ascension | Tracer un benchmark ou une revue expert            | Enregistrer une preuve technique exploitable liée à une décision d'architecture.                              |

---

## 4\. Tableau des critères de succès

Période de référence de validation beta : septembre 2026 -> juillet 2027.

| ID Fonctionnalité | Critères clés de succès                                                     | Indicateur / métrique                                                                  | Résultat obtenu      |
| ----------------- | --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | -------------------- |
| BTP-F01           | L’utilisateur se connecte sans erreur bloquante.                            | 30 essais, 0 blocage critique.                                                         | Achieved (30/30).    |
| BTP-F02           | Le profil morphologique est sauvegardé et relu correctement.                | 20 modifications, 20 persistées.                                                       | Not achieved (0/20). |
| BTP-F03           | Le parcours "passer puis reprendre" conserve les données.                   | 20 reprises, 0 anomalie.                                                               | Not achieved (0/20). |
| BTP-F04           | L'onboarding et les tutoriels sont fonctionnels et rejouables.              | 20 ouvertures, 20 réussies.                                                            | Not achieved (0/20). |
| BTP-F05           | L’import vidéo fonctionne sur les formats ciblés.                           | 30 uploads, >= 90% réussis au 1er essai.                                               | Not achieved (0/30). |
| BTP-F06           | Chaque lancement crée une analyse 2D traçable.                              | 30 lancements, 30 analyses créées.                                                     | Not achieved (0/30). |
| BTP-F07           | La progression est visible jusqu’à terminaison claire.                      | 30 suivis, 30 statuts cohérents.                                                       | Not achieved (0/30). |
| BTP-F08           | Le résultat biomécanique et les conseils sont lisibles et actionnables.     | 30 analyses complètes, 30 restitutions valides.                                        | Not achieved (0/30). |
| BTP-F09           | Le score global et l'historique reflètent l'activité de l'utilisateur.      | 20 consultations, 20 scores cohérents.                                                 | Not achieved (0/20). |
| BTP-F10           | La sélection custom des prises est exploitable sans confusion.              | 20 essais, 20 parcours complets sans blocage.                                          | Not achieved (0/20). |
| BTP-F11           | Le fantôme MVP se génère dans un temps acceptable.                          | 20 générations, temps <= 30 s.                                                         | Not achieved (0/20). |
| BTP-F12           | La comparaison fantôme met en évidence des écarts actionnables.             | 20 comparaisons, >= 80% jugées lisibles par testeurs.                                  | Not achieved (0/20). |
| BTP-F13           | Le mode fantôme via photo se génère avec une bêta lisible.                  | 20 générations photo, >= 80% bêta validée.                                             | Not achieved (0/20). |
| BTP-F14           | La configuration d'objectifs et la génération de routines sont pertinentes. | 20 configurations, 20 routines générées et loguées.                                    | Not achieved (0/20). |
| BTP-F15           | Le partage et la comparaison d'amis respectent la confidentialité.          | 20 partages / comparaisons, 0 anomalie de visibilité.                                  | Not achieved (0/20). |
| BTP-F16           | L'application respecte les standards d'accessibilité mobile critiques.      | Audit WCAG 2.2 AA >= 80% conformité, 0 blocage lecteur d'écran.                        | Not achieved (0/1).  |
| BTP-F17           | Les KPI critiques et l'accessibilité sont suivis de manière continue.       | 100% des runs tracés, API p95 < 250 ms, analyse p95 < 60 s, score accessibilité tracé. | Not achieved.        |
| BTP-F18           | Les preuves techniques sont reliées à des actions concrètes.                | >= 2 benchmarks/revues, >= 1 action corrective par preuve.                             | Not achieved (0/2).  |

---

## 5\. Hors périmètre beta

Pour garantir un scope beta réaliste et parfaitement maîtrisé lors du GreenLight, les éléments suivants sont formellement exclus de cette étape et reportés à l'ATP :

- **Reconstruction de pose via modèle 3D et expérience 3D mobile interactive** : l'analyse beta repose sur l'extraction 2D fiabilisée ; la 3D complète est ciblée pour l'ATP.
- **Détection automatique et qualification IA avancée des prises** : la beta utilise la sélection manuelle en mode custom ; la reconnaissance automatique est ciblée pour l'ATP.
- **Grimpe assistée en temps réel (AR + audio)** : nécessite un pipeline temps réel basse latence réservé à la phase ATP.
- **Cycle business complet et monétisation** : abonnements payants, gestion du churn et passerelles bancaires sont intégrés en ATP.
