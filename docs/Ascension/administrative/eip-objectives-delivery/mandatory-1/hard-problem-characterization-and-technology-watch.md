:::success
**Version:** 1.0
:::

# Caractérisation du point dur et dispositif de veille opérationnel

---

## 1. Le problème à résoudre : le Mode Fantôme

- **Ce qu'on veut faire :** L'utilisateur prend une photo d'une voie d'escalade et sélectionne ses prises ou laisse l'IA les détecter. En fonction de la morphologie du grimpeur, l'application doit lui donner la séquence de mouvements étape par étape pour réussir la voie (ex. _Étape 1 : pied gauche sur la prise 2, main droite sur la prise 4..._).
- **Ce qu'on ne sait pas faire aujourd'hui :** Trouver automatiquement une suite de mouvements logique, humaine et réalisable sans que le grimpeur se retrouve coincé ou dans une posture impossible.

---

## 2. Pourquoi c'est dur

1. **Pas de solution unique (« pas de bêta parfaite ») :** Deux grimpeurs ne grimpent pas de la même façon. Quelqu'un de plus petit va monter ses pieds plus haut, quelqu'un de grand va chercher des prises plus loin. Il n'y a pas une seule bonne réponse qu'on pourrait simplement copier.
2. **Les erreurs de la photo se répercutent sur l'algo :** Si la détection sur la photo décale une prise de 10 cm ou rate une petite prise de pied, l'algorithme va calculer un mouvement sur du vide ou penser qu'une prise est inatteignable.
3. **Pas de données d'entraînement toutes faites :** Il n'existe aucun jeu de données public qui associe des photos de voies à la liste exacte des mouvements réussis par différents types de personnes. On doit construire notre propre logique.
4. **La cohérence physique dans le temps :** Le grimpeur ne peut pas se téléporter. Chaque mouvement part de la position précédente. Pour lever une main ou un pied, il faut que le reste du corps garde l'équilibre (ne pas basculer en arrière ou décrocher).

---

## 3. Pourquoi une solution toute simple (naïve) ne marche pas

- **La solution naïve :** Relier simplement les prises de bas en haut en allant à chaque fois à la prise la plus proche au-dessus.
- **Pourquoi ça échoue à tous les coups :**
  - **Croisements de membres aberrants :** L'algo naïf va par exemple demander de poser le pied droit 1 mètre à gauche du pied gauche, les jambes complètement croisées.
  - **Perte d'équilibre immédiate :** Il ne vérifie pas si le grimpeur a assez d'appuis pour tenir au moment où il déplace une main.
  - **Il ignore la taille du grimpeur :** Une prise située à 1m30 sera proposée de la même façon à quelqu'un d'1m50 et à quelqu'un d'1m90, alors que le premier ne peut physiquement pas l'attraper.

---

## 4. Critères de réussite chiffrés

1. **Faisabilité physique (100 %) :** 100 % des mouvements proposés doivent respecter la portée du grimpeur (aucune prise demandée au-delà de ce que ses bras et jambes peuvent atteindre).
2. **Maintien de l'équilibre ($\ge$ 85 %) :** Lors de chaque changement de prise, le grimpeur doit garder au moins 3 appuis stables (règle des 3 points d'appui) sur au moins 85 % des étapes de la voie.
3. **Différenciation selon la morphologie ($\ge$ 20 %) :** Sur une même voie standard comportant des prises intermédiaires (12 à 20 prises), l'algorithme doit proposer au moins 20 % d'étapes différentes entre un profil petit (~1m60) et un profil grand (~1m85) (ex. saut d'une prise intermédiaire par le grand, ou replacement de pied supplémentaire pour compenser la taille), tout en restant faisable pour les deux.
4. **Temps de calcul (< 30 secondes) :** Le calcul complet de la voie doit prendre **moins de 25 secondes en moyenne**, et jamais plus de 30 secondes pour une voie standard (moins de 20 prises).

---

## 5. Notre dispositif de veille opérationnel

### 5.1 Ce qu'on regarde (sources)

- **Projets open source et dépôts GitHub :** travaux sur la détection de prises d'escalade et générateurs de voies.
- **Articles et recherches sur l'escalade :** notamment les travaux de chercheurs en biomécanique du sport.
- **Algorithmes de graphes et de pathfinding :** recherche de chemin avec contraintes physiques.

### 5.2 Nos outils

- **Instance n8n auto-hébergée sur VPS :** workflow d'automatisation déployé sur notre VPS (via Docker) qui s'exécute chaque matin pour interroger les flux RSS (arXiv, releases GitHub, Google Scholar) et filtrer les publications par mots-clés pertinents.
- **Salon Discord `#veille-technique` :** relié directement à n8n via un webhook pour recevoir automatiquement les alertes formatées (titre, lien, extrait et tags).
- **Documentation partagée :** fiches de synthèse écrites dans la doc du projet pour tracer ce que l'on retient ou élimine.

### 5.3 Notre rythme

- **Individuel :** environ 1 heure par semaine par personne pour se documenter et tester des approches.
- **Équipe :** un point rapide de 15 minutes toutes les deux semaines pour décider si une idée ou un outil peut servir dans Ascension.
- **Objectif EIP :** alimenter le journal pour avoir au moins 20 entrées documentées et 6 présentations internes sur l'année.

### 5.4 Qui suit quoi dans l'équipe

- **Gianni TUERO & Olivier POUECH (IA) :** Algorithmes de pathfinding, modélisation physique du grimpeur et détection des prises dans le worker IA.
- **Lou PELLEGRINO (Backend) :** Transmission asynchrone des calculs via RabbitMQ et sauvegarde des résultats dans PostgreSQL sans bloquer l'API Go.
- **Nicolas TORO (Mobile) :** Restitution visuelle pas-à-pas de la bêta dans l'application mobile et ergonomie utilisateur.
- **Christophe VANDEVOIR (Infra) :** Déploiement et dimensionnement des ressources (CPU/RAM) sur le VPS pour que les workers IA tournent efficacement.

---

## 6. Journal de recherche (Research Log)

### 6.1 Format d'une fiche

Pour chaque entrée dans le journal, nous notons :

- **Date :** Quand la ressource a été consultée.
- **Auteur :** Qui l'a analysée.
- **Source & lien :** Référence de l'article, vidéo ou repo.
- **Sujet :** Ce que ça explique en 2-3 lignes.
- **Apport pour Ascension :** Ce que ça peut changer pour notre projet.
- **Décision :** Ce qu'on fait (Adopté / En test / Écarté, et pourquoi).

### 6.2 Exemple de première entrée

- **Date :** 15 octobre 2026
- **Auteur :** Gianni TUERO
- **Source :** Travaux de Lionel Reveret sur le mouvement en escalade.
- **Sujet :** Analyse du placement des appuis et de l'équilibre du grimpeur.
- **Apport pour Ascension :** Confirme que la règle des 3 appuis permet d'éviter les positions de déséquilibre sans calcul trop lourd.
- **Décision :** Adopté. Intégration de cette règle comme contrainte dans notre algorithme pour éliminer immédiatement les positions de chute.
