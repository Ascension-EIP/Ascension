:::success
**Version:** 1.0
:::

---

# ADR-003 : Migration du backend API Gateway de Rust (Axum) vers Go (Gin)

- **Date :** 2026-04-01
- **Statut :** Accepté *(Révision de la décision initiale de mars 2026)*
- **Périmètre :** Backend (`apps/server`)
- **Références :** [Backend Benchmark](../../../../developer/architecture/benchmark/backend.md), [Go vs Rust Functional Gap](../../../../drafts/go-vs-rust-functional-gap.md), [Suivi Mentoring n°4](../../../../resources/follow-up/mentoring/4.md)

---

## 1. Contexte et problème

L'API Gateway d'Ascension assure l'authentification (JWT), la gestion des utilisateurs et quotas, la délivrance d'URLs S3 présignées pour l'upload vidéo, l'orchestration des tâches RabbitMQ et la notification temps réel vers le client mobile Flutter.

À l'issue d'un benchmark synthétique initial (mars 2026), l'équipe avait d'abord choisi **Rust (Axum 0.8 + Tokio + SeaORM)** pour ses performances brutes exceptionnelles (105 000+ req/s, latence p99 < 2 ms, empreinte mémoire de 12 à 25 Mo au repos).

Cependant, l'implémentation réelle du MVP durant le sprint intensif *Prototype Pool* (2 semaines) a mis en évidence une forte friction opérationnelle :

- courbe d'apprentissage très abrupte pour les membres ne maîtrisant pas Rust (un seul développeur à l'aise sur le langage) ;
- vélocité fortement dégradée sur les évolutions métier courantes (ajout de relations, modification de DTO, propagation d'erreurs et *trait bounds* asynchrones) ;
- temps de compilation incrémentaux longs (35 à 90 secondes), ralentissant les boucles de test en local et en intégration continue ;
- ergonomie complexe de l'ORM SeaORM pour les filtres dynamiques et jointures.

---

## 2. Options envisagées

| Critère | Rust (Axum + SeaORM) *(choix initial)* | Go (Gin + GORM) | Node.js (TypeScript / Fastify) |
| --- | --- | --- | --- |
| **Débit maximal mesuré (`wrk`, 1k conn.)** | 105 000+ req/s | 58 000+ req/s | 28 000 req/s |
| **Mémoire sous charge (1k conn.)** | 94 Mo | 180 Mo | 420 Mo |
| **Latence p99** | < 2 ms (sans GC) | 8 – 15 ms (GC léger) | 25 – 50 ms (GC V8) |
| **Temps de compilation** | Lent (35 – 90 s) | Quasi instantané (< 2 s) | Rapide (transpilation TS) |
| **Prise en main équipe & vélocité** | Très difficile | Très rapide (< 48 h) | Immédiate |
| **Modèle de concurrence** | `async`/`await` + Tokio + lifetimes | Goroutines natives (`go func()`) | Boucle événementielle mono-thread |

---

## 3. Option choisie

Réécriture et migration complète du backend vers **Go (Gin + GORM)**, avec abandon définitif de l'implémentation `apps/server-rust`.

---

## 4. Raison (ce qui a fait changer l'équipe d'avis)

1. **Priorité à la vélocité et à la maintenabilité sur la performance brute :** l'API Gateway est essentiellement limitée par les entrées/sorties réseau (PostgreSQL, RabbitMQ, S3) et non par le calcul CPU. Passer de 105 000 req/s à 58 000 req/s n'a aucun impact fonctionnel pour la charge d'Ascension, alors que le gain de productivité est décisif sur un projet EIP d'un an à 5 personnes.
2. **Parallélisme et couverture fonctionnelle validés :** lors de l'audit comparatif du 1er avril 2026 ([go-vs-rust-functional-gap.md](../../../../drafts/go-vs-rust-functional-gap.md)), le serveur Go couvrait déjà les mêmes domaines métier tout en étant plus avancé sur les flux critiques (refresh token, confirmation d'upload, URL de téléchargement, branchement effectif des middlewares de rôles).
3. **Onboarding immédiat de l'équipe :** en moins de 48 heures, l'ensemble des développeurs a pu contribuer de manière autonome sur les handlers Go, avec des builds locaux en moins de 2 secondes.
4. **Validation en conditions réelles :** l'API Go maintient une latence p95 inférieure à 15 ms pour une empreinte mémoire conteneur sous les 60 Mo, bien en deçà de la cible (< 200 ms p95).

---

## 5. Conséquences acceptées

- **Coût ponctuel de réécriture :** le code produit en Rust durant le Prototype Pool a été abandonné, et certains éléments plus avancés côté Rust (documentation OpenAPI/Swagger, suivi détaillé de progression d'analyse) ont dû être réimplémentés en Go.
- **Garantie mémoire moindre à la compilation :** contrairement au *borrow checker* de Rust, Go repose sur un *garbage collector* et autorise les pointeurs `nil` ; la rigueur de revue de code, les tests unitaires et l'analyse statique (`golangci-lint`, SonarQube) doivent compenser cette souplesse.
- **Gestion d'erreurs verbeuse :** le pattern idiomatique `if err != nil` ajoute du code répétitif mais rend les chemins d'erreur explicites et faciles à auditer.
