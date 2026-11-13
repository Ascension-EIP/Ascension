---
id: adc007ee-64c3-4a37-884b-07b65e0f2782
---

:::success
**Version:** 1.2
:::

---

# Catalogue complet des fonctionnalités Ascension

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
| --- | --- | --- | --- |
| F01 | Profil morphologique | Le feedback n'est pas adapté au corps de l'utilisateur | BTP |
| F02 | Sessions de grimpe & Analyse de pose 2D (vidéo -> feedback) | Le grimpeur ne voit pas ses erreurs ni le bilan global de sa séance en salle | MVP -> BTP |
| F03 | Extraction de squelette et biomécanique | Manque de mesures objectives sur le mouvement (2D en BTP, 3D en ATP) | MVP -> ATP |
| F04 | Score global et progression | Difficulté à suivre ses progrès par session et dans le temps | BTP |
| F05 | Comparaison de grimpe | Difficulté à comparer sa technique à celle d'autres grimpeurs sur la même voie | BTP |
| F06 | Détection & qualification des prises | Difficulté à lire une voie de manière fiable, à isoler et qualifier les prises sur une photo de mur | BTP (détection/groupes) -> ATP (qualification avancée) |
| F07 | Mode Fantôme (bêta réalisable pas à pas sur photo) | Difficulté à lire une voie vide et visualiser une solution possible avant l'essai | BTP |
| F08 | Analyse & Expérience 3D mobile | Les résultats 2D manquent parfois de lisibilité spatiale (profondeur, appuis) | ATP |
| F09 | Conseils techniques personnalisés | Les retours sont trop génériques | BTP |
| F10 | Coach perso / routines | Manque de plan de progression concret | BTP |
| F11 | Communauté et partage | Progression isolée, faible motivation sociale | BTP |
| F12 | Grimpe assistée temps réel (AR + audio) | Besoin d'aide et d'accessibilité vocale pendant la montée | ATP |
| F13 | Abonnements et quotas | Besoin d'un modèle économique durable | BTP -> ATP |
| F14 | Onboarding et tutoriels | L'utilisateur débutant ne comprend pas vite l'app | BTP |
| F15 | Accessibilité numérique | L'app devient inutilisable pour certains profils | MVP -> ATP |
| F16 | Fiabilité plateforme (CI/CD, pipeline) | Expérience instable, retards, incidents | Action Plan -> ATP |

---

## Parcours global simplifié (version débutant)

1. L'utilisateur crée son compte et complète son profil (niveau, morphologie, contraintes).
2. À son arrivée à la salle, il démarre une **session de grimpe** puis filme sa montée ou importe une vidéo.
3. L'app envoie la vidéo pour une analyse de pose (rattachée automatiquement à la session en cours).
4. Le système extrait les points du corps (2D en BTP, puis 3D en ATP), calcule des indicateurs chiffrés et génère un retour personnalisé.
5. L'utilisateur consulte son score, ses conseils techniques et, en fin de session, sa durée d'entraînement et ses statistiques globales.
6. S'il publie son analyse, un autre utilisateur ayant analysé la **même voie** peut comparer les deux montées.
7. Indépendamment de la vidéo, il peut utiliser le **Mode Fantôme** : photographier une voie, choisir un groupe de prises détecté (ex. par couleur) ou cliquer les prises manuellement, et obtenir une suite d'images détaillant une **bêta réalisable** étape par étape adaptée à sa morphologie.
8. Il accède également aux routines d'entraînement personnalisées et, en phase ATP, à l'expérience 3D interactive ainsi qu'à la grimpe assistée en temps réel.

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

### F02 - Sessions de grimpe & Analyse de pose (vidéo -> feedback)

**But de la fonctionnalité**

- Regrouper les montées d'une séance en salle via une session de grimpe et fournir un feedback technique objectif à partir de chaque vidéo.

**Ce que l'utilisateur voit**

- Un contrôle pour démarrer et clôturer sa **session de grimpe** en salle (durée d'entraînement et statistiques globales affichées en fin de session).
- Un écran d'upload simple ou de capture vidéo rattaché à la session en cours.
- Un choix entre analyse de pose 2D ou 3D.
- Un statut d'analyse (en attente, en cours, terminée, échec) et un résultat lisible avec métriques chiffrées et recommandations.

**Parcours utilisateur simple**

1. L'utilisateur se connecte et démarre une **session de grimpe** à son arrivée à la salle.
2. Il filme ou importe sa vidéo (upload direct S3 via URL présignée) et lance l'analyse, rattachée à sa session.
3. Il suit la progression et consulte ses métriques et conseils personnalisés.
4. En fin de séance, il clôt sa session et consulte sa durée totale et ses statistiques agrégées.

**Ce que le système fait en coulisse**

- Gestion du cycle de vie de `climbing_sessions` (démarrage, rattachement des vidéos/analyses, agrégation en fin de session).
- Génération d'URL présignée pour upload direct objet et création d'un job asynchrone via RabbitMQ.
- Traitement par worker IA et écriture du résultat en base.
- Notification du client (polling/API ou WebSocket).

**Valeur pour l'utilisateur**

- Un suivi complet à l'échelle de la séance d'entraînement et un retour concret sur chaque essai sans coach présent.

**Niveau de maturité dans la roadmap**

- Sessions de grimpe et analyse de pose 2D livrées en BTP/GreenLight ; extension 3D en ATP.

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

- Base MVP, amélioration de l'analyse 2D en BTP, puis reconstruction autour d'un modèle 3D en ATP.

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

### F05 - Comparaison de grimpe entre grimpeurs

**But de la fonctionnalité**

- Comparer visuellement et techniquement deux analyses de pose sur la **même voie** (entre ses propres essais ou avec les montées  d'autres utilisateurs) pour identifier les différences d'exécution.

**Ce que l'utilisateur voit**

- Une vue comparative de deux analyses vidéo d'une même voie.
- Les écarts articulaires, de rythme et de posture entre les deux grimpeurs.

**Parcours utilisateur simple**

1. L'utilisateur ouvre une de ses analyses de grimpe (ou une montée partagée).
2. Il sélectionne une autre analyse réalisée sur la **même voie** (un autre utilisateur autorisé ou un essai précédent).
3. Le système affiche la comparaison vidéo-à-vidéo et les métriques d'écart.

**Ce que le système fait en coulisse**

- Vérification des droits de visibilité et de la correspondance de voie.
- Alignement temporel des séries de points clés (2D en BTP, puis 3D en ATP).
- Calcul des écarts de posture et scores de similarité.

**Valeur pour l'utilisateur**

- Comprendre concrètement ce qui différencie son exécution de celle d'un autre grimpeur sur exactement le même problème.

**Niveau de maturité dans la roadmap**

- MVP fonctionnel en BTP, version complète en ATP.

---

### F06 - Détection & qualification des prises

**But de la fonctionnalité**

- Automatiser la détection et le regroupement des prises sur photo tout en gardant un contrôle manuel si l'IA se trompe ou si l'utilisateur veut personnaliser sa voie.

**Ce que l'utilisateur voit**

- Les prises détectées et regroupées (par voie/couleur) sur la photo du mur vide.
- Le choix entre sélectionner un groupe/couleur détecté ou cliquer manuellement les prises une par une.
- En ATP : la qualification avancée (type de prise, difficulté, exploitabilité).

**Parcours utilisateur simple**

1. L'utilisateur prend une photo de la voie.
2. L'IA détecte et regroupe les prises par couleur/voie.
3. L'utilisateur choisit le groupe souhaité (ex. prises rouges ou vertes) ou sélectionne/corrige manuellement les prises.
4. Les prises retenues alimentent le Mode Fantôme.

**Ce que le système fait en coulisse**

- Détection et clustering des prises (BTP) sur photo de voie vide.
- Qualification avancée (type, difficulté, exploitation) en phase ATP.
- Gestion d'une sélection manuelle au clic et conservation des corrections.

**Valeur pour l'utilisateur**

- Sélection rapide de la voie en salle sans base préalable, utilisable même en configuration mixte ou mur chargé.

**Niveau de maturité dans la roadmap**

- Détection/groupement et sélection groupe ou manuel en BTP ; qualification avancée en ATP.

---

### F07 - Mode Fantôme (bêta réalisable pas à pas sur photo)

**But de la fonctionnalité**

- Proposer visuellement **une bêta réalisable** (et non une prétendue « bêta optimale ») étape par étape à partir d'une **photo de voie**, sans grimper ni filmer.

**Ce que l'utilisateur voit**

- L'outil de sélection des prises sur photo : choix d'un ou plusieurs groupes de couleur détectés, ou sélection manuelle.
- Une succession d'images générées depuis la photo initiale (une image par étape) affichant chaque mouvement l'un après l'autre.

**Parcours utilisateur simple**

1. L'utilisateur prend une **photo de la voie** (aucun grimpeur à l'image).
2. L'IA détecte et regroupe les prises ; l'utilisateur choisit son groupe/couleur (ex. rouge, vert) ou choisit manuellement les prises exploitables.
3. Le système récupère le profil morphologique du grimpeur (mensurations, contraintes).
4. Le pathfinding calcule **une bêta réalisable** adaptée à sa morphologie et génère les mouvements/images étape par étape à partir de la photo initiale.
5. L'utilisateur fait défiler les images étape par étape sur mobile (aucune superposition sur vidéo ni comparaison vidéo-vs-fantôme).

**Ce que le système fait en coulisse**

- Détection et regroupement des prises sur la photo de voie vide.
- Pathfinding morphologique calculant un enchaînement réalisable selon les mensurations et contraintes corporelles.
- Génération d'une image par étape depuis la photo initiale avec le mouvement à exécuter.

**Valeur pour l'utilisateur**

- Déchiffrer et visualiser pas à pas une manière concrète et adaptée à son gabarit de grimper la voie avant même de poser les mains sur le mur.

**Niveau de maturité dans la roadmap**

- MVP fonctionnel en BTP (détection + groupement + choix groupe/manuel + bêta réalisable pas à pas), enrichi en ATP par la qualification avancée des prises (`F06`).

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

- Cible ATP.

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

- Cible BTP (avec enrichissement ATP).

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

- BTP.

---

### F12 - Grimpe assistée temps réel (AR + audio)

**But de la fonctionnalité**

- Aider le grimpeur pendant la montée avec des conseils en temps réel et offrir un mode d'accessibilité vocale pendant la montée (notamment pour les grimpeurs malvoyants).

**Ce que l'utilisateur voit**

- Un mode d'assistance active lancé avec le smartphone  face au mur.
- Des indications vocales en direct pendant l'effort (via écouteurs).

**Parcours utilisateur simple**

1. L'utilisateur pose son téléphone de façon fixe face au mur et lance le mode assisté avec ses écouteurs.
2. L'IA suit la grimpe en temps réel.
3. L'utilisateur reçoit des indications vocales adaptées sur sa posture et la progression.

**Ce que le système fait en coulisse**

- Tracking temps réel de la posture.
- Génération de messages vocaux à fréquence contrôlée.
- Fallback si tracking perdu.

**Valeur pour l'utilisateur**

- Un coaching "pendant l'action", pas seulement après.
- Un guidage audio inclusif pendant l'ascension, pensé pour l'accessibilité.

**Niveau de maturité dans la roadmap**

- MVP fonctionnel en ATP.

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

- Sessions de grimpe en salle (démarrage, rattachement des analyses, durée et stats de fin de session).
- Analyse de Pose 2D fonctionnelle (33 points clés, métriques chiffrées et conseils personnalisés).
- Mode Fantôme sur photo de voie  (détection et regroupement des prises avec choix par groupe/couleur ou clic manuel, bêta réalisable étape par étape).
- Communauté, partage et comparaison vidéo entre grimpeurs sur la même voie.
- Création de routines et suivi de progression.
- Parcours utilisateur complet et accessibilité forte.

### Passage GreenLight + livraison ATP (juillet 2027)

- Validation go/no-go sur exécution BTP.
- ATP livré pour cadrer la suite.

### Exécution ATP (août 2027 -> mars 2028)

- IA de pose reconstruite autour de modèle d'analyse 3D.
- Expérience 3D mobile interactive.
- Qualification avancée des prises (type, difficulté, exploitabilité).
- Coach perso enrichi et comparaison vidéo.
- Grimpe assistée temps réel MVP.
- Cycle business complet et instrumentation produit.

---

## Points qui font la valeur unique d'Ascension

- **Agnostique du lieu**: fonctionne sur n'importe quel mur, sans base pré-remplie par salle.
- **Mode Fantôme pédagogique**: décomposition pas à pas d'une bêta réalisable à partir d'une photo de voie et de la morphologie du grimpeur.
- **Approche complète**: sessions en salle, analyse, correction, entraînement, suivi, communauté.
- **Accessibilité intégrée**: prise en compte de l'inclusion dès la conception.
- **Architecture pragmatique**: pipeline asynchrone, rendu côté client, optimisation coût/performance.
