---
id: 278636a7-ef36-464d-83b7-b9eeb6602f96
---

:::success
**Version:** 1.1
:::

# Schémas et diagrammes de l'architecture et des données

---

## 1. Schéma d'architecture globale du système

Ce diagramme présente l'architecture événementielle d'Ascension : l'application mobile Flutter dialogue avec l'API Gateway Go/Gin en REST (upload direct vers S3 via URL présignée, soumission asynchrone via RabbitMQ et récupération des résultats par polling), tandis qu'un worker IA Python unique traite les 4 files de tâches (`poses.detect`, `poses.advice`, `holds.detect`, `pathfinding.compute`) et persiste les résultats dans PostgreSQL.

```mermaid
graph TD
    subgraph Client ["📱 Couche Client"]
        MobileApp["Application Mobile Flutter"]
    end

    subgraph API ["🛡️ API Gateway (Go / Gin)"]
        APIServer["Serveur API REST"]
        AuthService["Authentification JWT, Rate Limit & Quotas"]
        CronJob["Worker Cron<br/>(Nettoyage sessions & vidéos expirées)"]
    end

    subgraph Storage ["🗄️ Données & Stockage"]
        ObjectStorage["Stockage Objets S3<br/>(RustFS en dev / OVHcloud en prod)"]
        Database[("Base de Données PostgreSQL 18<br/>Tables relationnelles + JSONB")]
        MessageQueue["Message Broker<br/>RabbitMQ 4.4.0"]
    end

    subgraph AI ["🤖 Worker IA (Python)"]
        direction TB
        subgraph Vision ["Pipeline 1 : Analyse de pose & Conseils"]
            Skel["Extraction squelette MediaPipe<br/>& métriques biomécaniques"]
            Adv["Conseils coach LLM"]
        end
        subgraph Ghost ["Pipeline 2 : Mode Fantôme"]
            Holds["Détection prises (YOLO26-seg ONNX)<br/>+ couleur CIELAB + plan du mur (MoGe-2)"]
            Path["Pathfinding A* morphologique<br/>& calcul des postures par étape"]
        end
    end

    MobileApp -->|"1. Demande URL d'upload"| APIServer
    APIServer -->|"2. Génère URL présignée PUT"| ObjectStorage
    MobileApp -->|"3. Téléversement binaire direct"| ObjectStorage
    MobileApp -->|"4. Confirmation upload terminé"| APIServer

    APIServer -->|"5. Publication tâche AMQP"| MessageQueue
    MessageQueue -->|"6a. poses.detect"| Skel
    MessageQueue -->|"6b. poses.advice"| Adv
    MessageQueue -->|"6c. holds.detect"| Holds
    MessageQueue -->|"6d. pathfinding.compute"| Path

    Skel -->|"Lecture vidéo"| ObjectStorage
    Holds -->|"Lecture photo"| ObjectStorage

    Skel -->|"7a. Sauvegarde analyses.result"| Database
    Adv -->|"7b. Lecture result / écriture advices.result"| Database
    Holds -->|"7c. Sauvegarde holds & routes.wall_plane"| Database
    Path -->|"7d. Lecture route / écriture pathfindings.result"| Database

    Skel -->|"8a. Statut pose.detect.status"| MessageQueue
    Adv -->|"8b. Statut pose.advice.status"| MessageQueue
    Holds -->|"8c. Statut holds.detect.status"| MessageQueue
    Path -->|"8d. Statut pathfinding.compute.status"| MessageQueue

    CronJob -->|"Purge périodique"| Database
    CronJob -->|"Purge objets expirés"| ObjectStorage

    MobileApp -->|"9. Polling résultats (JSON)"| APIServer
    APIServer -->|"10. Lecture des résultats"| Database
```

---

## 2. Diagramme de séquence de bout en bout pour l'analyse de pose et les conseils

Ce diagramme détaille le cycle complet d'une vidéo de grimpe : upload direct sur S3, lancement asynchrone de l'analyse de pose (`POST /v1/analysis`), génération découplée des conseils personnalisés (`POST /v1/advices/:id` via Gemini) et rendu local (*edge rendering*) sur l'application Flutter.

```mermaid
sequenceDiagram
    autonumber
    participant User as 👤 Grimpeur
    participant App as 📱 Flutter Mobile
    participant API as 🛡️ API Gateway Go
    participant S3 as 📦 S3 (RustFS / OVHcloud)
    participant RMQ as 📨 RabbitMQ
    participant Worker as 🤖 Worker IA Python
    participant DB as 🗄️ PostgreSQL

    User->>App: Enregistre une vidéo de grimpe (10–45 s)
    App->>App: Mise en cache local du fichier MP4

    Note over App,API: Phase 1 : Négociation & Upload direct
    App->>API: POST /v1/videos/upload-url { content_type, size_bytes, ... }
    API->>S3: Génération URL présignée PUT (expiration 15 min)
    S3-->>API: URL présignée retournée
    API-->>App: 200 OK { video_id, upload_url }

    App->>S3: PUT /videos/{video_id}.mp4 (Upload binaire direct)
    S3-->>App: 200 OK (Upload réussi)
    App->>API: PUT /v1/videos/upload-done/{video_id}
    API-->>App: 204 No Content

    Note over App,RMQ: Phase 2 : Soumission asynchrone de l'analyse de pose
    App->>API: POST /v1/analysis { video_id }
    API->>DB: INSERT INTO analyses (status='pending')
    API->>RMQ: Publie 'pose.detect.requested' { job_id, object_key }
    API-->>App: 202 Accepted { analysis_id }

    Note over RMQ,Worker: Phase 3 : Traitement IA — Analyse de pose
    RMQ->>Worker: Message consommé depuis 'poses.detect'
    Worker->>DB: UPDATE analyses SET status='started', progress=0
    Worker->>RMQ: Publie 'pose.detect.status' (started / running)
    Worker->>S3: Téléchargement du flux MP4 temporaire
    Worker->>Worker: MediaPipe Pose : 33 keypoints, filtrage, métriques & mouvements
    Worker->>DB: UPDATE analyses SET result=JSONB, status='success', progress=100
    Worker->>RMQ: Publie 'pose.detect.status' (success)

    Note over App,Worker: Phase 4 : Génération des conseils LLM (job découplé)
    App->>API: POST /v1/advices/{video_id}
    API->>DB: INSERT INTO advices (id=video_id, status='pending')
    API->>RMQ: Publie 'pose.advice.requested' { job_id: video_id }
    API-->>App: 202 Accepted

    RMQ->>Worker: Message consommé depuis 'poses.advice'
    Worker->>DB: Lecture du dernier analyses.result de la vidéo
    Worker->>Worker: LLM : conseils personnalisés
    Worker->>DB: UPDATE advices SET result=JSONB, status='success', progress=100
    Worker->>RMQ: Publie 'pose.advice.status' (success)

    Note over API,App: Phase 5 : Polling & Edge Rendering
    App->>API: Polling GET /v1/analysis/{analysis_id} & GET /v1/advices/{video_id}
    API->>DB: SELECT result FROM analyses / advices
    DB-->>API: Données JSONB
    API-->>App: 200 OK avec payload biomécanique & conseils
    App->>App: CustomPainter dessine le squelette et les conseils sur la vidéo locale
    App->>User: Affichage interactif avec curseur temporel
```

---

## 3. Schéma d'hébergement et d'infrastructure cloud

Ce schéma illustre le déploiement de production sur OVHcloud : un VPS-4 à Milan administré par Coolify et exposé via Traefik, hébergeant les conteneurs applicatifs (API Go, Cron Go, Worker IA unique, RabbitMQ 4.4.0, PostgreSQL 18) ainsi que l'usine logicielle (Jenkins, SonarQube, n8n), couplé au stockage objet S3 OVHcloud à Gravelines.

```mermaid
flowchart TB
    subgraph Client ["📱 Client Mobile"]
        App["App Mobile Flutter<br/>iOS & Android"]
    end

    subgraph ExtServices ["☁️ Intégrations Externes"]
        GH["GitHub (Ascension-EIP)<br/>Webhooks & PR Checks"]
        Discord["Discord (#veille-technique)<br/>Alertes Veille Techno"]
        Llm["API LLM Externe"]
    end

    subgraph DNS ["🌐 Réseau & Domaine"]
        Domain["ascension-eip.fr<br/>(Anycast DNS + DNSSEC)"]
    end

    subgraph Storage ["🗄️ OVHcloud Object Storage (Gravelines - GRA)"]
        direction TB
        Bucket["Bucket S3 Standard<br/>(Vidéos brutes & Photos de voies)"]
    end

    subgraph Compute ["🖥️ OVHcloud VPS-4 (Milan - IT-MIL : 8 vCores / 24 Go RAM / 200 Go NVMe)"]
        direction TB

        subgraph Management ["⚙️ Gestion & Routage (Coolify)"]
            Coolify["Coolify PaaS<br/>Gestionnaire de conteneurs & déploiements"]
            Proxy["Reverse Proxy Traefik<br/>Terminaison TLS Let's Encrypt"]
            Coolify -.->|Pilote| Proxy
        end

        subgraph CoreApp ["Conteneurs Applicatifs Docker"]
            API["API Gateway Go / Gin<br/>(Go 1.27)"]
            Cron["Cron Go<br/>(Purge sessions & vidéos expirées)"]
            RabbitMQ["RabbitMQ 4.4.0<br/>Message Broker AMQP"]
            WorkerAI["Worker IA Python<br/>(MediaPipe / ONNX Runtime : YOLO26-seg, MoGe-2 / Pathfinding)"]
            DB[("PostgreSQL 18<br/>Données & JSONB")]
        end

        subgraph ToolingAndCI ["Usine Logicielle, Outils & Veille"]
            WebSite["Site Vitrine Web<br/>(Présentation & Docs)"]
            Jenkins["Jenkins CI/CD<br/>(Pipelines de tests & builds)"]
            Sonar["SonarQube<br/>(Quality Gate & SAST)"]
            N8N["n8n Automation Engine<br/>(Veille technologique)"]
        end

        Proxy -->|api.ascension-eip.fr| API
        Proxy -->|ascension-eip.fr| WebSite
        Proxy -->|jenkins.ascension-eip.fr| Jenkins
        Proxy -->|sonarqube.ascension-eip.fr| Sonar
        Proxy -->|n8n.ascension-eip.fr| N8N

        API --> DB
        API --> RabbitMQ
        Cron --> DB
        RabbitMQ --> WorkerAI
        WorkerAI --> DB

        Jenkins <-->|Analyses & Quality Gate| Sonar
    end

    Domain --> Proxy
    GH <-->|Webhooks & PR Status| Jenkins
    N8N -->|Webhook Alertes RSS| Discord
    WorkerAI -->|Requêtes conseils LLM| Llm

    App -->|"1. Demande URL présignée"| API
    API -.->|"2. Délivre URL présignée"| App
    App -->|"3. Upload direct vers S3"| Bucket
    App -->|"4. Confirmation fin upload"| API
    WorkerAI -->|"5. Téléchargement vidéo / photo"| Bucket
    Cron -->|"Suppression médias expirés"| Bucket
    App -->|"6. Récupération JSON d'analyse / conseils"| API
```

---

## 4. Schéma de données (Data Diagram)

Ce diagramme entité-association reflète le schéma PostgreSQL 18 issu des migrations actives, incluant la table `ADVICES` découplée de `ANALYSES`, le renommage de `GHOSTS` / `GHOST_HOLDS` en `PATHFINDINGS` / `PATHFINDING_HOLDS` et la table `VIDEO_CONTEXTS`.

```mermaid
erDiagram
    USERS ||--o| USER_PROFILES : has
    USERS ||--o{ USER_BODY_CONSTRAINTS : declares
    USERS ||--o{ SESSIONS : authenticates
    USERS ||--o{ TUTORIAL_PROGRESS : tracks
    USERS ||--o{ CLIMBING_SESSIONS : climbs
    USERS ||--o{ VIDEOS : uploads
    USERS ||--o{ ROUTES : creates
    USERS ||--o{ PATHFINDINGS : requests
    USERS ||--o{ GOALS : sets
    USERS ||--o{ TRAINING_LOGS : logs
    USERS ||--o{ FRIENDSHIPS : requests
    USERS ||--o{ FOLLOWS : follows
    USERS ||--o{ SUBSCRIPTIONS : subscribes
    USERS ||--o{ QUOTA_USAGES : consumes
    USERS o|--o{ GYMS : manages

    GYMS ||--o{ CLIMBING_SESSIONS : hosts
    GYMS ||--o{ ROUTES : hosts

    CLIMBING_SESSIONS ||--o{ VIDEOS : groups
    CLIMBING_SESSIONS ||--o{ TRAINING_LOGS : links

    VIDEOS ||--o{ ANALYSES : analyzed_by
    VIDEOS ||--o| ADVICES : advised_by
    ANALYSES ||--o| ANALYSIS_SCORES : scored_by
    ANALYSES ||--o{ COMPARISONS : compared_in
    PATHFINDINGS ||--o{ COMPARISONS : compared_against

    ROUTES ||--o{ HOLDS : contains
    ROUTES ||--o{ PATHFINDINGS : generates
    PATHFINDINGS ||--o{ PATHFINDING_HOLDS : uses
    HOLDS ||--o{ PATHFINDING_HOLDS : selected_in

    GOALS ||--o{ TRAINING_PROGRAMS : drives
    TRAINING_PROGRAMS ||--o{ TRAINING_PROGRAM_SESSIONS : schedules
    TRAINING_PROGRAM_SESSIONS ||--o{ EXERCISES : contains
    TRAINING_PROGRAM_SESSIONS ||--o{ TRAINING_LOGS : completed_by

    SUBSCRIPTION_PLANS ||--o{ SUBSCRIPTIONS : priced_by
    SUBSCRIPTIONS ||--o{ SUBSCRIPTION_EVENTS : emits

    VIDEO_CONTEXTS {
        uuid id PK
    }
```

---

## 5. Schéma de la pipeline IA

Ce diagramme détaille les traitements exécutés par le worker IA Python : la pipeline d'analyse de pose (MediaPipe + métriques + conseils LLM découplés) et la pipeline Mode Fantôme (segmentation YOLO26-seg en ONNX, couleur dominante en espace CIELAB, estimation de profondeur métrique MoGe-2 ViT-S en ONNX et plan du mur, puis pathfinding A* et calcul des postures rendues côté mobile).

```mermaid
flowchart TD
    subgraph A ["Analyse de pose & Conseils"]
        A1["Vidéo grimpeur (S3)"] --> A2["Squelette MediaPipe<br/>33 points par image"]
        A2 --> A3["Filtrage, angles articulaires & vitesses"]
        A3 --> A4["Découpage en mouvements & pauses"]
        A4 -->|"Job découplé (poses.advice)"| A5["Conseils personnalisés LLM<br/>(OpenAI-compatible)"]
    end

    subgraph B ["Mode Fantôme (Détection & Pathfinding)"]
        B1["Photo de la voie (S3)"] --> B2["Segmentation prises & volumes<br/>(YOLO26-seg / ONNX Runtime)"]
        B2 --> B3["Couleur dominante<br/>(espace CIELAB)"]
        B1 --> B4["Profondeur métrique monoculaire<br/>(MoGe-2 ViT-S / ONNX Runtime)"]
        B3 --> B5["Estimation du plan du mur<br/>& homographie pixels → cm"]
        B4 --> B5
        B5 --> B6["Validation prises, départ/fin<br/>+ Morphologie grimpeur"]
        B6 --> B7["Pathfinding A* (bêta réalisable)<br/>& calcul des postures par étape"]
    end

    subgraph C ["Rendu mobile (Edge Rendering)"]
        C1["Canvas CustomPainter<br/>Overlay squelette & conseils"]
        C2["Visionneuse pas-à-pas<br/>Mode Fantôme"]
    end

    A4 --> C1
    A5 --> C1
    B7 --> C2
```
