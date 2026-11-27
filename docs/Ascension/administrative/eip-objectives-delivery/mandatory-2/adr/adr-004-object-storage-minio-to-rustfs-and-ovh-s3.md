---
id: 80020647-8de2-459b-a847-0e340d712867
---

:::success
**Version:** 1.0
:::

---

# ADR-004 : Remplacement de MinIO par RustFS (dev) et OVHcloud Object Storage (prod)

- **Date :** 2026-09-24
- **Statut :** Accepté *(Révision de la décision initiale de mars 2026)*
- **Périmètre :** Infrastructure / Stockage objet / Backend (`apps/server`) / IA (`apps/ai`)
- **Références :** [MinIO Deprecation Audit](../../../../developer/architecture/audits/minio-deprecation.md), [Object Storage Benchmark](../../../../developer/architecture/benchmark/object-storage.md), commit `f5c79569`

---

## 1. Contexte et problème

Pour éviter que l'API Go ne serve de proxy pour des vidéos d'escalade volumineuses (50 Mo à 2 Go), Ascension applique le pattern **Edge Upload & Rendering** : le mobile Flutter obtient une URL S3 présignée (`PUT`) auprès de l'API, téléverse la vidéo directement vers le stockage objet, puis les workers IA Python la récupèrent (`GET`) pour l'analyse.

En mars 2026, **MinIO Community Edition** avait été retenu pour sa compatibilité stricte avec l'API Amazon S3 (*Simple Storage Service*) et sa simplicité de déploiement en Docker.

Lors de la reprise du projet en septembre 2026, un audit de sécurité et de maintenance a révélé que le dépôt officiel `minio/minio` avait été **archivé le 25 avril 2026** par son éditeur au profit d'offres commerciales fermées (MinIO Enterprise / AIStor). Conserver MinIO exposait directement Ascension à :

- l'absence définitive de correctifs de sécurité (risque critique sur un service exposé publiquement pour les URLs présignées, alors que MinIO a déjà connu des CVE critiques telles que `CVE-2023-28432`, score 9.8) ;
- une non-conformité **RGPD (Article 32)** vis-à-vis de la sécurisation de données biométriques et vidéos identifiables selon « l'état de l'art » ;
- une dérive progressive de compatibilité avec les SDK AWS S3 modernes (Go, Python `boto3`, Dart) ;
- les contraintes de la licence copyleft **AGPLv3** dans un cadre SaaS commercial.

---

## 2. Options envisagées

| Critère | Statu quo (MinIO figé) / Fork (Silo) | RustFS | Garage | SeaweedFS | Ceph (RGW) |
| --- | --- | --- | --- | --- | --- |
| **Maintenance active (2026)** | Nulle (MinIO) / Fragile et jeune (Silo) | Très active | Active | Active | Très active |
| **Licence** | AGPLv3 | **Apache-2.0** | AGPLv3 | Apache-2.0 | LGPL |
| **Flux vidéo séquentiel** | Bon (mais non maintenu) | **Élevé (streaming natif)** | Modéré | Surcoût de réassemblage | Élevé |
| **Empreinte RAM de base** | Faible | **150 – 300 Mo** | 100 – 250 Mo | 200 – 400 Mo | 2 – 4+ Go par démon |
| **Complexité opérationnelle** | Faible | **Faible (1 conteneur)** | Faible | Moyenne (Master/Volume/Filer) | Très élevée (MON/OSD/RGW) |
| **Fidélité S3 Signature V4** | Risque de dérive | **Stricte et complète** | Bonne (écarts mineurs) | Dépendante du Filer | Stricte et complète |

Pour l'environnement de **production**, l'alternative d'un stockage auto-hébergé sur le disque NVMe du serveur applicatif (200 Go) a également été comparée à un stockage objet managé européen compatible S3 (**OVHcloud Object Storage Standard**).

---

## 3. Option choisie

- **Développement local et CI :** migration complète vers **RustFS** (déployé en conteneur Docker dans `docker-compose.yml`).
- **Production :** délégation du stockage média vers **OVHcloud Object Storage Standard** (datacenter de Gravelines, France — `GRA`), compatible S3.
- **Suppression complète de MinIO** de tous les dépôts, configurations et pipelines.

---

## 4. Raison (ce qui a fait changer l'équipe d'avis)

1. **Veto sécurité et conformité RGPD :** exploiter en production un composant publiquement abandonné et privé de patchs de sécurité sur des vidéos personnelles était inacceptable.
2. **Adéquation technique de RustFS en local :** écrit en Rust, distribué sous licence permissive **Apache-2.0**, léger en RAM (150 – 300 Mo) et conçu pour des flux séquentiels lourds, RustFS évite à la fois la lourdeur opérationnelle de Ceph et les contraintes AGPLv3 de Garage/Silo.
3. **Élasticité en production sans surcoût de bande passante :** OVHcloud Object Storage Standard offre un stockage élastique (~0,01 €/Go/mois), un trafic entrant/sortant gratuit, une souveraineté française/européenne et évite de saturer les 200 Go NVMe du VPS de calcul.
4. **Parité stricte grâce au standard S3 :** l'API Go et les workers Python utilisent uniquement des clients S3 standards ; le passage de RustFS (dev) à OVHcloud S3 (prod) ne nécessite aucun changement de code applicatif, uniquement les variables d'environnement.

---

## 5. Conséquences acceptées

- **Maturité plus récente de RustFS :** projet plus jeune que Ceph ou l'historique MinIO ; son usage est volontairement cantonné au développement local et aux tests automatisés, tandis que la production repose sur le stockage managé OVHcloud.
- **Double configuration à maintenir :** les variables d'environnement S3 (endpoint, région, style de chemin *path-style* vs *virtual-host*, clés d'accès) doivent être testées sur les deux cibles pour garantir l'absence d'écart de comportement entre dev et prod.
- **Dépendance au fournisseur OVHcloud en production :** même si le protocole S3 garantit la portabilité applicative, une migration future de la production impliquerait un transfert physique des vidéos stockées.
