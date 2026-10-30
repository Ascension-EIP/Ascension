---
id: 0a818f56-53cb-4ef7-b6fa-2b8691b69962
---

### **État des lieux actuel : où en est-on ?**

Il y a actuellement une **désynchronisation majeure** suite au début de refonte du worker IA (`apps/ai` par rapport à l'ancienne version `apps/old_ai`). En l'état, **le backend et le nouveau worker IA ne peuvent pas communiquer.**

**Côté Backend (`apps/server` en Go)**

Le backend est encore branché sur les conventions de l'ancien worker (`apps/old_ai`) :

1. **Configuration RabbitMQ** (**`config.go`**) :
   - `QueueAI` : `"vision.skeleton"` (par défaut)
   - `QueueServer` : `"`[`ascension.events`](http://ascension.events)`"` (topic exchange)
2. **Émission** (**`analysis.go`**) :
   - Lors de la création d'une analyse, le serveur publie directement dans la file d'attente brute `vision.skeleton` (exchange par défaut `""`) un JSON :

     ```
     json
     ```

     { "analysis\_id": "<uuid>", "video\_url": "s3://bucket/..." }
   - Un commentaire explicite y figure d'ailleurs : `// TODO change this with gianni new crosslanguage generated dto`.
3. **Réception / Consommateur** :
   - **Aucun consommateur RabbitMQ n'existe côté serveur Go.**
   - Dans l'ancien système, le worker Python écrivait directement dans la base PostgreSQL via `psycopg2` pour mettre à jour le statut (`processing`, `completed`) et le résultat JSON. Le serveur Go ne consommait aucun message en retour.

---

**Côté IA (`apps/ai` en Python)**

La refonte entamée dans `apps/ai` a posé les bases d'un pipeline événementiel par étapes, mais **le chantier est incomplet et présente plusieurs ruptures** :

1. **Topologie RabbitMQ divergente** ([**`macro.py`**](http://macro.py) et [**`rabbitmq.py`**](http://rabbitmq.py)) :
   - L'IA déclare et écoute un topic exchange nommé `"events"` (alors que le serveur attend `"`[`ascension.events`](http://ascension.events)`"`).
   - Les files créées sont `poses.detect` et `poses.advice`, associées aux routing keys `pose.detect.requested`, `pose.detect.completed` et `pose.advice.requested`.
   - **Conséquence** : Les messages envoyés par le serveur Go dans `"vision.skeleton"` ne sont jamais reçus par `apps/ai`.
2. **Format de charge utile (DTO) incompatible** :
   - Le handler **`pose_detect_`**[**`request.py`**](http://request.py) attend `payload.get("job_id")`, alors que le Go envoie `analysis_id`.
3. **Logique non connectée & TODOs** :
   - Le handler contient plusieurs TODOs critiques :
     - `# TODO: créer le schema pour la payload que je suis censé recevoir`
     - `# TODO: avoir le lien s3 et download temporairement la vidéo pour la process`
     - `# TODO: mettre dans la db les résultats...`
4. **Bugs de code dans `apps/ai` bloquants au runtime** :
   - Dans **`pose_detect_`**[**`request.py`**](http://request.py) : `JobStatus(job_id=..., status=JobStatus.PENDING)` lève une exception (c'est `Status.PENDING`, `JobStatus` étant le modèle Pydantic).
   - `pose_skeleton.process()` est appelé sans argument, alors que la méthode exige `video_path: str`.

---

### **Mon avis sur l'architecture et la direction prise**

**Les points positifs de la refonte**

- **Séparation en sous-tâches (`poses.detect` -> `poses.advice`)** : C'est une excellente décision. Découpler la détection de pose (lourde en calcul CV / MediaPipe) de la génération de conseil (appel LLM / Gemini) permet :
  - D'éviter de bloquer ou d'échouer l'analyse complète si l'API externe de conseil tombe.
  - De paralléliser et de scaler indépendamment les workers GPU/CPU pour la vision et les workers I/O pour les conseils.
- **Passage à un Topic Exchange avec Routing Keys** : C'est bien plus propre et évolutif que des files directes codées en dur comme dans `old_ai`.

**Les faiblesses actuelles**

1. **L'absence de boucle de retour côté serveur Go** :
   - Faire écrire les workers IA directement en base PostgreSQL (`analyses`) brise l'isolation des responsabilités et couple fortement le schéma SQL interne du backend au code Python.
   - Le serveur Go devrait être le seul maître de la table `analyses` et écouter les événements de progression/statut (`pose.*.status` ou `pose.*.completed`) émis par RabbitMQ pour mettre à jour la base et notifier les clients (WebSocket).
2. **Absence de contrat d'interface partagé** :
   - Le manque de synchronisation entre Go et Python sur les noms de clés (`analysis_id` vs `job_id`, statuts `completed` vs `success`, etc.) fragilise l'intégration.
