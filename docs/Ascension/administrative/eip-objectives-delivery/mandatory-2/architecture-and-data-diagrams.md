:::success
**Version:** 1.0
:::

# Schèmas et diagrammes de l'architecture et des données

---

## 1. Schéma d'architecture globale du système

```mermaid
graph TD
    subgraph Client ["📱 Couche Client"]
        MobileApp["Application Mobile Flutter<br/>"]
    end

    subgraph API ["🛡️ API Gateway (Go / Gin)"]
        APIServer["Serveur API REST & WebSocket"]
        AuthService["Authentification JWT & Quotas"]
    end

    subgraph Storage ["🗄️ Données & Stockage"]
        ObjectStorage["Stockage Objets S3<br/>(RustFS en dev / OVHcloud en prod)"]
        Database[("Base de Données PostgreSQL<br/>Tables relationnelles + JSONB")]
        MessageQueue["Message Broker<br/>RabbitMQ"]
    end

    subgraph AI ["🤖 Traitement IA (Python)"]
        direction TB
        subgraph Vision ["Pipeline 1 : Analyse de pose"]
            Skel["Extraction squelette MediaPipe"]
            Adv["Conseils coach LLM"]
            Skel --> Adv
        end
        subgraph Ghost ["Pipeline 2 : Mode Fantôme"]
            Holds["Détection des prises"]
            Path["Pathfinding morphologique"]
            StepsImg["Générateur d'images étapes"]
            Holds --> Path --> StepsImg
        end
        subgraph Training ["Pipeline 3 : Entraînement"]
            Programs["Générateur de programmes"]
        end
    end

    MobileApp -->|"1. Demande URL d'upload"| APIServer
    APIServer -->|"2. Délivre URL présignée PUT"| ObjectStorage
    MobileApp -->|"3. Téléversement binaire direct"| ObjectStorage
    MobileApp -->|"4. Notification upload terminé"| APIServer

    APIServer -->|"5. Publication tâche AMQP"| MessageQueue
    MessageQueue -->|"6a. poses.detect"| Skel
    MessageQueue -->|"6b. ghost.path"| Holds
    MessageQueue -->|"6c. training.plan"| Programs

    Skel -->|"Lecture vidéo"| ObjectStorage
    Holds -->|"Lecture photo"| ObjectStorage

    Adv -->|"7a. Sauvegarde result & hints"| Database
    StepsImg -->|"7b. Sauvegarde ghost & étapes"| Database
    Programs -->|"7c. Sauvegarde plan d'entraînement"| Database

    Adv -->|"8. Événement terminé"| MessageQueue
    StepsImg -->|"8. Événement terminé"| MessageQueue

    MessageQueue -->|"9. Notification résultat"| APIServer
    APIServer -->|"10. Notification WebSocket / Polling"| MobileApp
    MobileApp -->|"11. Requête résultats (JSON)"| APIServer
    APIServer -->|"12. Lecture des métriques"| Database
```

---

## 2. Diagramme de séquence de bout en bout pour l'analyse de pose

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
    App->>API: GET /v1/videos/upload-url?content_type=video/mp4&size=...
    API->>S3: Génération URL pré-signée PUT (expiration 15 min)
    S3-->>API: URL pré-signée retournée
    API-->>App: { video_id, upload_url }

    App->>S3: PUT /videos/{video_id}.mp4 (Upload binaire direct)
    S3-->>App: 200 OK (Upload réussi)
    App->>API: PUT /v1/videos/upload-done/{video_id}
    API-->>App: 204 No Content

    Note over App,RMQ: Phase 2 : Soumission asynchrone
    App->>API: POST /v1/analysis { video_id }
    API->>DB: INSERT INTO analyses (status='pending')
    API->>RMQ: Publie 'pose.detect.requested' { job_id, object_key }
    API-->>App: 202 Accepted { analysis_id }

    Note over RMQ,Worker: Phase 3 : Traitement IA
    RMQ->>Worker: Message consommé depuis 'poses.detect'
    Worker->>DB: UPDATE analyses SET status='started', progress=0
    Worker->>S3: Téléchargement du flux MP4 temporaire
    Worker->>Worker: MediaPipe Pose : 33 keypoints par frame, filtrage & métriques
    Worker->>DB: UPDATE analyses SET result=JSONB, progress=85
    Worker->>RMQ: Publie 'pose.detect.completed' sur 'events'

    RMQ->>Worker: Message consommé depuis 'poses.advice'
    Worker->>Worker: LLM (OpenAI API) : génération des conseils personnalisés
    Worker->>DB: UPDATE analyses SET hints=JSONB, status='success', progress=100
    Worker->>RMQ: Publie 'pose.advice.status'

    Note over API,App: Phase 4 : Notification & Edge Rendering
    App->>API: Polling GET /v1/analysis/{analysis_id} (ou WebSocket)
    API->>DB: SELECT result, hints FROM analyses WHERE id = ...
    DB-->>API: Données JSONB
    API-->>App: 200 OK avec payload biomécanique (~50 Ko)
    App->>App: CustomPainter dessine le squelette et les conseils sur la vidéo locale
    App->>User: Affichage interactif avec curseur temporel
```

---

## 3 Schèma d'hébergement et d'infrastructure cloud

```mermaid
flowchart TB
    subgraph Client ["📱 Client Mobile"]
        App["App Mobile Flutter<br/>iOS & Android"]
    end

    subgraph ExtServices ["☁️ Intégrations Externes"]
        GH["GitHub (Ascension-EIP)<br/>Webhooks & PR Checks"]
        Discord["Discord (#veille-technique)<br/>Alertes Veille Techno"]
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
            API["API Gateway Go / Gin<br/>(Go 1.27.1)"]
            RabbitMQ["RabbitMQ 4.2.4<br/>Message Broker AMQP"]
            WorkerPose["Worker AI d'analyse de pose<br/>(MediaPipe / PyTorch)"]
            WorkerGhost["Worker AI de mode fantôme<br/>(Pathfinding & YOLOv8)"]
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
        RabbitMQ --> WorkerPose
        RabbitMQ --> WorkerGhost
        WorkerPose --> DB
        WorkerGhost --> DB

        Jenkins <-->|Analyses & Quality Gate| Sonar
    end

    Domain --> Proxy
    GH <-->|Webhooks & PR Status| Jenkins
    N8N -->|Webhook Alertes RSS| Discord

    App -->|"1. Demande URL pré-signée"| API
    API -.->|"2. Délivre URL pré-signée"| App
    App -->|"3. Upload direct vers S3"| Bucket
    App -->|"4. Notification fin upload"| API
    WorkerPose -->|"5. Téléchargement vidéo"| Bucket
    WorkerGhost -->|"5. Téléchargement photo"| Bucket
    App -->|"6. Récupération JSON d'analyse"| API
```

---

## 4. Schéma de Données (Data Diagram)

```mermaid
erDiagram
    USERS ||--o| USER_PROFILES : has
    USERS ||--o{ USER_BODY_CONSTRAINTS : declares
    USERS ||--o{ SESSIONS : authenticates
    USERS ||--o{ TUTORIAL_PROGRESS : tracks
    USERS ||--o{ CLIMBING_SESSIONS : climbs
    USERS ||--o{ VIDEOS : uploads
    USERS ||--o{ ROUTES : creates
    USERS ||--o{ GHOSTS : requests
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
    ANALYSES ||--o| ANALYSIS_SCORES : scored_by
    ANALYSES ||--o{ COMPARISONS : compared_in

    ROUTES ||--o{ HOLDS : contains
    ROUTES ||--o{ GHOSTS : generates
    GHOSTS ||--o{ GHOST_HOLDS : uses
    HOLDS ||--o{ GHOST_HOLDS : selected_in
    GHOSTS ||--o{ COMPARISONS : compared_in

    GOALS ||--o{ TRAINING_PROGRAMS : drives
    TRAINING_PROGRAMS ||--o{ TRAINING_PROGRAM_SESSIONS : schedules
    TRAINING_PROGRAM_SESSIONS ||--o{ EXERCISES : contains
    TRAINING_PROGRAM_SESSIONS ||--o{ TRAINING_LOGS : completed_by

    SUBSCRIPTION_PLANS ||--o{ SUBSCRIPTIONS : priced_by
    SUBSCRIPTIONS ||--o{ SUBSCRIPTION_EVENTS : emits
```

### 5. Schèma de la pipeline de l'IA

```mermaid
flowchart TD
    subgraph A ["Analyse de pose"]
        A1["Vidéo grimpeur (S3)"] --> A2["Squelette MediaPipe\n33 points par image"]
        A2 --> A3["Angles articulaires & vitesses"]
        A3 --> A4["Découpage en mouvements & pauses"]
    end

    subgraph B ["Mode fantôme"]
        B1["Photo de la voie (S3)"] --> B2["Détection prises (YOLOv8)"]
        B2 --> B3["Couleur dominante (OpenCV HSV)"]
        B3 --> B4["Clustering par voie (k-means)"]
        B4 --> B5["Validation / Correction utilisateur"]
        B5 --> B6["Prises validées + Morphologie"]
        B6 --> B7["Calcul bêta optimale par étapes"]
    end

    subgraph C ["Rendu mobile"]
        C2["Visionneuse pas-à-pas\nMode Fantôme"]
        C1["Canvas CustomPainter\nOverlay squelette & conseils"]
    end

    A4 --> C1
    B7 --> C2
```
