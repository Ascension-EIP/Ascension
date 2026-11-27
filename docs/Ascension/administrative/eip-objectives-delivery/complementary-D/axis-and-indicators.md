---
id: e0fc3689-6981-4255-a627-ec82bfb00ebd
---

:::success
**Version:** 1.0
:::

# Choix de l'axe de mesure et des indicateurs de performance

---

## 1. Axe prioritaire retenu

- **Axe officiel du guide EIP :** Temps de réponse et d'exécution (*Response or execution time*).
- **Périmètre ciblé :** Les **pipelines IA du worker Python exécutés sur CPU** (analyse de pose 2D, détection/segmentation des prises et calcul du Mode Fantôme).

---

## 2. Justification du choix

### 2.1 Pourquoi cet axe est critique pour Ascension

1. **Vrai goulot d'étranglement de l'architecture :** l'API Go (Gin) ne gère que des opérations légères (CRUD PostgreSQL, génération d'URLs présignées S3, publication RabbitMQ). L'essentiel du temps de calcul et de la charge serveur se situe dans les workers Python (`apps/ai/src/worker/`), qui exécutent MediaPipe, YOLO26-seg (ONNX) et le pipeline de pathfinding (profondeur métrique + recherche bêta + reconstruction de posture).
2. **Contrainte d'infrastructure CPU :** en phase de développement et de lancement, l'infrastructure repose sur un VPS OVHcloud CPU sans GPU dédié afin de maîtriser les coûts d'exploitation. Chaque seconde économisée sur l'inférence augmente directement la capacité de traitement concurrent des files RabbitMQ.
3. **Impact direct sur l'expérience utilisateur en salle :** un grimpeur utilise Ascension entre deux essais. Si l'analyse d'une vidéo de 30 secondes prend plusieurs minutes ou si la détection des prises bloque la sélection sur photo, l'utilisateur abandonne l'outil.

### 2.2 Risque en cas d'inaction

Sans mesure ni optimisation structurée :

- Les files RabbitMQ (`pose.detect`, `holds.detect`, `pathfinding.compute`) s'engorgent dès quelques utilisateurs simultanés.
- Le temps d'attente dépasse le seuil acceptable en séance d'escalade, dégradant la rétention.
- La seule réponse possible devient une montée en gamme matérielle (GPU cloud), qui remet en cause l'équilibre économique du modèle freemium.

### 2.3 Pourquoi ne pas mélanger d'autres axes dans l'objectif principal

- **Tests de charge API (tenue en charge) :** l'API Go n'est pas le facteur limitant actuel ; un test de charge HTTP seul mesurerait surtout la réactivité de Gin/PostgreSQL sans traiter le coût réel des pipelines IA.
- **Qualité des modèles de vision (mAP, justesse du nombre de prises) :** comme souligné lors du suivi n°4, la précision de détection reste essentielle. Elle est intégrée ci-dessous en **garde-fou de non-régression** (au même titre que la consommation mémoire RAM) afin de prouver qu'aucun gain de vitesse n'est obtenu au détriment de la qualité des résultats.

---

## 3. Indicateurs retenus et objectifs chiffrés

> **Note de lecture :** `p95` (95e percentile) signifie que **95 % des exécutions** sont plus rapides que la valeur indiquée (seuls les 5 % les plus lents la dépassent). `RTF` (*Real-Time Factor*, ou facteur temps réel) correspond au ratio **temps de calcul / durée de la vidéo** (un `RTF` de `1,0x` signifie que l'analyse est au moins aussi rapide que la durée réelle de la vidéo).

| # | Indicateur | Formule | Outil de mesure | Conditions de mesure | Objectif fin d'année | Justification de la cible |
| --- | --- | --- | --- | --- | --- | --- |
| **1** | **Facteur temps réel — Analyse de pose 2D (`RTF`, temps de calcul / durée vidéo)** | `RTF = t_pipeline_pose / d_video` | Instrumentation Python (`time.perf_counter()`) + profiling (`cProfile` / `py-spy`) | Jeu fixe de 5 vidéos d'escalade 1080p à 30 fps (durée 15 à 30 s), exécutées sur le VPS CPU de référence, 5 répétitions (médiane et p95) | **`RTF <= 1,0x`** en p95 (95 % des cas) | Une vidéo de 30 s est analysée en moins de 30 s (au moins aussi rapide que le temps réel), ce qui reste confortable le temps de redescendre du mur et de reprendre son téléphone. |
| **2** | **Latence détection & segmentation des prises (`holds.detect`)** | `t_total = t_yolo_onnx + t_couleurs` (en secondes) | Commande CLI `holds-detect` instrumentée (`time.perf_counter()`) | Jeu fixe de 20 photos de murs réels (résolution smartphone standard), exécutées sur le VPS CPU de référence, 5 répétitions (médiane et p95) | **`< 5,0 s`** en p95 (95 % des cas) | Temps d'attente court après prise de photo pour afficher les prises détectées et laisser l'utilisateur valider sa voie, avec une marge réaliste face à la charge du VPS CPU. |
| **3** | **Latence calcul Mode Fantôme (`pathfinding.compute`)** | `t_total = t_mur + t_profondeur + t_beta + t_pose` (en secondes) | Commande CLI pathfinding instrumentée (`time.perf_counter()`) | Jeu fixe de 10 voies de référence (12 à 20 prises, profils morphologiques fixés), hors attente RabbitMQ, sur le VPS CPU de référence, 5 répétitions (médiane et p95) | **`< 20,0 s`** en p95 (et `< 30,0 s` max) | Aligné avec le critère du point dur déjà validé (`< 25 s` en moyenne, `< 30 s` max pour une voie standard), tout en laissant de la marge à l'enrichissement du solveur. |

---

## 4. Garde-fous de non-régression

Conformément aux exigences du guide EIP, chaque boucle d'optimisation sera validée non seulement par la suite de tests existante, mais aussi par des indicateurs de non-régression mesurés avant et après chaque changement :

1. **Mémoire (pic `RSS`, c'est-à-dire la RAM physique maximale réellement consommée par le worker Python) :** mesurée via `psutil` / `tracemalloc` sur le même jeu de données. Seuil d'acceptation : aucune augmentation supérieure à **+10 %** du pic mémoire par rapport à la baseline.
2. **Qualité de détection des prises (`mAP` et comptage) :**
   - `masks mAP@50` (précision moyenne de segmentation YOLO avec au moins 50 % de recouvrement avec la vraie prise) évaluée sur le split de test du modèle YOLO26-seg (`apps/ai/training/holds`).
   - **Erreur moyenne absolue (`MAE`, écart moyen en nombre de prises entre la réalité et la détection)** par mur sur le jeu de 20 photos de référence (ex. vérifier que si un mur compte 20 prises, le modèle en détecte un nombre cohérent).
   - Seuil d'acceptation : aucune baisse supérieure à **1 point de mAP@50** ni dégradation significative du comptage après optimisation (ex. quantification ONNX ou redimensionnement d'entrée).
3. **Précision de la classification couleur :** vérifiée via la commande existante `holds-colors-eval` sans régression sur le score de référence.

---

## 5. Pistes d'optimisation envisagées pour les boucles futures

Sans préjuger du diagnostic qui sera établi par profiling en février, plusieurs leviers isolés sont déjà identifiés pour les boucles 1 (mars) et 2 (mai) :

- **Analyse de pose 2D (`_1_mediapipe`) :** réglage de la résolution de décodage OpenCV, sélection du modèle MediaPipe / cadence d'échantillonnage adaptative (frame-skipping sur phases statiques), parallélisation lecture/inférence.
- **Détection des prises (`_3_holds`) :** tuning des threads `onnxruntime` sur CPU, quantification INT8/FP16 du modèle YOLO26-seg, vectorisation de l'extraction de couleurs (`_2_hold_color.py`).
- **Mode Fantôme (`_4_pathfinding`) :** optimisation/redimensionnement de l'estimation de profondeur métrique (`_1_depth.py`), amélioration des heuristiques et de l'élagage dans la recherche bêta (`_2_beta.py`).

---

## 6. Prochaines étapes (calendrier EIP)

| Étape | Échéance | Action prévue |
| --- | --- | --- |
| **Protocole de mesure** | Avant fin janvier | Figer le jeu de données de référence (vidéos, photos, voies), rédiger le protocole reproductible et ajouter une commande automatisée (`moon run ai:benchmark`) exportant les mesures datées (JSON/CSV). |
| **Baseline & diagnostic** | Avant fin février | Exécuter la baseline datée sur le VPS de référence et profiler chaque pipeline (`cProfile` / `py-spy`) pour isoler les goulots exacts. |
| **Boucle 1** | Avant fin mars | Appliquer une première optimisation isolée, remesurer dans les mêmes conditions, documenter le gain (absolu et %) et valider les garde-fous de non-régression. |
| **Boucle 2** | Avant fin mai | Appliquer une seconde optimisation isolée, remesurer, compléter le tableau avant/après et l'historique de suivi. |
