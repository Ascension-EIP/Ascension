---
id: a521a93c-f811-4150-a388-1a7238a7242c
---

:::warning
**Version:** 0.2
:::

---

# Worker IA

Le worker IA (`apps/ai`, Python 3.11, géré par `uv`) fait le travail lourd hors de l'API : il récupère la vidéo d'un grimpeur, calcule l'analyse 2D et produit des conseils. Il ne parle jamais directement au mobile. Il consomme des jobs RabbitMQ, lit la vidéo dans RustFS (S3), écrit sa progression et ses résultats dans PostgreSQL, et publie ses statuts sur RabbitMQ.

Aujourd'hui, seul le pipeline vidéo 2D existe : lecture de voie (photo), pathfinding, mode fantôme et 3D ne sont pas implémentés. Le détail des briques, des seuils et de leurs limites est dans [pipeline-2d-decomposition.md](./pipeline-2d-decomposition.md). L'installation, les variables d'environnement, les commandes et les tests sont dans le [README du worker](../../../../../apps/ai/README.md).

---

## Ce que fait le worker

| Étape | Queue | Entrée | Sortie |
| --- | --- | --- | --- |
| Détection de pose | `poses.detect` | `pose.detect.requested` : `{job_id, object_key}` | `analyses.result` (squelette filtré, angles, vitesses, métriques, mouvements, pauses) |
| Conseils | `poses.advice` | `pose.detect.completed` ou `pose.advice.requested` : `{job_id}` | `analyses.hints` (conseils structurés, en français) |

- L'exchange est `events` (topic). Les jobs en échec définitif partent dans `<queue>.dlq`.
- `job_id` est l'identifiant de la ligne `analyses`. Le bucket est une valeur de configuration, pas une donnée du message.
- Statuts : `pending` (créé par le serveur), `started` (pris par le worker), `running`, `success`, `failed`. `success` n'est posé qu'après l'étape conseils.
- Si le LLM échoue ou n'est pas configuré, l'analyse finit en `success` avec `hints` vide, et `pose.advice.status` vaut `failed`. Le squelette reste utilisable.
- Un job à la fois par process. Pour monter en charge, on ajoute des réplicas.
- Le modèle de langage est interchangeable : un seul client compatible OpenAI, réglé par `LLM_BASE_URL`, `LLM_API_KEY` et `LLM_MODEL`. Il ne reçoit que des valeurs calculées, jamais la vidéo ni d'identifiant.

Chaque étape du pipeline est aussi une sous-commande (`uv run worker pose-detect`, `pose-advice`, etc.) qui fonctionne sans broker, base ni stockage.

Le serveur Go n'est pas encore branché sur ces queues : il publie encore sur l'ancienne queue `vision.skeleton`. En attendant, `apps/ai/src/producer.py` déclenche les jobs à la main.

---

## Schéma du flow IA

*Résumé : l'application envoie la vidéo directement à RustFS, puis l'API publie le job. Le worker analyse la vidéo, écrit le résultat et les conseils dans PostgreSQL et publie ses statuts. Le pipeline 2 (mode fantôme) est prévu, pas implémenté.*

```mermaid
flowchart TD
    subgraph Client ["Couche Client"]
        App["App Mobile (Flutter)"]
    end

    subgraph Gateway ["API Gateway"]
        API["Serveur API (Go/Gin)"]
    end

    subgraph Broker ["Message Broker"]
        RMQ["RabbitMQ"]
    end

    subgraph IA ["Couche Traitement IA"]
        subgraph P1 ["Pipeline 1"]
            ExtSkel["Extraction du squelette"]
            GenCons["Générateur de conseils"]
            ExtSkel -->|"Squelette extrait"| GenCons
        end

        subgraph P2 ["Pipeline 2 – Mode Fantôme"]
            ExtPrises["Détection des prises & sélection groupe/manuel"]
            RechChemin["Pathfinding selon morphologie"]
            GenFantome["Générateur d'images par étape"]
            ExtPrises -->|"Prises choisies"| RechChemin
            RechChemin -->|"Bêta réalisable"| GenFantome
        end
    end

    subgraph Data ["Couche Données et Stockage"]
        S3["Object Storage S3 (Rust<br/>FS)"]
        PG["PostgreSQL"]
    end

    %% Flux de communication (1 à 12)
    App -->|"1. Demande Presigned<br/>URL"| API
    API -->|"2. Génère Presigned URL"| S3
    App -->|"3. Upload direct (Vidéo ou<br/>Photo)"| S3
    App -->|"4. Notifie upload terminé"| API
    API -->|"5. Publie le job"| RMQ

    RMQ -->|"6a. Job d'analyse de pose<br/>(vidéo de grimpe)"| ExtSkel
    ExtSkel -->|"Récupère la vidéo"| S3
    GenCons -->|"7a. Stocke résultat et conseils (JSON)"| PG
    GenCons -->|"8a. Publie les statuts"| RMQ

    RMQ -->|"6b. Job de mode fantôme<br/>(photo de mur)"| ExtPrises
    ExtPrises -->|"Récupère la photo"| S3
    GenFantome -->|"7b. Stocke étapes & images"| PG
    GenFantome -->|"8b. Publie événement<br/>terminé"| RMQ

    RMQ -->|"9. Notifie résultat prêt"| API
    API -->|"10. Notification WebSocket"| App
    App -->|"11. Récupère l'analyse<br/>(JSON)"| API
    API -->|"12. Lit les données"| PG
```
