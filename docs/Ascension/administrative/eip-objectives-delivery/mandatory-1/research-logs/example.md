---
id: f582c2a1-7dd9-40fa-8028-55656d16fe68
---

:::success
**Version:** 1.0
:::

---

# Exemples de fiches de recherche (Research Log Examples)

Ce document fournit deux exemples concrets de fiches rédigées selon le gabarit officiel du projet :

1. **Une piste validée et adoptée** (intégration dans le solveur du Mode Fantôme).
2. **Une piste explorée puis écartée** (résultat négatif motivé, valorisé par l'EIP).

---

## Exemple 1 : Piste adoptée

### [RL-01] Analyse biomécanique de l'équilibre statique et règle des 3 appuis

- **Date d'analyse :** 15 octobre 2026
- **Auteur :** Gianni TUERO (Pôle IA)
- **Thématique :** Algorithmes de pathfinding & Biomécanique
- **Source :** Article de recherche — _L. Reveret, F. Quaine, "Biomechanical model of static equilibrium in rock climbing", Journal of Sports Biomechanics, 2021_.
- **Lien :** `https://doi.org/10.1080/14763141.2021.1895632` (remonté via la veille arXiv `cs.RO` / n8n)

#### 1. Synthèse technique

L'article modélise les conditions d'équilibre statique d'un grimpeur sur paroi verticale en s'appuyant sur le polygone de sustentation défini par les points de contact actifs (mains et pieds). Les auteurs démontrent que la projection orthogonale du centre de masse (CoM) à l'intérieur de ce polygone, combinée à une règle de maintien de 3 appuis simultanés lors des transitions, suffit à garantir la stabilité statique dans 92 % des mouvements standards de bloc, sans nécessiter de calcul dynamique complet des forces de frottement.

#### 2. Apport pour le point dur d'Ascension (Mode Fantôme)

- **Problème ciblé :** La recherche de chemin naïve entre prises générait des postures biomécaniquement instables ou aberrantes (croisements extrêmes, chute immédiate).
- **Impact sur nos critères de succès :**
  - **Maintien de l'équilibre :** Permet d'atteindre notre critère de $\ge 85\%$ de postures stables en éliminant immédiatement dans l'arbre d'exploration les configurations où le CoM sort du polygone de sustentation.
  - **Temps de calcul :** Évite de lancer une simulation physique lourde à chaque étape, maintenant le temps de calcul moyen sous notre seuil cible de 25 secondes.

#### 3. Décision & Plan d'action

- **Statut :** **Adopté**
- **Justification :** Modèle mathématique simple, déterministe et très peu gourmand en ressources CPU, parfaitement adapté à un traitement rapide dans notre worker IA.
- **Action concrète :** Intégration de la validation géométrique des 3 appuis et du polygone de sustentation comme filtre d'élagage dans l'algorithme de pathfinding (`apps/ai/workers/pathfinding/solver.py`). Présentation des résultats lors du point d'équipe du 5 novembre.

---

## Exemple 2 : Piste explorée puis écartée (Résultat négatif)

### [RL-02] Génération de séquence de grimpe par Deep Reinforcement Learning (PPO)

- **Date d'analyse :** 28 octobre 2026
- **Auteur :** Olivier POUECH (Pôle IA)
- **Thématique :** Intelligence artificielle & Génération de trajectoire
- **Source :** Dépôt GitHub & publication — _DeepClimb: Reinforcement Learning for Humanoid Climbing in MuJoCo, 2023_.
- **Lien :** `https://github.com/deepclimb/deepclimb-sim` (remonté via la veille GitHub Repos / n8n)

#### 1. Synthèse technique

Le projet utilise l'algorithme Proximal Policy Optimization (PPO) entraîné dans l'environnement physique MuJoCo pour apprendre à un agent humanoïde à escalader une paroi en 3D. Le modèle apprend par essais-erreurs en optimisant une fonction de récompense basée sur l'altitude atteinte et la dépense d'énergie.

#### 2. Apport pour le point dur d'Ascension (Mode Fantôme)

- **Problème ciblé :** Tester la faisabilité d'une génération end-to-end des mouvements par apprentissage renforcé sans modéliser manuellement les règles de transition.
- **Impact sur nos critères de succès :**
  - **Faisabilité & Généralisation :** Le modèle peine à converger dès que la configuration des prises s'écarte de la paroi d'entraînement synthétique.
  - **Temps de calcul :** Le temps d'inférence et d'adaptation à une nouvelle disposition de prises dépasse 4 minutes sur GPU VPS, ce qui enfreint largement notre critère d'exigence (< 30 secondes).

#### 3. Décision & Plan d'action

- **Statut :** **Écarté**
- **Justification :** Approche trop instable pour un usage de production sur des parois arbitraires (photos réelles) et coût en calcul prohibitif pour l'infrastructure VPS du projet. L'absence d'explicabilité des mouvements générés rend également le débogage complexe.
- **Action concrète :** Abandon de la piste Deep RL au profit d'un algorithme de graphe avec heuristiques géométriques et biomécaniques (A* / Dijkstra contraint). Consigné comme contre-analyse dans notre note d'état de l'art EIP de décembre.
