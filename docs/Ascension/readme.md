---
id: 70a1364c-671e-4bda-90e9-1518b784c93e
sort: custom
order:
  - user
  - developer
  - administrative
  - resources
  - drafts
---

:::success
**Version:** 1.0
:::

---

# Documentation Ascension

Bienvenue dans l'espace documentaire central du projet **Ascension**.

Ascension est une solution d'entraînement et d'analyse biomécanique intelligente dédiée à l'escalade. Grâce à la vision par ordinateur et à l'intelligence artificielle, l'application transforme tout smartphone en un coach d'escalade objectif, capable d'extraire la posture du grimpeur (squelette 2D et 3D), de qualifier les prises du mur, de générer des conseils techniques personnalisés et de projeter le mouvement optimal via le mode fantôme.

---

## Organisation de la documentation

Pour répondre aux besoins spécifiques de chaque public, la documentation du projet est structurée en **3 documentations principales** complétées par un espace de ressources partagées :

| Documentation | Langue | Public cible | Description |
| --- | --- | --- | --- |
| [**Documentation Utilisateur**](user/readme.md) | Anglais (`en`) | Grimpeurs & Salles partenaires | Guides de prise en main, capture vidéo, compréhension des analyses, Ghost Mode et FAQ. |
| [**Documentation Développeur**](developer/readme.md) | Anglais (`en`) | Ingénieurs & Contributeurs | Architecture système, microservices (Mobile, Server, AI), standards Git et spécifications d'API. |
| [**Documentation Administrative**](administrative/readme.md) | Français (`fr`) | Référents EIP, Jurys & Équipe | Suivi académique Epitech, livrables RNCP, catalogue de fonctionnalités, roadmap et plans de tests. |
| [**Ressources & Médias**](resources/readme.md) | Multi | Tous | Schémas d'architecture Excalidraw, présentations (decks), photographies et assets graphiques. |

:::info
**Note linguistique :** Les documentations technique (développeur) et produit (utilisateur) sont rédigées intégralement en anglais afin de garantir l'accessibilité internationale du code et du produit. La documentation administrative est maintenue en français pour satisfaire le cadre académique d'Epitech et les jurys francophones.
:::

---

## Les 3 piliers documentaires

### 1\. Documentation Utilisateur (User)

Destinée aux personnes qui utilisent l'application mobile Ascension au quotidien :

- **Premiers pas :** Installation de l'application, création de compte et configuration du profil morphologique.
- **Enregistrement des ascensions :** Recommandations d'angle et de luminosité pour filmer efficacement une voie ou un bloc.
- **Restitution de l'analyse :** Interprétation des scores, visualisation du squelette 2D/3D et conseils du coach virtuel.
- **Ghost Mode & Programmes :** Utilisation de l'overlay de comparaison et suivi de programmes d'entraînement sur-mesure.

### 2\. Documentation Développeur (Developer)

Destinée aux développeurs souhaitant comprendre l'architecture, configurer leur environnement local ou contribuer au code source :

- **Architecture globale :** Présentation du monorepo géré par `moonrepo`, découpage entre API Gateway (Go), workers IA (Python) et client mobile (Flutter).
- **Standards & Bonnes pratiques :** Guides de style Markdown, conventions Conventional Commits, règles de nommage des branches Git et intégration continue.
- **Spécifications techniques :** Modèle de données PostgreSQL, routes REST & WebSocket, et files AMQP RabbitMQ.
- **Agents d'assistance :** Instructions système et boîtes à outils pour les agents IA (Claude Code, Copilot, Antigravity).

### 3\. Documentation Administrative (Administrative)

Dédiée à la gouvernance, à la gestion de projet et au cadre académique de l'Epitech Innovative Project (EIP) :

- **Périmètre fonctionnel :** Catalogue exhaustif des fonctionnalités, roadmap de développement et jalons de livraison (MVP, BTP, ATP).
- **Assurance qualité & Recette :** Plan d'action opérationnel, plan de tests bêta, plan de recette fonctionnelle et conformité d'accessibilité.
- **Modèle économique :** Détail des offres tarifaires (Freemium, Premium, Infinity) et des quotas associés.
- **Suivi de projet & RNCP :** Mémos hebdomadaires de l'équipe et dossiers de compétences pour la certification RNCP.

---

## Navigation

:::subpages cards 3
