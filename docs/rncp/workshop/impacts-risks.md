> **Last updated:** 26th February 2026  
> **Version:** 1.2  
> **Authors:** Olivier POUECH and Nicolas TORO  
> **Status:** Done  
> {.is-success}  

---

# Impacts, Risks & Mitigation - Workshop Deliverable

---

## 1. Risk Management

### Matrice des risques

| #  | Risque                                                                                           | Catégorie    | Probabilité (1-5) | Impact (1-5) | Criticité (P×I) | Stratégie | Plan de mitigation                                                                                              |
| -- | ------------------------------------------------------------------------------------------------ | ------------ | :---------------: | :----------: | :-------------: | --------- | --------------------------------------------------------------------------------------------------------------- |
| 1  | Précision insuffisante du modèle ML (MediaPipe ne détecte pas correctement les poses d'escalade) | Technique    |         4         |      5       |     **20**      | Réduire   | Dataset d'entraînement spécifique escalade, validation par grimpeurs experts, fallback sur détection simplifiée |
| 2  | Panne du serveur ML (Machine 3 - Workers Python)                                                 | Opérationnel |         3         |      4       |     **12**      | Réduire   | Queue RabbitMQ persistante (jobs pas perdus), retry automatique, alerting Grafana immédiat                      |
| 3  | Départ d'un membre clé de l'équipe                                                               | Opérationnel |         3         |      5       |     **15**      | Réduire   | Documentation technique obligatoire, code reviews croisées, pas de knowledge siloing                            |
| 4  | Fuite de données utilisateurs (vidéos + données biométriques)                                    | Sécurité     |         2         |      5       |     **10**      | Réduire   | Chiffrement AES-256 au repos, TLS 1.3 en transit, accès S3 privé signé, audit RGPD                              |
| 5  | Corruption ou perte de la base de données PostgreSQL                                             | Technique    |         1         |      5       |      **5**      | Réduire   | Backup quotidien pg_dump + WAL archiving continu, RPO < 15 min, test restore mensuel                            |
| 6  | Upload vidéo échoue (fichier > 200 MB, réseau instable)                                          | Technique    |         4         |      3       |     **12**      | Réduire   | Upload chunked (5 MB par chunk), reprise sur erreur, compression vidéo côté mobile avant upload                 |
| 7  | Hetzner datacenter indisponible (panne provider)                                                 | Opérationnel |         1         |      5       |      **5**      | Accepter  | SLA Hetzner 99.9%, monitoring uptime, procédure de bascule documentée                                           |
| 8  | Dépassement budget cloud (croissance inattendue)                                                 | Financier    |         2         |      3       |      **6**      | Réduire   | Billing alerts Hetzner à 80% budget, rate limiting API, compression vidéos auto                                 |
| 9  | Refus App Store / Play Store (politique Apple/Google)                                            | Opérationnel |         2         |      4       |      **8**      | Réduire   | Respect guidelines dès le début, review interne avant soumission, délai buffer 2 semaines                       |
| 10 | Injection SQL / attaque API                                                                      | Sécurité     |         2         |      5       |     **10**      | Réduire   | SQLx compile-time queries (pas d'injection possible), rate limiting Nginx, input validation                     |
| 11 | Latence analyse trop élevée (> 10 min)                                                           | Technique    |         3         |      3       |      **9**      | Réduire   | Optimisation algorithme OpenCV, processing asynchrone avec notification push, progress bar                      |
| 12 | RGPD - Consentement vidéos / données biométriques                                                | Légal        |         3         |      5       |     **15**      | Éviter    | Consentement explicite obligatoire à l'onboarding, droit à l'effacement implémenté, DPO désigné                 |

---

### Visualisation Matrice (Impact vs Probabilité)

```
Impact
  5 |  [3,12]  [1]       [RGPD]
    |          [4,10]
  4 |  [9]     [2]
    |
  3 |          [11]      [6]
    |
  2 |
    |  [5,7]
  1 |
    +----+----+----+----+----
         1    2    3    4    5   Probabilité

Légende :
  CRITIQUE (>= 15) : [1] ML précision, [3] Départ membre, [RGPD]
  ÉLEVÉ (10-14)    : [2] Panne workers, [4] Fuite données, [6] Upload, [10] Injection
  MODÉRÉ (5-9)     : [5] DB corruption, [7] Provider, [8] Budget, [9] App Store, [11] Latence
```

---

### Détail des risques critiques (criticité >= 10)

**Risque 1 - Précision ML insuffisante (criticité 20)**
- Cause : MediaPipe entraîné sur poses génériques, pas spécifique escalade
- Impact : Feedback erroné = perte de confiance utilisateur, potentiel danger blessure
- Mitigation :
  - Collecter dataset propriétaire de vidéos d'escalade (minimum 500 vidéos labellisées)
  - Fine-tuning du modèle avec TensorFlow Lite
  - Indicateur de confiance affiché à l'utilisateur (score < 70% = résultat non affiché)
  - Vérification faite par l'utilisateur
  - Beta testing avec 10 grimpeurs avant release

**Risque 3 - Départ membre clé (criticité 15)**
- Cause : Équipe étudiante, risques stage/emploi/abandon
- Impact : Perte de compétence critique (ex: seul dev Rust, seul dev ML)
- Mitigation :
  - Chaque composant documenté par au moins 2 personnes
  - Code reviews obligatoires croisées
  - Wiki technique maintenu à jour (Notion/Confluence)
  - Pas de secrets/accès personnels (tout centralisé dans variables d'environnement partagées)

**Risque RGPD - Données biométriques (criticité 15)**
- Cause : Vidéos corporelles = données biométriques (RGPD Article 9 - données sensibles)
- Impact : Amende CNIL jusqu'à 4% du CA, obligation de notification sous 72h en cas de breach
- Mitigation :
  - Consentement explicite granulaire (vidéo, analyse, amélioration modèle = 3 consentements séparés)
  - Données stockées en EU uniquement (Hetzner Allemagne/Finlande)
  - Droit à l'effacement : suppression vidéo + analyse + landmarks en cascade (PostgreSQL ON DELETE CASCADE)
  - Politique de rétention : vidéos supprimées après 90 jours par défaut (sauf consentement)
  - Chiffrement AES-256 au repos sur S3

---

## 2. Environmental Impact (GreenIT)

### Choix d'hébergement - Empreinte carbone datacenter

**Hetzner Falkenstein (Allemagne) - Datacenter retenu**

| Critère                         | Valeur                                 | Source                             |
| ------------------------------- | -------------------------------------- | ---------------------------------- |
| PUE (Power Usage Effectiveness) | 1.3                                    | Hetzner transparency report        |
| Énergie renouvelable            | 100% (énergie verte certifiée)         | Hetzner Green Energy               |
| Localisation                    | Falkenstein, Allemagne                 | Zone EU à faible intensité carbone |
| Intensité carbone réseau DE     | ~350 gCO2/kWh                          | Our World in Data 2024             |
| Certification                   | ISO 14001 (management environnemental) | Hetzner                            |

**Pourquoi Hetzner > AWS pour le GreenIT :**
- AWS Ireland (eu-west-1) : PUE ~1.2 mais mix énergétique partiel renouvelable selon période
- Hetzner : 100% énergie renouvelable garantie contractuellement

---

### Principes d'éco-conception appliqués

| Principe                  | Choix technique                                                                                                     | Impact estimé                                      |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| **Client-side rendering** | L'overlay squelette est rendu localement sur Flutter (CustomPainter), aucune vidéo re-encodée côté serveur          | -50 MB bande passante + 30s CPU par vidéo          |
| **Transfert de données**  | Retour JSON (~50 KB) au lieu d'une vidéo traitée (~50 MB)                                                           | Réduction de 99.9% du poids de la réponse          |
| **Compression vidéo**     | Compression vidéo côté mobile avant upload (H.264, CRF 28), chunks de 5 MB                                          | Réduction ~60% du poids moyen des fichiers         |
| **Lifecycle S3**          | Suppression automatique des vidéos non sauvegardées après 7 jours (MinIO policy)                                    | Réduction du stockage inutile                      |
| **Asynchronisme**         | Traitement IA différé via RabbitMQ : les workers s'arrêtent si la queue est vide                                    | Pas de CPU gaspillé en attente active              |
| **Algorithme optimisé**   | Résultats JSON réutilisés entre les étapes (skeleton → advice → ghost) : la vidéo n'est traitée qu'une seule fois | -2 passes GPU par analyse                          |
| **Données en EU**         | Serveurs Hetzner Allemagne uniquement → pas de transfert transatlantique                                           | Latence réseau réduite + empreinte transit réduite |

---

### Estimation empreinte carbone infrastructure

**Hypothèses** : 3 VPS Hetzner (Srv-API CX31 + Srv-DB CX41 + Srv-ML CX51) — mix 100% renouvelable

| Serveur        | Puissance estimée | Heures/an |  kWh/an   | gCO2eq/an (350g/kWh DE) |
| -------------- | :---------------: | :-------: | :-------: | :---------------------: |
| Srv-API (CX31) |       ~30 W       |   8 760   |    263    |         ~92 kg          |
| Srv-DB (CX41)  |       ~50 W       |   8 760   |    438    |         ~153 kg         |
| Srv-ML (CX51)  |       ~80 W       |   8 760   |    701    |         ~245 kg         |
| **Total**      |                   |           | **1 402** |  **~490 kg CO2eq/an**   |

> ⚠️ Avec 100% énergie renouvelable Hetzner, l'intensité carbone effective tend vers 0 gCO2/kWh. L'estimation ci-dessus représente le **pire cas** (mix réseau DE résiduel).

**Comparaison** : une solution équivalente sur AWS EC2 (eu-west-1, mix ~60% renouvelable) produirait environ **2× à 3× plus** d'émissions.

---

## 3. Deployment & Resilience

### CI/CD — Automatisation des tests et déploiements

Le pipeline CI/CD repose sur **GitHub Actions** + **moonrepo** (monorepo task runner). Moonrepo permet des builds **affected-only** : seuls les projets modifiés sont compilés et testés.

```
main branch ──► Tag v* ──► GitHub Actions: build + push Docker images ──► Deploy Hetzner
dev branch  ──► PR     ──► GitHub Actions: tests + lint (affected only)
```

**CI — `.github/workflows/ci.yml`** (déclenché sur chaque PR) :

```yaml
jobs:
  ci:
    steps:
      - name: Install moon
        run: curl -fsSL https://moonrepo.dev/install/moon.sh | bash
      - name: Run affected tests
        run: moon run :test --affected
      - name: Run affected lint
        run: moon run :lint --affected
```

**CD — `.github/workflows/deploy-production.yml`** (déclenché sur tag `v*`) :

```yaml
jobs:
  build-and-deploy:
    steps:
      - name: Build & push API image
        run: docker build -t registry/ascension-api:${{ github.ref_name }} ./apps/server
      - name: Build & push Worker image
        run: docker build -t registry/ascension-worker:${{ github.ref_name }} ./apps/ai
      - name: Deploy to Hetzner (SSH)
        run: |
          docker-compose up -d --no-deps api worker
          docker-compose exec -T api sqlx migrate run
      - name: Health check
        run: curl -f http://localhost:8080/health || exit 1
```

---

### Stratégie de migration (schema évolutif)

Les migrations de base de données sont gérées via **SQLx migrate** (fichiers `.sql` versionnés dans `migrations/`). Le déploiement applique automatiquement les migrations avant de redémarrer les services.

| Version | Action                                    | Stratégie                                               |
| ------- | ----------------------------------------- | ------------------------------------------------------- |
| V1.0    | Schéma initial                            | `CREATE TABLE` initial                                  |
| V1.1    | Ajout colonne `subscription_tier`         | `ALTER TABLE users ADD COLUMN` avec valeur par défaut   |
| V1.2    | Changement type JSONB → table normalisée  | Migration additive : nouvelle table + backfill + switch |
| V2.0    | Breaking change                           | Feature flag + double écriture pendant transition       |

**Principe** : toutes les migrations sont **rétrocompatibles** (additive-first). Un rollback de l'API ne casse jamais le schéma DB.

---

### SPOF — Single Points of Failure identifiés

| Composant                     |   SPOF ?   | Mitigation                                                                                      |
| ----------------------------- | :--------: | ----------------------------------------------------------------------------------------------- |
| **Rust API** (Srv-API)        | ⚠️ Partiel | 2 instances derrière Nginx load balancer (`least_conn`) — si les 2 tombent : KO                 |
| **PostgreSQL** (Srv-DB)       | ⚠️ Partiel | Read replica + failover manuel (promotion replica) ; WAL archiving RPO < 15 min                 |
| **RabbitMQ** (Srv-DB)         | ⚠️ Partiel | Queue durable persistante : les messages survivent au redémarrage ; clustering prévu en phase 2 |
| **AI Workers** (Srv-ML)       |   ✅ Non    | 2 workers actifs ; si 1 tombe, le job reste en queue et est consommé par l'autre                |
| **MinIO / Object Storage**    |   ✅ Non    | Hetzner Volume redondant ; données sauvegardées sur Hetzner Storage Box                         |
| **Cloudflare**                |   ✅ Non    | SLA 100% uptime ; multi-PoP mondial                                                             |
| **Hetzner datacenter entier** |  ⚠️ Rare   | SLA 99.9% ; procédure de bascule documentée (nouveau VPS + restore backup < 2h)                 |

> **Mode dégradé** : si les workers ML tombent complètement, l'upload vidéo reste fonctionnel. L'utilisateur voit un statut "En cours d'analyse" et reçoit une notification push dès que les workers sont de retour. Le reste de l'app (profil, historique, routines d'entraînement) fonctionne normalement.

---

### Politique de sauvegarde (Backup Policy)

#### PostgreSQL

| Type                 |   Fréquence    | Rétention | Outil                        |
| -------------------- | :------------: | :-------: | ---------------------------- |
| Dump complet         | Quotidien (3h) |  7 jours  | `pg_dump` + gzip + cron      |
| WAL archiving        |    Continu     |  7 jours  | `pg_receivewal` / pgBackRest |
| Test de restauration |    Mensuel     |     —     | Restore sur VPS de staging   |

- **RPO** (Recovery Point Objective) : < 15 minutes
- **RTO** (Recovery Time Objective) : < 2 heures

#### MinIO / Vidéos

| Type             | Fréquence | Rétention | Outil                                        |
| ---------------- | :-------: | :-------: | -------------------------------------------- |
| Sync bucket      | Quotidien | 30 jours  | `mc mirror` → Hetzner Storage Box            |
| Lifecycle policy |   Auto    |  7 jours  | Suppression auto des uploads non sauvegardés |

#### Procédure de restauration (Full Server Failure)

```
1. Provisionner nouveau VPS Hetzner (~5 min)
2. Installer Docker + Docker Compose (~5 min)
3. Pull images Docker depuis registry (~5 min)
4. Restaurer .env depuis stockage sécurisé (~2 min)
5. Restaurer PostgreSQL depuis dernier backup (~20 min)
6. Rejouer WAL logs pour point-in-time recovery (~10 min)
7. Démarrer services : docker-compose up -d (~3 min)
8. Vérifier health check : curl /health (~1 min)
─────────────────────────────────────────────
Total RTO estimé : < 1 heure
```

---

### Plan de scalabilité (Roadmap Infrastructure)

| Phase        | Utilisateurs   | Infrastructure                               | Coût estimé/mois |
| ------------ | :------------: | -------------------------------------------- | :--------------: |
| **Phase 1**  | 0 – 5 000      | 3 VPS Hetzner + Docker Compose               | ~60 €            |
| **Phase 2**  | 5 000 – 20 000 | Multi-VPS + Nginx LB + PG Read Replica       | ~200 €           |
| **Phase 3**  | 20 000 – 100 000 | K3s Kubernetes + HPA workers               | ~600 €           |
| **Phase 4**  | 100 000+       | Full K8s + CDN + auto-scaling GPU workers    | ~2 000 €+        |

**Déclencheurs de scaling automatique** :
- API : CPU > 70% ou file de requêtes > 100
- Workers ML : profondeur de queue RabbitMQ > 50 jobs
- Base de données : saturation du pool de connexions
