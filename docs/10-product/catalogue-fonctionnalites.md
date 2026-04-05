> **Last updated:** 6th April 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO, GitHub Copilot  
> **Status:** Done  
> {.is-success}

---

# Catalogue complet des fonctionnalites Ascension

---

## Table of Contents

- [Catalogue complet des fonctionnalites Ascension](#catalogue-complet-des-fonctionnalites-ascension)
  - [Table of Contents](#table-of-contents)
  - [Objectif du document](#objectif-du-document)
  - [Vue d'ensemble des fonctionnalites](#vue-densemble-des-fonctionnalites)
  - [Parcours global simplifie (version debutant)](#parcours-global-simplifie-version-debutant)
  - [Detail de chaque fonctionnalite](#detail-de-chaque-fonctionnalite)
    - [F01 - Profil morphologique et contexte utilisateur](#f01---profil-morphologique-et-contexte-utilisateur)
    - [F02 - Analyse de grimpe (video -\> feedback)](#f02---analyse-de-grimpe-video---feedback)
    - [F03 - Extraction de squelette et biomecanique](#f03---extraction-de-squelette-et-biomecanique)
    - [F04 - Score global et indicateurs de progression](#f04---score-global-et-indicateurs-de-progression)
    - [F05 - Mode Fantome en comparaison](#f05---mode-fantome-en-comparaison)
    - [F06 - Analyse des prises (detection, qualification, correction)](#f06---analyse-des-prises-detection-qualification-correction)
    - [F07 - Mode Fantome sans grimpe](#f07---mode-fantome-sans-grimpe)
    - [F08 - Experience 3D mobile](#f08---experience-3d-mobile)
    - [F09 - Conseils techniques personnalises (IA externe)](#f09---conseils-techniques-personnalises-ia-externe)
    - [F10 - Coach perso et programmes d'entrainement](#f10---coach-perso-et-programmes-dentrainement)
    - [F11 - Dimension communautaire et partage](#f11---dimension-communautaire-et-partage)
    - [F12 - Grimpe assistee (AR + audio)](#f12---grimpe-assistee-ar--audio)
    - [F13 - Abonnements, quotas et montee en gamme](#f13---abonnements-quotas-et-montee-en-gamme)
    - [F14 - Onboarding et tutoriels rejouables](#f14---onboarding-et-tutoriels-rejouables)
    - [F15 - Accessibilite numerique (transverse)](#f15---accessibilite-numerique-transverse)
    - [F16 - Fiabilite plateforme (pipeline, CI/CD, observabilite)](#f16---fiabilite-plateforme-pipeline-cicd-observabilite)
  - [Synthese par phase roadmap](#synthese-par-phase-roadmap)
    - [Avant septembre 2026 (livraison Action Plan + BTP)](#avant-septembre-2026-livraison-action-plan--btp)
    - [Execution BTP (septembre 2026 -\> juillet 2027)](#execution-btp-septembre-2026---juillet-2027)
    - [Passage GreenLight + livraison ATP (juillet 2027)](#passage-greenlight--livraison-atp-juillet-2027)
    - [Execution ATP (aout 2027 -\> mars 2028)](#execution-atp-aout-2027---mars-2028)
  - [Points qui font la valeur unique d'Ascension](#points-qui-font-la-valeur-unique-dascension)

---

## Objectif du document

Ce document liste et explique toutes les fonctionnalites du projet Ascension de facon claire, simple et detaillee.

Le but est de donner une vision unique et lisible pour:
- l'equipe produit,
- l'equipe technique,
- les personnes qui decouvrent le projet,
- le jury et les partenaires.

Ce document distingue aussi ce qui est:
- deja cadre pour un MVP demonstrable,
- cible pour la phase BTP,
- cible pour la phase ATP.

---

## Vue d'ensemble des fonctionnalites

| Code | Fonctionnalite | Probleme resolu | Phase cible principale |
|---|---|---|---|
| F01 | Analyse de grimpe (video -> feedback) | Le grimpeur ne voit pas ses erreurs en direct | MVP / BTP |
| F02 | Profil morphologique | Le feedback n'est pas adapte au corps de l'utilisateur | BTP |
| F03 | Extraction de squelette et biomecanique | Manque de mesures objectives sur le mouvement | MVP / BTP |
| F04 | Score global et progression | Difficulte a suivre ses progres dans le temps | BTP |
| F05 | Mode Fantome | Difficulte a visualiser une beta optimale | BTP -> ATP |
| F06 | Analyse des prises | Difficulte a lire une voie de maniere fiable | ATP |
| F07 | Experience 3D mobile | Les resultats techniques restent abstraits | BTP |
| F08 | Conseils techniques personnalises | Les retours sont trop generiques | BTP |
| F09 | Coach perso / routines | Manque de plan de progression concret | ATP |
| F10 | Communaute et partage | Progression isolee, faible motivation sociale | ATP |
| F11 | Grimpe assistee (AR + audio) | Besoin d'aide pendant la montee | ATP |
| F12 | Abonnements et quotas | Besoin d'un modele economique durable | MVP -> ATP |
| F13 | Onboarding et tutoriels | L'utilisateur debutant ne comprend pas vite l'app | BTP |
| F14 | Accessibilite numerique | L'app devient inutilisable pour certains profils | MVP -> ATP |
| F15 | Fiabilite plateforme (CI/CD, pipeline) | Experience instable, retards, incidents | Action Plan -> BTP -> ATP |

---

## Parcours global simplifie (version debutant)

1. L'utilisateur cree son compte et complete son profil (niveau, morphologie, contraintes).
2. Il filme sa grimpe ou importe une video.
3. L'app envoie la video pour une analyse IA asynchrone.
4. Le systeme extrait les points du corps, calcule des indicateurs et genere un retour.
5. L'utilisateur lit son score global et ses conseils techniques.
6. Il peut comparer sa grimpe a un fantome (trajectoire ideale), puis corriger sa trajectoire.
7. Il peut aussi prendre en photo la voie pour detecter les prises, chosir les prises à utiliser et obtenir la beta (trajectoire optimale).
8. Dans les phases avancees, il recoit des routines, partage ses progres, et accede au coaching assiste.

---

## Detail de chaque fonctionnalite

### F01 - Profil morphologique et contexte utilisateur

**But de la fonctionnalite**
- Adapter les analyses a la morphologie reelle de chaque grimpeur.

**Ce que l'utilisateur voit**
- Un profil editable avec taille, poids, longueur de bras, niveau.
- Un schema corporel interactif pour declarer des membres absents ou blesses.

**Parcours utilisateur simple**
1. A l'inscription, l'utilisateur complete ses infos corporelles.
2. S'il manque du temps, il peut passer et revenir plus tard depuis le profil.
3. Il met a jour ses infos quand sa condition evolue.

**Ce que le systeme fait en coulisse**
- Stockage des parametres morphologiques.
- Prise en compte de ces parametres pour l'analyse, le fantome, les conseils, et les routines.

**Valeur pour l'utilisateur**
- Les conseils sont realistes et personnalises, pas generiques.

**Niveau de maturite dans la roadmap**
- Cible BTP.

---

### F02 - Analyse de grimpe (video -> feedback)

**But de la fonctionnalite**
- Donner un feedback technique objectif a partir d'une simple video de grimpe.

**Ce que l'utilisateur voit**
- Un ecran d'upload simple ou de capture vidéo.
- Un choix entre analyse 2D basique ou experience 3D avancee.
- Un statut d'analyse (en attente, en cours, terminee, echec).
- Un resultat lisible avec points clefs et recommandations.

**Parcours utilisateur simple**
1. L'utilisateur se connecte.
2. Il demande une URL d'upload (en fond avec MinIO).
3. Il envoie sa video.
4. Il lance l'analyse.
5. Il suit la progression.
6. Il consulte le resultat final.

**Ce que le systeme fait en coulisse**
- Generation d'URL presignee pour upload direct objet.
- Creation d'un job asynchrone via broker.
- Traitement par worker IA.
- Ecriture du resultat en base.
- Notification du client (polling/API ou evenement temps reel).

**Valeur pour l'utilisateur**
- Il obtient un retour concret sans coach present.

**Niveau de maturite dans la roadmap**
- MVP demonstrable et renforce en BTP.

---

### F03 - Extraction de squelette et biomecanique

**But de la fonctionnalite**
- Convertir une video en donnees biomecaniques exploitables (directement liée à l'analyse de la grimpe).

**Ce que l'utilisateur voit**
- Un squelette superpose a sa video.
- Des informations sur sa posture et ses mouvements.

**Parcours utilisateur simple**
1. L'utilisateur charge sa video.
2. L'IA detecte les points corporels image par image.
3. L'app affiche une restitution comprehensible.

**Ce que le systeme fait en coulisse**
- Extraction de points de pose (33 landmarks via MediaPipe).
- Calcul d'angles, postures, et indicateurs derives.
- Generation d'un format de sortie standardise pour les autres modules.

**Valeur pour l'utilisateur**
- Il voit enfin des donnees objectives sur sa grimpe.

**Niveau de maturite dans la roadmap**
- Base MVP, puis reconstruction autour de SAM3D en BTP.

---

### F04 - Score global et indicateurs de progression

**But de la fonctionnalite**
- Donner une lecture rapide de la qualite de la grimpe et de son evolution.

**Ce que l'utilisateur voit**
- Un score global par session.
- Des indicateurs dans le temps (technique, puissance, endurance, etc.).

**Parcours utilisateur simple**
1. L'utilisateur ouvre son historique.
2. Il compare ses sessions recentes.
3. Il identifie si sa progression est stable, positive ou en baisse.

**Ce que le systeme fait en coulisse**
- Calcul de metriques par analyse.
- Agregation mensuelle/hebdomadaire pour les courbes de progression.

**Valeur pour l'utilisateur**
- Il sait rapidement ou il progresse et ou il stagne.

**Niveau de maturite dans la roadmap**
- Cible BTP (avec enrichissement ATP).

---

### F05 - Mode Fantome en comparaison

**But de la fonctionnalite**
- Montrer visuellement le chemin de mouvement optimal (la beta) en comparaison de la grimpe reelle.

**Ce que l'utilisateur voit**
- Une trajectoire fantome superposee a sa video.
- Des ecarts visibles entre son mouvement et le mouvement conseille.

**Parcours utilisateur simple**
1. L'utilisateur prepare une analyse de voie.
2. Le systeme calcule un trajet de reference.
3. L'utilisateur lance la comparaison sur sa video.
4. Il relit les points critiques et ajuste sa technique.

**Ce que le systeme fait en coulisse**
- Calcul de trajectoire (pathfinding/cinematique inverse selon contexte).
- Alignement temporal du fantome avec la video utilisateur.
- Restitution des deviations utiles a la pedagogie.

**Valeur pour l'utilisateur**
- Il comprend "quoi changer" concretement, pas seulement "quoi corriger".

**Niveau de maturite dans la roadmap**
- MVP fonctionnel en BTP, version complete en ATP.

---

### F06 - Analyse des prises (detection, qualification, correction)

**But de la fonctionnalite**
- Automatiser la lecture de voie tout en gardant un controle manuel si l'IA se trompe.

**Ce que l'utilisateur voit**
- Les prises detectees sur la photo du mur.
- Un mode de correction manuelle par categories.
- Un choix de mode (custom manuel ou selection par couleur detectee).

**Parcours utilisateur simple**
1. L'utilisateur prend une photo de la voie.
2. L'IA detecte les prises.
3. L'utilisateur valide/corrige les prises.
4. Le resultat alimente le mode fantome et les conseils.

**Ce que le systeme fait en coulisse**
- Detection et qualification des prises (type, difficulte, exploitation).
- Gestion d'un fallback manuel quand la detection est incomplete.
- Conservation des corrections pour ameliorer le modele (boucle d'apprentissage).

**Valeur pour l'utilisateur**
- Meilleure lecture de voie, plus fiable, et utilisable partout.

**Niveau de maturite dans la roadmap**
- Fonction avancee ATP.

---

### F07 - Mode Fantome sans grimpe

**But de la fonctionnalite**
- Montrer visuellement le chemin de mouvement optimal (la beta) à partir d'une simple photo de la voie, sans besoin de grimper ou filmer.

**Ce que l'utilisateur voit**
- L'outil de selection des prises (automatique ou manuel) pour indiquer les prises utilisables.
- Une trajectoire fantome superposee a la photo de la voie.

**Parcours utilisateur simple**
1. L'utilisateur prend une photo de la voie.
2. L'IA detecte les prises.
3. L'utilisateur séléctionne les prises.
4. Le systeme calcule et affiche la beta optimale.

**Ce que le systeme fait en coulisse**
- Detection des prises et de leur qualite.
- Calcul de trajectoire de reference en fonction des prises utilisables et du profil de l'utilisateur.
- Restitution d'une beta optimale sans besoin de grimper.

**Valeur pour l'utilisateur**
- Il peut visualiser la beta optimale avant même de grimper, ce qui l'aide à mieux préparer sa montée.

**Niveau de maturite dans la roadmap**
- MVP fonctionnel en BTP, version complete en ATP.

---

### F08 - Experience 3D mobile

**But de la fonctionnalite**
- Rendre les donnees techniques visuelles, intuitives et faciles a manipuler suite à une analyse de grimpe 3D.

**Ce que l'utilisateur voit**
- Une scene 3D manipulable au doigt (rotation, zoom, deplacement).
- Une reconstruction du mouvement lisible.

**Parcours utilisateur simple**
1. L'utilisateur ouvre une analyse 3D terminee.
2. Il active la vue 3D.
3. Il inspecte les moments cles de son mouvement.

**Ce que le systeme fait en coulisse**
- Transformation des donnees de pose en rendu 3D mobile.
- Optimisations pour garder des performances correctes sur terminaux cibles.

**Valeur pour l'utilisateur**
- Il comprend mieux les details de posture qu'en simple 2D.

**Niveau de maturite dans la roadmap**
- Cible BTP.

---

### F09 - Conseils techniques personnalises (IA externe)

**But de la fonctionnalite**
- Transformer les donnees brutes en conseils actionnables.

**Ce que l'utilisateur voit**
- Des recommandations claires: erreurs principales, priorites de correction, actions concretes.

**Parcours utilisateur simple**
1. Une analyse est terminee.
2. L'utilisateur ouvre la fiche resultat.
3. Il lit des conseils adaptes a son mouvement et au contexte de voie.

**Ce que le systeme fait en coulisse**
- Combine les sorties biomecaniques et les infos de prises.
- Appelle un modele externe de type Gemini (ou equivalent API) pour formuler le feedback.

**Valeur pour l'utilisateur**
- Il sait quelles actions faire a la prochaine session.

**Niveau de maturite dans la roadmap**
- Cible BTP (avec enrichissement ATP).

---

### F10 - Coach perso et programmes d'entrainement

**But de la fonctionnalite**
- Proposer un vrai plan de progression, pas seulement une analyse ponctuelle.

**Ce que l'utilisateur voit**
- Des objectifs (niveau actuel -> niveau cible).
- Des seances types personnalisees.
- Un suivi des sessions realisees.

**Parcours utilisateur simple**
1. L'utilisateur definit ses objectifs et son niveau.
2. Le systeme genere des seances types.
3. L'utilisateur suit et journalise ses entrainements.

**Ce que le systeme fait en coulisse**
- Croise objectifs, historique d'analyses, blessures et profil.
- Propose des routines evolutives.

**Valeur pour l'utilisateur**
- Il passe d'un diagnostic ponctuel a une progression continue.

**Niveau de maturite dans la roadmap**
- Principalement ATP.

---

### F11 - Dimension communautaire et partage

**But de la fonctionnalite**
- Renforcer la motivation et l'engagement via la communaute.

**Ce que l'utilisateur voit**
- Comparaison de performances entre amis.
- Partage de montees et d'analyses.
- Parametres de visibilite (prive, amis, public).

**Parcours utilisateur simple**
1. L'utilisateur active le partage sur certaines sessions.
2. Il compare ses resultats avec ses amis.
3. Il suit sa progression sociale.

**Ce que le systeme fait en coulisse**
- Gestion des droits de visibilite par contenu.
- Exposition des performances partageables.

**Valeur pour l'utilisateur**
- La progression devient plus motivante et sociale.

**Niveau de maturite dans la roadmap**
- ATP.

---

### F12 - Grimpe assistee (AR + audio)

**But de la fonctionnalite**
- Aider le grimpeur pendant la montee avec des conseils en temps reel.

**Ce que l'utilisateur voit**
- Un mode d'assistance active.
- Des indications vocales pendant l'effort (via ecouteurs).

**Parcours utilisateur simple**
1. L'utilisateur pose son telephone, lance le mode assiste.
2. L'IA suit la grimpe en temps reel.
3. L'utilisateur recoit des conseils vocaux adaptes.

**Ce que le systeme fait en coulisse**
- Tracking temps reel de la posture.
- Generation de messages vocaux a frequence controlee.
- Fallback si tracking perdu.

**Valeur pour l'utilisateur**
- Un coaching "pendant l'action", pas seulement apres.

**Niveau de maturite dans la roadmap**
- ATP (fonction avancee).

---

### F13 - Abonnements, quotas et montee en gamme

**But de la fonctionnalite**
- Rendre le produit economiquement durable sans bloquer l'acces de base.

**Ce que l'utilisateur voit**
- Une offre Freemium et des options Premium/Infinity.
- Un compteur d'analyses restantes.
- Un parcours complet de souscription et gestion abonnement.

**Parcours utilisateur simple**
1. L'utilisateur commence en Freemium.
2. Il atteint les limites de quota.
3. Il peut passer en Premium/Infinity selon son usage.

**Ce que le systeme fait en coulisse**
- Application des quotas et droits par niveau d'offre.
- Gestion du cycle abonnement (renouvellement, changement offre, annulation, echec paiement).
- Instrumentation business (activation, retention, conversion, churn).

**Valeur pour l'utilisateur**
- Il choisit un niveau adapte a son besoin reel.

**Niveau de maturite dans la roadmap**
- ATP.

---

### F14 - Onboarding et tutoriels rejouables

**But de la fonctionnalite**
- Aider un nouvel utilisateur a comprendre rapidement l'application.

**Ce que l'utilisateur voit**
- Un onboarding guide au premier lancement.
- Un centre d'aide/tutoriels rejouables depuis les parametres.

**Parcours utilisateur simple**
1. Premier lancement: mini parcours de prise en main.
2. Plus tard: consultation des tutos depuis les settings.

**Ce que le systeme fait en coulisse**
- Gestion de l'etat "premier lancement".
- Stockage des progressions tuto.

**Valeur pour l'utilisateur**
- Moins de friction, meilleure comprehension des fonctions avancees.

**Niveau de maturite dans la roadmap**
- BTP.

---

### F15 - Accessibilite numerique (transverse)

**But de la fonctionnalite**
- Rendre l'application utilisable par le plus grand nombre, y compris les personnes en situation de handicap.

**Ce que l'utilisateur voit**
- Interface lisible (contraste, taille texte, focus clair).
- Compatibilite VoiceOver/TalkBack.
- Alternatives textuelles des contenus visuels importants.

**Parcours utilisateur simple**
1. L'utilisateur active ses options d'accessibilite systeme.
2. L'app respecte ces options sur les ecrans critiques.
3. Les resultats restent comprehensibles sans dependre uniquement de la couleur.

**Ce que le systeme fait en coulisse**
- Respect des exigences WCAG (objectif 2.2 AA en mobile).
- Tests manuels guides + checks automatisables.
- Suivi de conformite dans les revues.

**Valeur pour l'utilisateur**
- Une app plus inclusive, plus robuste et plus facile a utiliser pour tous.

**Niveau de maturite dans la roadmap**
- Transverse: present des le MVP, renforce en BTP et ATP.

---

### F16 - Fiabilite plateforme (pipeline, CI/CD, observabilite)

**But de la fonctionnalite**
- Garantir une experience stable, securisee et maintenable.

**Ce que l'utilisateur voit**
- Moins de pannes.
- Des analyses plus fiables.
- Des temps de traitement plus previsibles.

**Parcours utilisateur simple**
- L'utilisateur ne "voit" pas directement cette fonctionnalite, mais il ressent sa qualite dans toute l'application.

**Ce que le systeme fait en coulisse**
- Pipeline CI/CD robuste (qualite, tests, build, deploiement).
- Monitoring et boucle d'optimisation continue (mesurer -> tester -> optimiser -> re-mesurer).
- Tracabilite technique (benchmarks, PoC, decisions argumentees).

**Valeur pour l'utilisateur**
- L'application reste utilisable et inspire confiance.

**Niveau de maturite dans la roadmap**
- Priorite forte des la livraison initiale Action Plan + BTP, puis continuation sur toute la roadmap.

---

## Synthese par phase roadmap

### Avant septembre 2026 (livraison Action Plan + BTP)

- Base plateforme: CI/CD robuste, architecture propre, backlog, risques, formalites.
- Cadrage fonctionnel complet pour execution.

### Execution BTP (septembre 2026 -> juillet 2027)

- Parcours utilisateur complet.
- IA de pose reconstruite autour de SAM3D.
- Experience 3D mobile.
- Mode Fantome MVP.
- Accessibilite forte.
- Conseils personnalises exploitables.

### Passage GreenLight + livraison ATP (juillet 2027)

- Validation go/no-go sur execution BTP.
- ATP livre pour cadrer la suite.

### Execution ATP (aout 2027 -> mars 2028)

- Mode Fantome complet.
- Lecture de prises avancee.
- Communaute et coach perso enrichis.
- Grimpe assistee temps reel.
- Cycle business complet et instrumentation produit.

---

## Points qui font la valeur unique d'Ascension

- **Agnostique du lieu**: fonctionne sur n'importe quel mur, sans base pre-remplie par salle.
- **Mode Fantome pedagogique**: comparaison visuelle directe entre grimpe reelle et trajectoire conseillee.
- **Approche complete**: analyse, correction, entrainement, suivi, communaute.
- **Accessibilite integree**: prise en compte de l'inclusion des la conception.
- **Architecture pragmatique**: pipeline asynchrone, rendu cote client, optimisation cout/performance.
