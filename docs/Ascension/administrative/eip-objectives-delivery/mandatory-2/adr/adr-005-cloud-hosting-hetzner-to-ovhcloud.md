---
id: 08a48135-bf64-4076-b570-a9bef453acc7
---

:::success
**Version:** 1.0
:::

---

# ADR-005 : Transition de l'hébergement cloud de Hetzner vers OVHcloud (VPS-4 + S3)

- **Date :** 2026-10-15
- **Statut :** Accepté *(Révision de la décision initiale de mars 2026)*
- **Périmètre :** Infrastructure / Déploiement / CI-CD
- **Références :** [Cloud Hosting Benchmark](../../../../developer/architecture/benchmark/cloud-hosting.md), [Infrastructure Architecture](../../../../developer/architecture/infrastructure.md), [Infrastructure Needs](../../../infrastructure-needs.md)

---

## 1. Contexte et problème

L'infrastructure serveur d'Ascension doit héberger cinq services cœur (API Gateway Go, PostgreSQL 18, RabbitMQ 4.x, workers IA Python et reverse proxy TLS) ainsi que les outils d'ingénierie (Jenkins, SonarQube, n8n), tout en servant des flux vidéo volumineux vers les mobiles.

À l'issue du benchmark cloud initial (mars 2026), l'équipe avait sélectionné **Hetzner Cloud** pour son rapport prix/performance exceptionnel (~15 €/mois pour 4 vCPU / 8 Go RAM, 20 To de trafic sortant inclus) et sa souveraineté européenne.

Lors de la phase d'allocation des ressources cloud EIP à l'automne 2026, **Epitech** a imposé une contrainte institutionnelle : le budget d'hébergement alloué aux projets étudiants doit être consommé exclusivement sur le catalogue **OVHcloud**. L'équipe a donc dû réviser son choix d'hébergeur et concevoir une topologie adaptée au catalogue OVHcloud sans sacrifier la maîtrise des coûts ni la conformité RGPD.

---

## 2. Options envisagées

| Critère | Hetzner Cloud (DE/FI) *(choix initial)* | OVHcloud (FR/EU) | AWS (Francfort / Irlande) |
| --- | --- | --- | --- |
| **VM 4 vCPU / 8 Go RAM** | ~15 €/mois | ~22 €/mois | ~60 €/mois |
| **VM 8 vCPU / 16+ Go RAM** | ~45 €/mois | ~65 €/mois (ou VPS-4 24 Go RAM) | ~180 €/mois |
| **Trafic sortant (*egress*)** | 20 To inclus (~1 €/To au-delà) | Bande passante illimitée (*unmetered*) | 100 Go gratuits puis ~90 €/To |
| **Souveraineté & RGPD** | UE, hors US CLOUD Act | UE, hors US CLOUD Act | UE, mais soumis au US CLOUD Act |
| **Éligibilité budget EIP Epitech** | Non (autofinancement requis) | **Oui (pris en charge)** | Non |
| **Ergonomie de gestion** | Moderne et minimaliste | Interface classique, plus verbeuse | Complexe (IAM, grille tarifaire) |

Au sein du catalogue OVHcloud, deux topologies ont également été comparées :

1. **Tout-en-un sur VPS unique** (stockage vidéo local sur les 200 Go NVMe du VPS).
2. **Architecture découplée** : 1 serveur de calcul **OVHcloud VPS-4** + stockage média externalisé sur **OVHcloud Object Storage Standard**.

---

## 3. Option choisie

Transition complète vers **OVHcloud** avec une topologie découplée :

- **Calcul et services :** **OVHcloud VPS-4** (8 vCores, 24 Go RAM, 200 Go SSD NVMe, 3 Gbps illimité, datacenter de Milan — `IT-MIL`), administré via **Coolify**, hébergeant l'API Go, les workers IA, PostgreSQL 18, RabbitMQ et la stack CI/CD (Jenkins, SonarQube, n8n).
- **Stockage média :** **OVHcloud Object Storage Standard** (datacenter de Gravelines — `GRA`) pour les vidéos et photos de voies.
- **Domaine & TLS :** `ascension-eip.fr` avec DNS Anycast, DNSSEC et certificats Let's Encrypt automatisés.

---

## 4. Raison (ce qui a fait changer l'équipe d'avis)

1. **Contrainte budgétaire et institutionnelle Epitech :** utiliser le catalogue OVHcloud permet de financer l'infrastructure sur le budget EIP de l'école tout en conservant une machine nettement plus capacitaire (24 Go de RAM, indispensables pour faire cohabiter les workers IA, PostgreSQL, Jenkins et SonarQube).
2. **Préservation des invariants du benchmark initial :** OVHcloud respecte les trois exigences non négociables établies dès mars 2026 : souveraineté européenne stricte (immunité face au US CLOUD Act), conformité RGPD pour les données biométriques, et absence de piège tarifaire sur l'*egress* vidéo (contrairement à AWS).
3. **Découplage calcul / stockage :** externaliser les vidéos sur OVHcloud Object Storage Standard évite la saturation rapide du disque NVMe de 200 Go du VPS-4 et supprime le besoin d'un second VPS dédié au stockage.

---

## 5. Conséquences acceptées

- **Point de défaillance unique (SPOF) sur le nœud de calcul :** héberger l'API, PostgreSQL, RabbitMQ, les workers IA et la CI/CD sur un seul VPS-4 expose l'ensemble des services en cas d'incident machine ou de saturation CPU/RAM par un job Jenkins ou un pic d'inférence IA. Cette limite est assumée pour la phase EIP et impose des limites de ressources Docker strictes ainsi que des sauvegardes externalisées régulières.
- **Latence inter-datacenters (`IT-MIL` ↔ `GRA`) :** le VPS de calcul (Milan) et le stockage objet (Gravelines) ne sont pas dans le même datacenter, ajoutant quelques millisecondes de latence réseau lors du téléchargement des vidéos par les workers IA (négligeable devant les 10 à 60 s d'inférence).
- **Coût supérieur hors subvention école :** à ressources équivalentes, OVHcloud reste environ 30 à 45 % plus cher que Hetzner en autofinancement ; la portabilité via Docker/Coolify et le standard S3 est maintenue pour permettre un changement d'hébergeur sans réécriture applicative après l'EIP.
