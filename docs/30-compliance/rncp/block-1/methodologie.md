# Méthodologie d'Audit et de Conformité

L'objectif de cet audit était de définir l'écosystème complet dans lequel évolue **Ascension**. Nous avons dépassé la simple analyse de la concurrence pour intégrer des contraintes techniques, juridiques et humaines, garantissant ainsi que nous ne "réinventons pas la roue".

## 1. Analyse du Contexte Concurrentiel

Notre approche a combiné l'intuition brute et l'objectivité rationnelle pour positionner Ascension sur le marché.

-   **Formalisation de l'Intuition** : Nous sommes partis d'une conviction profonde : les grimpeurs ont besoin d'un feedback biomécanique précis, agnostique du lieu, pour dépasser leur plafond de verre.
    
-   **Définition de Critères Objectifs** : Pour nous comparer aux solutions existantes (comme Crimpd), nous avons établi des axes d'analyse précis:
    
    -   **Business** : Accessibilité (prix), dépendance aux bases de données de salles, facilité d'utilisation.
        
    -   **Technique** : Latence de traitement (cible < 60s), précision de l'extraction de squelette, consommation de batterie sur mobile.
        
-   **Outils de Visualisation** : Nous avons utilisé un **tableau comparatif de fonctionnalités** pour mettre en avant nos différenciateurs clés, notamment le **Mode Fantôme** et le rendu côté client.
    

## 2. Audit de l'État de l'Art Technique

Pour maximiser l'efficacité de notre développement, nous avons appliqué une stratégie de "Build vs Buy".

-   **Identification des Standards** : Plutôt que de développer nos propres modèles de vision par ordinateur, nous avons intégré des bibliothèques robustes comme **MediaPipe Pose** (33 points clés) et **PyTorch**.
    
-   **Services Tiers et APIs** : Nous utilisons des solutions standardisées pour les besoins transverses : **MinIO** pour le stockage compatible S3 et **RabbitMQ** pour la gestion asynchrone des tâches.
    
-   **Benchmark Technique** : Nous avons validé notre choix de **Rust (Axum)** pour l'API Gateway afin de garantir une sécurité mémoire native et des performances élevées (p95 < 200ms).
    

## 3. Conformité Légale et Sécurité

La gestion de vidéos d'utilisateurs impose une rigueur absolue en matière de protection des données.

-   **RGPD (GDPR)** : Nous avons audité les données collectées. Les vidéos non sauvegardées explicitement sont supprimées après 7 jours de notre bucket MinIO.
    
-   **Sécurité (OWASP)** : Nous avons identifié les risques majeurs, notamment l'injection de données via le JSONB de PostgreSQL et la sécurisation des uploads par **URL pré-signées** pour éviter l'exposition de nos clés secrètes S3.
    
-   **Accessibilité (A11y)** : Nous suivons les standards **WCAG** pour l'application Flutter, en nous concentrant sur les contrastes élevés pour une utilisation en salle d'escalade (souvent très lumineuse ou poussiéreuse).
    

## 4. Audit des Compétences de l'Équipe (HR)

Nous avons confronté l'ambition d'Ascension aux forces réelles de nos 5 membres.

-   **Matrice de Compétences** : Nous avons listé les besoins en IA (Python/PyTorch), Backend (Rust), Mobile (Flutter) et DevOps (Moonrepo/Docker).
    
-   **Analyse d'Écart (Gap Analysis)** : L'audit a révélé un besoin de montée en compétence sur l'intégration RabbitMQ pour Gianni et sur l'optimisation GPU pour Olivier.
    
-   **Plan d'Action** : Nous avons instauré des sessions de "Technology Watch" régulières et des POCs (Proof of Concept) pour valider l'intégration de chaque brique avant sa mise en production.

## Conclusion

```mermaid
graph LR
    %% Phase 1: Investigation Terrain
    A[<b>1. Investigation & Réalité</b><br/>Observation en salle d'escalade] --> B(Interviews Grimpeurs)
    B --> C{Identification du <br/>'Plafond de Verre'}
    
    %% Phase 2: Audit Concurrentiel & Objectivité
    D[<b>2. Audit de l'Existant</b><br/>Analyse de Crimpd & concurrents]
    D --> E[Définition des critères :<br/>Business vs Technique]
    E --> F(Tableau comparatif des fonctionnalités)
    
    %% Phase 3: État de l'Art & Étude Technique
    G[<b>3. État de l'Art Technique</b><br/>Ne pas réinventer la roue]
    G --> H[Benchmark IA:<br/>MediaPipe Pose vs Custom]
    H --> I[Audit Infrastructure:<br/>Rust, RabbitMQ, MinIO]
    
    %% Phase 4: Conformité & Risques
    J[<b>4. Audit de Conformité</b><br/>Sécurité & Légal]
    J --> K(Analyse RGPD: Rétention vidéo)
    K --> L(Accessibilité PSH: WCAG/RGAA)
    
    %% Final: Cadrage
    L --> M((<b>Livrable Final</b><br/>Spécifications & Chiffrage))

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style G fill:#bbf,stroke:#333,stroke-width:2px
    style J fill:#bfb,stroke:#333,stroke-width:2px
    style M fill:#f96,stroke:#333,stroke-width:4px
```

```mermaid
graph LR
    subgraph R1 [ÉTAPE 1 : ANALYSE MÉTIER & UTILISATEUR]
    direction LR
    A[<b>Investigation</b><br/>Observation en salle] --> B(<b>Interviews</b><br/>Grimpeurs & Coachs)
    B --> C(<b>Benchmark</b><br/>Analyse Crimpd/SNCF)
    end

    subgraph R2 [ÉTAPE 2 : AUDIT TECHNIQUE & LÉGAL]
    direction LR
    D[<b>État de l'art</b><br/>IA MediaPipe vs Custom] --> E(<b>Infra & Sécurité</b><br/>Rust/RabbitMQ/OWASP)
    E --> F(<b>Conformité</b><br/>RGPD & Accessibilité)
    end

    C --> D

    style A fill:#f9f,stroke:#333
    style D fill:#bbf,stroke:#333
    style F fill:#f96,stroke:#333
```

### 1. Feuille de route d'évolution (Horizon 36 mois)

Notre stratégie est découpée en phases logiques pour absorber la croissance de la base utilisateur :

-   **Court terme (0–12 mois) :** Stabilisation du pipeline IA et industrialisation des tests d'accessibilité mobile pour les PSH.
    
-   **Moyen terme (12–24 mois) :** Passage à l'échelle via le scaling horizontal des workers IA (Python/MediaPipe) et durcissement de la gouvernance RGPD.
    
-   **Long terme (24–36 mois) :** Transition vers une orchestration plus robuste (type Kubernetes) selon le trafic et versionnement strict des contrats d'API pour éviter toute rupture de service client.
    

### 2. Stratégie de migration technique

Pour assurer une continuité de service, nous appliquons des principes de **déploiement continu** :

-   **Approche "Additive-first" :** Les modifications de schéma PostgreSQL sont d'abord additives (nouvelles colonnes/tables) pour maintenir la compatibilité avec les versions précédentes du code.
    
-   **Feature Flags :** Utilisation de drapeaux de fonctionnalités pour activer progressivement les nouvelles capacités (ex: Mode Fantôme) sans risquer une panne globale.
    
-   **Compatibilité ascendante :** Maintenance de la version N-1 des endpoints API durant les phases de transition.
    

### 3. Gouvernance et Mitigation des risques

Nous avons mis en place un cadre de suivi pour anticiper les points de rupture :

-   **Revue mensuelle des risques :** Analyse systématique de la sécurité, de la conformité légale et de l'accessibilité.
    
-   **Traçabilité des décisions :** Chaque changement d'architecture majeur est documenté (ADR - Architecture Decision Records) avant implémentation pour garantir la maintenabilité à long terme par n'importe quel membre de l'équipe.
-   

```mermaid
graph LR
    subgraph T [HORIZON TEMPOREL & ÉVOLUTION]
    direction TB
    H1[<b>0-12 mois : Fondation</b><br/>Stabilisation IA & Accessibilité] --> H2[<b>12-24 mois : Croissance</b><br/>Scaling Workers & Gouvernance RGPD]
    H2 --> H3[<b>24-36 mois : Maturité</b><br/>Orchestration & Versionnement API]
    end

    subgraph M [STRATÉGIE DE MIGRATION CONTINUE]
    direction TB
    M1(<b>Additive-First</b><br/>Migrations DB sans rupture) --- M2(<b>Feature Flags</b><br/>Déploiement progressif)
    M2 --- M3(<b>Plan de Mitigation</b><br/>Rollback & Revue mensuelle)
    end

    T -.-> M

    style H1 fill:#e1f5fe,stroke:#01579b
    style H2 fill:#b3e5fc,stroke:#01579b
    style H3 fill:#81d4fa,stroke:#01579b
    style M fill:#fff3e0,stroke:#e65100
```

```mermaid
graph LR
    subgraph Chronologie
    A[<b>1. Consolidation</b><br/>Stabiliser & Rendre accessible] --> B[<b>2. Croissance</b><br/>Plus de grimpeurs & Plus de sécurité]
    B --> C[<b>3. Maturité</b><br/>Automatisation & Long terme]
    end

    subgraph Methode
    D(<b>Ajouts sécurisés</b><br/>Ne jamais casser l'existant) --- E(<b>Tests progressifs</b><br/>Activer les options pas à pas)
    E --- F(<b>Protection des données</b><br/>Suppression auto & Respect de la loi)
    end

    C -.-> D
```

