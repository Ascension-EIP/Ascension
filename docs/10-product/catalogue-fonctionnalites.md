> **Last updated:** 6th April 2026  
> **Version:** 1.1  
> **Authors:** Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# Catalogue complet des fonctionnalités Ascension

---

## Table of Contents

- [Catalogue complet des fonctionnalités Ascension](#catalogue-complet-des-fonctionnalités-ascension)
  - [Table of Contents](#table-of-contents)
  - [Objectif du document](#objectif-du-document)
  - [Vue d'ensemble des fonctionnalités](#vue-densemble-des-fonctionnalités)
  - [Parcours global simplifié (version débutant)](#parcours-global-simplifié-version-débutant)
  - [Détail de chaque fonctionnalité](#détail-de-chaque-fonctionnalité)
    - [F01 - Profil morphologique et contexte utilisateur](#f01---profil-morphologique-et-contexte-utilisateur)
    - [F02 - Analyse de grimpe (vidéo -\> feedback)](#f02---analyse-de-grimpe-vidéo---feedback)
    - [F03 - Extraction de squelette et biomécanique](#f03---extraction-de-squelette-et-biomécanique)
    - [F04 - Score global et indicateurs de progression](#f04---score-global-et-indicateurs-de-progression)
    - [F05 - Mode Fantôme en comparaison](#f05---mode-fantôme-en-comparaison)
    - [F06 - Analyse des prises (détection, qualification, correction)](#f06---analyse-des-prises-détection-qualification-correction)
    - [F07 - Mode Fantôme sans grimpe](#f07---mode-fantôme-sans-grimpe)
    - [F08 - Expérience 3D mobile](#f08---expérience-3d-mobile)
    - [F09 - Conseils techniques personnalisés (IA externe)](#f09---conseils-techniques-personnalisés-ia-externe)
    - [F10 - Coach perso et programmes d'entraînement](#f10---coach-perso-et-programmes-dentraînement)
    - [F11 - Dimension communautaire et partage](#f11---dimension-communautaire-et-partage)
    - [F12 - Grimpe assistée (AR + audio)](#f12---grimpe-assistée-ar--audio)
    - [F13 - Abonnements, quotas et montée en gamme](#f13---abonnements-quotas-et-montée-en-gamme)
    - [F14 - Onboarding et tutoriels rejouables](#f14---onboarding-et-tutoriels-rejouables)
    - [F15 - Accessibilité numérique (transverse)](#f15---accessibilité-numérique-transverse)
    - [F16 - Fiabilité plateforme (pipeline, CI/CD, observabilité)](#f16---fiabilité-plateforme-pipeline-cicd-observabilité)
  - [Synthèse par phase roadmap](#synthèse-par-phase-roadmap)
    - [Avant septembre 2026 (livraison Action Plan + BTP)](#avant-septembre-2026-livraison-action-plan--btp)
    - [Exécution BTP (septembre 2026 -\> juillet 2027)](#exécution-btp-septembre-2026---juillet-2027)
    - [Passage GreenLight + livraison ATP (juillet 2027)](#passage-greenlight--livraison-atp-juillet-2027)
    - [Exécution ATP (août 2027 -\> mars 2028)](#exécution-atp-août-2027---mars-2028)
  - [Points qui font la valeur unique d'Ascension](#points-qui-font-la-valeur-unique-dascension)

---

## Objectif du document

Ce document liste et explique toutes les fonctionnalités du projet Ascension de façon claire, simple et détaillée.

Le but est de donner une vision unique et lisible pour :
- l'équipe produit,
- l'équipe technique,
- les personnes qui découvrent le projet,
- le jury et les partenaires.

Ce document distingue aussi ce qui est :
- déjà cadré pour un MVP démontrable,
- ciblé pour la phase BTP,
- ciblé pour la phase ATP.

---

## Vue d'ensemble des fonctionnalités

| Code | Fonctionnalité | Problème résolu | Phase cible principale |
|---|---|---|---|
| F01 | Profil morphologique | Le feedback n'est pas adapté au corps de l'utilisateur | BTP |
| F02 | Analyse de grimpe (vidéo -> feedback) | Le grimpeur ne voit pas ses erreurs en direct | MVP / BTP |
| F03 | Extraction de squelette et biomécanique | Manque de mesures objectives sur le mouvement | MVP / BTP |
| F04 | Score global et progression | Difficulté à suivre ses progrès dans le temps | BTP |
| F05 | Mode Fantôme en comparaison | Difficulté à visualiser une bêta optimale pendant la grimpe | BTP -> ATP |
| F06 | Analyse des prises | Difficulté à lire une voie de manière fiable | ATP |
| F07 | Mode Fantôme sans grimpe | Difficulté à préparer une voie avant essai réel | BTP -> ATP |
| F08 | Expérience 3D mobile | Les résultats techniques restent abstraits | BTP |
| F09 | Conseils techniques personnalisés | Les retours sont trop génériques | BTP |
| F10 | Coach perso / routines | Manque de plan de progression concret | ATP |
| F11 | Communauté et partage | Progression isolée, faible motivation sociale | ATP |
| F12 | Grimpe assistée (AR + audio) | Besoin d'aide pendant la montée | ATP |
| F13 | Abonnements et quotas | Besoin d'un modèle économique durable | MVP -> ATP |
| F14 | Onboarding et tutoriels | L'utilisateur débutant ne comprend pas vite l'app | BTP |
| F15 | Accessibilité numérique | L'app devient inutilisable pour certains profils | MVP -> ATP |
| F16 | Fiabilité plateforme (CI/CD, pipeline) | Expérience instable, retards, incidents | Action Plan -> BTP -> ATP |

---

## Parcours global simplifié (version débutant)

1. L'utilisateur crée son compte et complète son profil (niveau, morphologie, contraintes).
2. Il filme sa grimpe ou importe une vidéo.
3. L'app envoie la vidéo pour une analyse IA asynchrone.
4. Le système extrait les points du corps, calcule des indicateurs et génère un retour.
5. L'utilisateur lit son score global et ses conseils techniques.
6. Il peut comparer sa grimpe à un fantôme (trajectoire idéale), puis corriger sa trajectoire.
7. Il peut aussi prendre en photo la voie pour détecter les prises, choisir les prises à utiliser et obtenir la bêta (trajectoire optimale).
8. Dans les phases avancées, il reçoit des routines, partage ses progrès, et accède au coaching assisté.

---

## Détail de chaque fonctionnalité

### F01 - Profil morphologique et contexte utilisateur

**But de la fonctionnalité**
- Adapter les analyses à la morphologie réelle de chaque grimpeur.

**Ce que l'utilisateur voit**
- Un profil éditable avec taille, poids, longueur de bras, niveau.
- Un schéma corporel interactif pour déclarer des membres absents ou blessés.

**Parcours utilisateur simple**
1. À l'inscription, l'utilisateur complète ses infos corporelles.
2. S'il manque de temps, il peut passer et revenir plus tard depuis le profil.
3. Il met à jour ses infos quand sa condition évolue.

**Ce que le système fait en coulisse**
- Stockage des paramètres morphologiques.
- Prise en compte de ces paramètres pour l'analyse, le fantôme, les conseils, et les routines.

**Valeur pour l'utilisateur**
- Les conseils sont réalistes et personnalisés, pas génériques.

**Niveau de maturité dans la roadmap**
- Cible BTP.

---

### F02 - Analyse de grimpe (vidéo -> feedback)

**But de la fonctionnalité**
- Donner un feedback technique objectif à partir d'une simple vidéo de grimpe.

**Ce que l'utilisateur voit**
- Un écran d'upload simple ou de capture vidéo.
- Un choix entre analyse 2D basique ou expérience 3D avancée.
- Un statut d'analyse (en attente, en cours, terminée, échec).
- Un résultat lisible avec points clés et recommandations.

**Parcours utilisateur simple**
1. L'utilisateur se connecte.
2. Il demande une URL d'upload (en fond avec MinIO).
3. Il envoie sa vidéo.
4. Il lance l'analyse.
5. Il suit la progression.
6. Il consulte le résultat final.

**Ce que le système fait en coulisse**
- Génération d'URL présignée pour upload direct objet.
- Création d'un job asynchrone via broker.
- Traitement par worker IA.
- Écriture du résultat en base.
- Notification du client (polling/API ou événement temps réel).

**Valeur pour l'utilisateur**
- Il obtient un retour concret sans coach présent.

**Niveau de maturité dans la roadmap**
- MVP démontrable et renforcé en BTP.

---

### F03 - Extraction de squelette et biomécanique

**But de la fonctionnalité**
- Convertir une vidéo en données biomécaniques exploitables (directement liée à l'analyse de la grimpe).

**Ce que l'utilisateur voit**
- Un squelette superposé à sa vidéo.
- Des informations sur sa posture et ses mouvements.

**Parcours utilisateur simple**
1. L'utilisateur charge sa vidéo.
2. L'IA détecte les points corporels image par image.
3. L'app affiche une restitution compréhensible.

**Ce que le système fait en coulisse**
- Extraction de points de pose (33 landmarks via MediaPipe).
- Calcul d'angles, postures, et indicateurs dérivés.
- Génération d'un format de sortie standardisé pour les autres modules.

**Valeur pour l'utilisateur**
- Il voit enfin des données objectives sur sa grimpe.

**Niveau de maturité dans la roadmap**
- Base MVP, puis reconstruction autour de SAM3D en BTP.

---

### F04 - Score global et indicateurs de progression

**But de la fonctionnalité**
- Donner une lecture rapide de la qualité de la grimpe et de son évolution.

**Ce que l'utilisateur voit**
- Un score global par session.
- Des indicateurs dans le temps (technique, puissance, endurance, etc.).

**Parcours utilisateur simple**
1. L'utilisateur ouvre son historique.
2. Il compare ses sessions récentes.
3. Il identifie si sa progression est stable, positive ou en baisse.

**Ce que le système fait en coulisse**
- Calcul de métriques par analyse.
- Agrégation mensuelle/hebdomadaire pour les courbes de progression.

**Valeur pour l'utilisateur**
- Il sait rapidement où il progresse et où il stagne.

**Niveau de maturité dans la roadmap**
- Cible BTP (avec enrichissement ATP).

---

### F05 - Mode Fantôme en comparaison

**But de la fonctionnalité**
- Montrer visuellement le chemin de mouvement optimal (la bêta) en comparaison de la grimpe réelle.

**Ce que l'utilisateur voit**
- Une trajectoire fantôme superposée à sa vidéo.
- Des écarts visibles entre son mouvement et le mouvement conseillé.

**Parcours utilisateur simple**
1. L'utilisateur prépare une analyse de voie.
2. Le système calcule un trajet de référence.
3. L'utilisateur lance la comparaison sur sa vidéo.
4. Il relit les points critiques et ajuste sa technique.

**Ce que le système fait en coulisse**
- Calcul de trajectoire (pathfinding/cinématique inverse selon contexte).
- Alignement temporel du fantôme avec la vidéo utilisateur.
- Restitution des déviations utiles à la pédagogie.

**Valeur pour l'utilisateur**
- Il comprend "quoi changer" concrètement, pas seulement "quoi corriger".

**Niveau de maturité dans la roadmap**
- MVP fonctionnel en BTP, version complète en ATP.

---

### F06 - Analyse des prises (détection, qualification, correction)

**But de la fonctionnalité**
- Automatiser la lecture de voie tout en gardant un contrôle manuel si l'IA se trompe.

**Ce que l'utilisateur voit**
- Les prises détectées sur la photo du mur.
- Un mode de correction manuelle par catégories.
- Un choix de mode (custom manuel ou sélection par couleur détectée).

**Parcours utilisateur simple**
1. L'utilisateur prend une photo de la voie.
2. L'IA détecte les prises.
3. L'utilisateur valide/corrige les prises.
4. Le résultat alimente le mode fantôme et les conseils.

**Ce que le système fait en coulisse**
- Détection et qualification des prises (type, difficulté, exploitation).
- Gestion d'un fallback manuel quand la détection est incomplète.
- Conservation des corrections pour améliorer le modèle (boucle d'apprentissage).

**Valeur pour l'utilisateur**
- Meilleure lecture de voie, plus fiable, et utilisable partout.

**Niveau de maturité dans la roadmap**
- Fonction avancée ATP.

---

### F07 - Mode Fantôme sans grimpe

**But de la fonctionnalité**
- Montrer visuellement le chemin de mouvement optimal (la bêta) à partir d'une simple photo de la voie, sans besoin de grimper ou filmer.

**Ce que l'utilisateur voit**
- L'outil de sélection des prises (automatique ou manuel) pour indiquer les prises utilisables.
- Une trajectoire fantôme superposée à la photo de la voie.

**Parcours utilisateur simple**
1. L'utilisateur prend une photo de la voie.
2. L'IA détecte les prises.
3. L'utilisateur sélectionne les prises.
4. Le système calcule et affiche la bêta optimale.

**Ce que le système fait en coulisse**
- Détection des prises et de leur qualité.
- Calcul de trajectoire de référence en fonction des prises utilisables et du profil de l'utilisateur.
- Restitution d'une bêta optimale sans besoin de grimper.

**Valeur pour l'utilisateur**
- Il peut visualiser la bêta optimale avant même de grimper, ce qui l'aide à mieux préparer sa montée.

**Niveau de maturité dans la roadmap**
- MVP fonctionnel en BTP, version complète en ATP.

---

### F08 - Expérience 3D mobile

**But de la fonctionnalité**
- Rendre les données techniques visuelles, intuitives et faciles à manipuler suite à une analyse de grimpe 3D.

**Ce que l'utilisateur voit**
- Une scène 3D manipulable au doigt (rotation, zoom, déplacement).
- Une reconstruction du mouvement lisible.

**Parcours utilisateur simple**
1. L'utilisateur ouvre une analyse 3D terminée.
2. Il active la vue 3D.
3. Il inspecte les moments clés de son mouvement.

**Ce que le système fait en coulisse**
- Transformation des données de pose en rendu 3D mobile.
- Optimisations pour garder des performances correctes sur terminaux cibles.

**Valeur pour l'utilisateur**
- Il comprend mieux les détails de posture qu'en simple 2D.

**Niveau de maturité dans la roadmap**
- Cible BTP.

---

### F09 - Conseils techniques personnalisés (IA externe)

**But de la fonctionnalité**
- Transformer les données brutes en conseils actionnables.

**Ce que l'utilisateur voit**
- Des recommandations claires : erreurs principales, priorités de correction, actions concrètes.

**Parcours utilisateur simple**
1. Une analyse est terminée.
2. L'utilisateur ouvre la fiche résultat.
3. Il lit des conseils adaptés à son mouvement et au contexte de voie.

**Ce que le système fait en coulisse**
- Combine les sorties biomécaniques et les infos de prises.
- Appelle un modèle externe de type Gemini (ou équivalent API) pour formuler le feedback.

**Valeur pour l'utilisateur**
- Il sait quelles actions faire à la prochaine session.

**Niveau de maturité dans la roadmap**
- Cible BTP (avec enrichissement ATP).

---

### F10 - Coach perso et programmes d'entraînement

**But de la fonctionnalité**
- Proposer un vrai plan de progression, pas seulement une analyse ponctuelle.

**Ce que l'utilisateur voit**
- Des objectifs (niveau actuel -> niveau cible).
- Des séances types personnalisées.
- Un suivi des sessions réalisées.

**Parcours utilisateur simple**
1. L'utilisateur définit ses objectifs et son niveau.
2. Le système génère des séances types.
3. L'utilisateur suit et journalise ses entraînements.

**Ce que le système fait en coulisse**
- Croise objectifs, historique d'analyses, blessures et profil.
- Propose des routines évolutives.

**Valeur pour l'utilisateur**
- Il passe d'un diagnostic ponctuel à une progression continue.

**Niveau de maturité dans la roadmap**
- Principalement ATP.

---

### F11 - Dimension communautaire et partage

**But de la fonctionnalité**
- Renforcer la motivation et l'engagement via la communauté.

**Ce que l'utilisateur voit**
- Comparaison de performances entre amis.
- Partage de montées et d'analyses.
- Paramètres de visibilité (privé, amis, public).

**Parcours utilisateur simple**
1. L'utilisateur active le partage sur certaines sessions.
2. Il compare ses résultats avec ses amis.
3. Il suit sa progression sociale.

**Ce que le système fait en coulisse**
- Gestion des droits de visibilité par contenu.
- Exposition des performances partageables.

**Valeur pour l'utilisateur**
- La progression devient plus motivante et sociale.

**Niveau de maturité dans la roadmap**
- ATP.

---

### F12 - Grimpe assistée (AR + audio)

**But de la fonctionnalité**
- Aider le grimpeur pendant la montée avec des conseils en temps réel.

**Ce que l'utilisateur voit**
- Un mode d'assistance active.
- Des indications vocales pendant l'effort (via écouteurs).

**Parcours utilisateur simple**
1. L'utilisateur pose son téléphone, lance le mode assisté.
2. L'IA suit la grimpe en temps réel.
3. L'utilisateur reçoit des conseils vocaux adaptés.

**Ce que le système fait en coulisse**
- Tracking temps réel de la posture.
- Génération de messages vocaux à fréquence contrôlée.
- Fallback si tracking perdu.

**Valeur pour l'utilisateur**
- Un coaching "pendant l'action", pas seulement après.

**Niveau de maturité dans la roadmap**
- ATP (fonction avancée).

---

### F13 - Abonnements, quotas et montée en gamme

**But de la fonctionnalité**
- Rendre le produit économiquement durable sans bloquer l'accès de base.

**Ce que l'utilisateur voit**
- Une offre Freemium et des options Premium/Infinity.
- Un compteur d'analyses restantes.
- Un parcours complet de souscription et gestion abonnement.

**Parcours utilisateur simple**
1. L'utilisateur commence en Freemium.
2. Il atteint les limites de quota.
3. Il peut passer en Premium/Infinity selon son usage.

**Ce que le système fait en coulisse**
- Application des quotas et droits par niveau d'offre.
- Gestion du cycle abonnement (renouvellement, changement d'offre, annulation, échec paiement).
- Instrumentation business (activation, rétention, conversion, churn).

**Valeur pour l'utilisateur**
- Il choisit un niveau adapté à son besoin réel.

**Niveau de maturité dans la roadmap**
- ATP.

---

### F14 - Onboarding et tutoriels rejouables

**But de la fonctionnalité**
- Aider un nouvel utilisateur à comprendre rapidement l'application.

**Ce que l'utilisateur voit**
- Un onboarding guidé au premier lancement.
- Un centre d'aide/tutoriels rejouables depuis les paramètres.

**Parcours utilisateur simple**
1. Premier lancement : mini parcours de prise en main.
2. Plus tard : consultation des tutos depuis les settings.

**Ce que le système fait en coulisse**
- Gestion de l'état "premier lancement".
- Stockage des progressions tuto.

**Valeur pour l'utilisateur**
- Moins de friction, meilleure compréhension des fonctions avancées.

**Niveau de maturité dans la roadmap**
- BTP.

---

### F15 - Accessibilité numérique (transverse)

**But de la fonctionnalité**
- Rendre l'application utilisable par le plus grand nombre, y compris les personnes en situation de handicap.

**Ce que l'utilisateur voit**
- Interface lisible (contraste, taille texte, focus clair).
- Compatibilité VoiceOver/TalkBack.
- Alternatives textuelles des contenus visuels importants.

**Parcours utilisateur simple**
1. L'utilisateur active ses options d'accessibilité système.
2. L'app respecte ces options sur les écrans critiques.
3. Les résultats restent compréhensibles sans dépendre uniquement de la couleur.

**Ce que le système fait en coulisse**
- Respect des exigences WCAG (objectif 2.2 AA en mobile).
- Tests manuels guidés + checks automatisables.
- Suivi de conformité dans les revues.

**Valeur pour l'utilisateur**
- Une app plus inclusive, plus robuste et plus facile à utiliser pour tous.

**Niveau de maturité dans la roadmap**
- Transverse: présent dès le MVP, renforcé en BTP et ATP.

---

### F16 - Fiabilité plateforme (pipeline, CI/CD, observabilité)

**But de la fonctionnalité**
- Garantir une expérience stable, sécurisée et maintenable.

**Ce que l'utilisateur voit**
- Moins de pannes.
- Des analyses plus fiables.
- Des temps de traitement plus prévisibles.

**Parcours utilisateur simple**
- L'utilisateur ne "voit" pas directement cette fonctionnalité, mais il ressent sa qualité dans toute l'application.

**Ce que le système fait en coulisse**
- Pipeline CI/CD robuste (qualité, tests, build, déploiement).
- Monitoring et boucle d'optimisation continue (mesurer -> tester -> optimiser -> re-mesurer).
- Traçabilité technique (benchmarks, PoC, décisions argumentées).

**Valeur pour l'utilisateur**
- L'application reste utilisable et inspire confiance.

**Niveau de maturité dans la roadmap**
- Priorité forte dès la livraison initiale Action Plan + BTP, puis continuation sur toute la roadmap.

---

## Synthèse par phase roadmap

### Avant septembre 2026 (livraison Action Plan + BTP)

- Base plateforme : CI/CD robuste, architecture propre, backlog, risques, formalités.
- Cadrage fonctionnel complet pour exécution.

### Exécution BTP (septembre 2026 -> juillet 2027)

- Parcours utilisateur complet.
- IA de pose reconstruite autour de SAM3D.
- Expérience 3D mobile.
- Mode Fantôme MVP.
- Accessibilité forte.
- Conseils personnalisés exploitables.

### Passage GreenLight + livraison ATP (juillet 2027)

- Validation go/no-go sur exécution BTP.
- ATP livré pour cadrer la suite.

### Exécution ATP (août 2027 -> mars 2028)

- Mode Fantôme complet.
- Lecture de prises avancée.
- Communauté et coach perso enrichis.
- Grimpe assistée temps réel.
- Cycle business complet et instrumentation produit.

---

## Points qui font la valeur unique d'Ascension

- **Agnostique du lieu**: fonctionne sur n'importe quel mur, sans base pré-remplie par salle.
- **Mode Fantôme pédagogique**: comparaison visuelle directe entre grimpe réelle et trajectoire conseillée.
- **Approche complète**: analyse, correction, entraînement, suivi, communauté.
- **Accessibilité intégrée**: prise en compte de l'inclusion dès la conception.
- **Architecture pragmatique**: pipeline asynchrone, rendu côté client, optimisation coût/performance.
