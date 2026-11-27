---
id: a352ce44-8906-4bed-9c23-12a687b02de4
---

:::success
**Version:** 1.0
:::

---

# ADR-002 : Choix de RabbitMQ (AMQP) pour l'orchestration asynchrone des tâches IA

- **Date :** 2026-03-02
- **Statut :** Accepté
- **Périmètre :** Architecture globale / Backend (`apps/server`) / IA (`apps/ai`)
- **Références :** [Message Broker Benchmark](../../../../developer/architecture/benchmark/message-queue.md), [Architecture Diagrams](../architecture-and-data-diagrams.md)

---

## 1. Contexte et problème

Les pipelines d'intelligence artificielle d'Ascension (extraction de 33 points clés par image via MediaPipe, calcul des métriques biomécaniques, génération de conseils LLM et calcul de trajectoire du Mode Fantôme) consomment entre **10 et 60 secondes** de calcul intensif par requête.

Ces traitements ne peuvent pas être exécutés de manière synchrone dans le cycle HTTP de l'API Gateway sans provoquer des timeouts clients et saturer le serveur. Il faut donc un courtier de messages (*message broker*) assurant :

- un découplage fiable entre l'API Gateway (producteur) et les workers Python (consommateurs) ;
- un acquittement explicite (`ACK` / `NACK`) avec remise en file automatique en cas de crash d'un worker ;
- une gestion native des messages corrompus (*poison pills*) via une *Dead Letter Queue* (DLQ) ;
- un contrôle strict de la contre-pression (*backpressure*) pour qu'un worker ne traite qu'une vidéo à la fois et n'épuise pas la mémoire RAM ou GPU.

---

## 2. Options envisagées

| Critère | RabbitMQ 4.x (AMQP) | Redis Streams / Pub-Sub | Apache Kafka | NATS JetStream |
| --- | --- | --- | --- | --- |
| **Paradigme principal** | File de tâches (*task queue*) à routage riche | Cache mémoire & journaux légers | Streaming distribué haut débit (100k+ msg/s) | Messagerie microservices ultra-légère |
| **Acquittement & reprise sur crash** | Natif (`basic_ack` / `basic_nack`) | Possible via Consumer Groups | Natif (gestion d'offsets) | Natif |
| **Dead Letter Queue (DLQ)** | Native (*Dead Letter Exchange*) | Logique applicative manuelle | Complexe à orchestrer | Basique |
| **Contrôle de contre-pression** | Natif (`basic_qos(prefetch=1)`) | Tirage manuel par le consommateur | Couplé au nombre de partitions | Pull consumers |
| **Empreinte RAM de base** | 60 – 120 Mo | 15 – 40 Mo | 500 Mo – 1,5 Go (JVM) | 20 – 50 Mo |
| **Complexité de déploiement** | Faible (1 conteneur Docker) | Faible (1 conteneur) | Élevée (clustering, partitions, rétention) | Faible (binaire unique) |

---

## 3. Option choisie

**RabbitMQ 4.x** via le protocole **AMQP 0-9-1** (*Advanced Message Queuing Protocol*), interfacé avec `amqp091-go` côté API Go et `pika` côté workers Python.

---

## 4. Raison

1. **Adéquation exacte avec une charge de tâches lourdes :** Ascension traite des volumes modérés de messages (centaines à milliers de tâches par jour) mais à très forte valeur et coût unitaire élevé. Kafka est surdimensionné (empreinte mémoire JVM élevée et complexité opérationnelle inutile) pour ce profil.
2. **Protection matérielle native (`prefetch_count=1`) :** le mécanisme `basic_qos` garantit qu'un worker IA ne reçoit jamais une deuxième vidéo avant d'avoir explicitement acquitté la première, évitant les plantages par manque de mémoire (*Out-Of-Memory*) lors des pics d'upload.
3. **Gestion native des échecs (DLX / DLQ) :** une vidéo corrompue ou un codec illisible est automatiquement isolé dans une file dédiée sans bloquer les autres analyses, permettant à l'API d'informer proprement l'utilisateur.
4. **Écosystème mature :** l'interface de management intégrée facilite le débogage et le suivi des files, et les bibliothèques `amqp091-go` et `pika` sont éprouvées.

---

## 5. Conséquences acceptées

- **Montée en compétence initiale :** aucun membre de l'équipe n'avait d'expérience préalable sur AMQP/RabbitMQ, nécessitant un temps d'apprentissage sur les échanges (*exchanges*), les clés de routage, les files durables et les *heartbeats*.
- **Gestion explicite des reconnexions et timeouts :** les traitements IA pouvant durer plusieurs dizaines de secondes, les paramètres de *heartbeat* et de *consumer timeout* doivent être calibrés avec soin (notamment avec `pika` en Python) pour éviter des déconnexions intempestives en cours d'inférence.
- **Composant critique supplémentaire :** RabbitMQ devient un point de passage obligé entre l'API et l'IA ; son indisponibilité bloque le déclenchement de nouvelles analyses et impose des tests d'intégration dédiés ainsi qu'une supervision dédiée.
