# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2026-11-13

### ⚡ Performance

- *(database)* Drop unused videos status index

### ➕ Additions

- *(server)* Add user email normalization helper
- *(docs)* Add management meeting memos for 2026
- *(docs)* Include project documentation and administrative resources
- *(docs)* Include presentation files index for workshops
- *(docs)* Update pedagogical resources and images
- *(docs)* Initialize architecture benchmark documentation
- *(docs)* Add team image to Ascension planning documentation
- *(docs)* Include pedagogical follow-up documents
- *(docs)* Include pitch document and deck
- *(docs)* Add mentoring session 2 and 3 records
- *(docs)* Include october 2026 bills and invoices for Ascension project
- *(docs)* Document hard problem characterization and technology watch strategy
- *(docs)* Add mentoring and pedagogical follow-up records
- *(docs)* Add administrative memo for 26-11-09

### ➖ Removals

- *(ai)* Drop cursor and codex mentions from AI docs
- *(ai)* Remove squad agent system and its workflows
- *(ai)* Strip remaining squad references from configs and docs
- *(ai)* Delete roadto-postanalyse.mp4 video file
- *(database)* Delete legacy migration files
- *(docs)* Delete case-colliding docs readme files
- *(docs)* Delete binary resources from the repository
- *(docs)* Delete placeholder documentation files
- *(mobile)* Stop tracking generated macos ephemeral files

### 🏗️ Build System

- *(toolchain)* Bump go to 1.27.1 in moon and proto
- *(deps)* Bump the pip-dependencies group in /apps/ai with 8 updates
- *(deps)* Bump the pip-dependencies group in /apps/ai with 8 updates
- *(deps)* Bump the pub-dependencies group
- *(deps)* Bump the pub-dependencies group in /apps/mobile with 5 updates
- *(deps)* Bump rabbitmq
- *(deps)* Bump rabbitmq from 4.3.5-management to 4.3.6-management in the docker-compose-dependencies group
- *(deps)* Bump the go-dependencies group
- *(deps)* Bump the go-dependencies group in /apps/server with 5 updates
- *(deps)* Bump the pip-dependencies group in /apps/ai with 7 updates
- *(deps)* Bump the pip-dependencies group in /apps/ai with 7 updates
- *(deps)* Bump rabbitmq
- *(deps)* Bump rabbitmq from 4.3.6-management to 4.4.0-management in the docker-compose-dependencies group
- *(deps)* Bump github.com/jackc/pgx/v5
- *(deps)* Bump github.com/jackc/pgx/v5 from 5.11.0 to 5.12.0 in /apps/server in the go-dependencies group
- *(deps)* Bump python
- *(deps)* Bump python from 3.11-slim to 3.15-slim in /apps/ai in the docker-dependencies group across 1 directory
- *(mobile)* Restore cocoapods integration for ios
- *(deps)* Bump the pub-dependencies group
- *(deps)* Bump the pub-dependencies group in /apps/mobile with 12 updates
- *(server)* Ship the cron binary in the api image

### 🐛 Bug Fixes

- *(log)* Zerolog -> slog
- *(server)* Code structure to a simplest version
- *(server)* Auth form
- *(server)* Config env var name
- *(server)* Middleware cleaning
- *(database)* Clean migrations
- *(database)* Remove trailing comma in sessions migration
- *(database)* Remove trailing comma in videos migration
- *(database)* Widen videos object_key column
- *(database)* Add missing semicolon in analyses migration
- *(server)* Use pgx placeholder in expired sessions cleanup
- *(server)* Remove extra placeholder in video insert query
- *(server)* Use analyses table name in analysis repository
- *(ai)* Write coaching hints to analyses advice column
- *(server)* Normalize emails in auth forms
- *(server)* Normalize emails in user create and update requests
- *(server)* First run
- *(server)* Input auth service validation move from handler to services
- *(server)* Videos migration
- *(db)* Migration format now concurrency proof + symlink in root poject for migrations
- *(db)* Add if exist to drop
- *(db)* Trailling commas
- *(cron)* Implement new cron
- *(db)* Migrations
- *(ui)* Update api key mappings for video upload analysis
- Enhance SettingsPage UI with improved layout and new SelectRow component
- *(ci)* Handle potential encoding errors in gemini_commit script
- *(ai)* Align worker database writes with the new analyses schema
- *(merge)* Test every endpoitn and fix
- *(localization)* Reorder authors in file headers
- *(auth)* Correct typo in LoginForm binding tag
- *(network)* Update auth endpoint paths and refresh token method
- *(storage)* Simplify concurrent writes and deletes
- Install the system libraries MediaPipe and OpenCV load at runtime
- *(server)* Storage bucket creation
- *(server)* Analyses request
- *(server)* Bis
- *(server)* Analysis pipeline to fit Issue#40
- *(docker)* Remove obsolete postgres build directive and use official postgres:18 image
- *(server)* Point videos.climbing_session_id at climbing_sessions
- *(server)* Align the job statuses and expose the analysis hints
- *(server)* Publish analysis jobs with the worker contract
- *(server)* Honor the endpoint scheme and region in the s3 client
- *(ai)* Read the s3 signing region from the environment
- *(server)* Answer 200 to get and head on the health route
- *(server)* Exclude the cron service from the coolify health status
- *(server)* Analysis.result now use shared result type
- Address valid ai review feedback on documentation and worker utils

### 👷 Continuous Integration

- *(workflows)* Bump go to 1.27.1 in server job
- *(github-actions)* Refactor mirror repository process to use dynamic matrix
- *(hooks)* Remove git pull from pre-push hook
- *(workflow)* Update glob pattern to ignore markdown files recursively
- *(server)* Add the jenkins pipeline and sonarqube project
- *(ai)* Add the jenkins pipeline and sonarqube project
- *(mobile)* Add the jenkins pipeline and sonarqube project
- Remove the github actions vps deployment
- *(server)* Leave the startup code out of the sonarqube coverage

### 💼 Other

- *(server)* Postgres interface
- *(server)* User implementation
- *(server)* Auth implementation
- *(server)* Video implementation 1/2
- *(server)* Video implementation 2/2
- *(server)* Analysis implementation
- Merge branch 'server/finish-rebase' into fix/server
- Merge pull request #191 from Ascension-EIP/fix/server

merge: "fix/database-migrations" into "server/finish-rebase"
- Merge branch 'dev' into refactor/mobile-ui
- Merge pull request #198 from Ascension-EIP/server/finish-rebase

merge: golang server cleaning
- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into refactor/ai
- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into refactor/ai
- Merge branch 'dev' into feat/user_profile
- Merge branch 'feat/user_profile' into dev
- *(new_mobile)* Add initial flutter project structure
- Merge branch 'dev' into refactor/mobile-application
- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into dev
- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into refactor/ai
- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into refactor/ai
- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into refactor/ai
- Merge branch 'dev' into fix/analysis-worker-contract

### 📚 Documentation

- *(server)* Update go version to 1.27.1
- *(ci)* Update go version in github actions guide
- *(database)* Align schema specification with migrations
- *(database)* Document lowercase users email constraint
- *(database)* Document trimmed users email constraint
- *(ai)* Sync graphify skill with latest installed version
- *(developer_guide)* Update architecture index and add technical action plan
- *(ai)* Add gemini environment variables to ai-worker documentation
- *(architecture)* Add comprehensive inter-app communication audit and recommendations
- *(ai)* Update graphify and forui documentation structure
- *(product)* Update feature roadmap maturity levels
- *(core)* Update documentation status and standards
- *(management)* Update status to final across project documentation
- *(ai)* Update pose ai terminology in instructions
- *(readme)* Update project roadmap features and technology stack
- *(ai)* Update pose ai terminology to 3d
- *(ai)* Mark sam3d module as deprecated
- *(management)* Update roadmap links and add missing memos
- *(management)* Update choice count for complementary tasks in memo
- *(engineering)* Standardize documentation header and update server architecture migration details
- *(core)* Standardize document headers and format
- *(core)* Update document header format to use status containers
- *(repo)* Remove metadata headers from documentation files
- Update "documentation-accessibility-compliance", "rncp", "block-1", "needs-analysis", "current-state-audit" (+161 more)
- Update "engineering", "developer_guide"
- Update "Untitled"
- Update "Develo", "Untitled", "README"
- Update "documentation-accessibility-compliance"
- Update "Developer", "User", "Untitled"
- Update "administrative"
- Update "Untitled"
- Update "deck", "follow-up", "audio"
- Update "images"
- Update "commandes", "agents", "code-documentation", "commit", "documentation" (+80 more)
- Update "SKILL", "communication-inter-apps-audit-et-recommandations", "deployment", "development", "production" (+10 more)
- Update "monorepo-guide", "system-overview", "accessibility-implementation-guide", "api-routes", "architecture" (+26 more)
- Update "adding-a-route", "mobile", "server", "catalogue-fonctionnalites", "product"
- Update "block-1", "rncp", "accessibility-compliance", "needs-analysis", "current-state-audit" (+25 more)
- Update "accessibility-compliance", "audit-draft", "management", "beta-test-plan", "acceptance-test-plan" (+2 more)
- Update "management", "beta-test-plan", "roadmap-fonctionnelle", "compliance"
- Update "management"
- Update "folder-files", "folder-files", "block-5", "folder-files", "block-6" (+40 more)
- Update "welcome", "user"
- Update "tools"
- Update "untilted", "ai", "ai"
- Update "developer", "apps", "ai"
- Update "developer", "apps", "ai", "audits", "untilted"
- Update "developer (2)", "apps", "ai"
- Update "audio", "folder-files", "deck", "folder-files", "follow-up" (+4 more)
- Update "images", "images", "folder-files", "planning", "folder-files" (+4 more)
- Update "Ascension"
- Update "Ascension"
- Update "Ascension"
- *(database)* Rewrite database schema specification
- Update "database-schema"
- Update "developer", "architecture", "specifications", "database-schema"
- Update "welcome", "developer (2)", "architecture", "specifications", "database-schema"
- Update "user"
- Update "developer"
- Update "developer"
- Update "communication-inter-apps-audit-et-recommandations"
- Update "communication-inter-apps-audit-et-recommandations", "communication-inter-apps-audit-et-recommandations"
- Update "untilted"
- *(database)* Align schema specification with the migrations
- Update "development", "database-schema"
- Update "developer", "architecture", "deployment", "development"
- Update "untilted"
- Update "untilted", "developer (2)", "architecture", "deployment", "development" (+1 more)
- Update "deployment", "architecture", "developer (2)", "development", "communication-inter-apps-audit-et-recommandations"
- Update "drafts", "communication-inter-apps-audit-et-recommandations"
- Update "Ascension"
- Update "drafts"
- Update "untilted", "accessibility-compliance", "needs-analysis", "current-state-audit", "functional-specifications" (+75 more)
- Update "drafts"
- Update "new-audit", "pool-draft", "plan-d-action-technique", "issues-to-create"
- Update "new-audit", "pool-draft", "communication-inter-apps-audit-et-recommandations", "plan-d-action-technique", "drafts" (+1 more)
- Update "drafts"
- Update "monorepo-guide"
- Update "system-overview", "architecture"
- Update "monorepo-guide", "architecture"
- Update "database-schema"
- Update "audit-draft", "architecture"
- Update "mobile"
- Update "adding-a-route"
- Update "server", "api-specification"
- Update "architecture", "mobile", "git-branch-standards-guide"
- Update "Ascension", "untilted", "block-1", "rncp", "accessibility-compliance" (+132 more)
- Update "git"
- Update "guidelines"
- Update "developer"
- Update "developer"
- Update "tools", "agents"
- Update "tools", "user"
- Trash "welcome", "user"
- Update "globale-architecture"
- Update "architecture"
- Update "globale-architecture"
- Update "architecture"
- Update "audits"
- Update "specifications", "audits", "deployment"
- Update "go-vs-rust-functional-gap"
- Update "overview"
- Update "mobile"
- Update "overview"
- Update "overview"
- Update "server"
- Update "overview"
- Update "mobile"
- Update "overview"
- Update "overview", "server"
- Update "ai", "overview"
- Update "ai"
- Update "26-02-10"
- Update "memo", "26-02-16"
- Update "16"
- Update "memo", "26-03-02"
- Update "26-03-09"
- Update "26-03-16"
- Update "26-04-20"
- Update "20"
- Update "26-05-04"
- Update "26-06-13"
- Update "26-06-20"
- Update "26-08-31"
- Update "26-09-07"
- Update "26-09-14"
- Update "26-02-09"
- Update "block-5"
- Update "block-1", "block-7", "rncp", "block-5", "block-6"
- Update "resources", "prototype-pool"
- Update "workshop"
- Update "presentation"
- Update "drafts"
- Update "audio", "rncp", "drafts"
- Update "follow-up", "deck", "intranet", "images"
- Update "markdown-guidelines"
- Update "folder-files"
- Update "folder-files"
- Update "folder-files", "folder-files", "folder-files", "folder-files"
- Update "folder-files"
- Update "folder-files", "folder-files"
- Update "folder-files"
- Update "folder-files"
- Update "folder-files"
- Update "folder-files", "folder-files"
- Update "folder-files"
- Update "folder-files"
- Update "folder-files"
- *(ascension)* Fix broken file paths in pitch deck links
- Update "folder-files"
- Update "folder-files"
- Update "folder-files", "folder-files"
- Update "folder-files", "folder-files"
- Update "folder-files"
- Update "folder-files"
- Update "folder-files"
- Update "folder-files", "folder-files"
- Update "folder-files"
- Update "folder-files"
- Update "folder-files"
- Update "folder-files"
- Update "folder-files"
- Update "folder-files"
- *(admin)* Add administrative planning documentation
- Update "folder-files"
- Update "folder-files", "folder-files"
- Update "folder-files", "folder-files"
- Update "swagger"
- Update "overview", "swagger"
- Update "database-schema", "administrative"
- Update "administrative"
- Update "a"
- Trash "a"
- Update "engineering", "developer_guide", "architecture", "specifications", "git"
- Update "deck"
- *(administrative)* Translate administrative documentation to french
- *(ascension)* Overhaul project and subsystem documentation hubs
- Update "administrative", "Ascension"
- Update "developer", "user"
- Update "action-plan", "beta-test-plan", "acceptance-test-plan"
- Update "developer", "markdown-guidelines"
- *(docs)* Remove redundant relative path prefixes in markdown links
- Update "developer"
- Update "developer"
- Update "benchmark"
- Update "benchmark", "untilted"
- Update "benchmark"
- *(markdown)* Update documentation guidelines for densho metadata and mermaid usage
- *(architecture)* Add audit report on minio deprecation
- *(administrative)* Update version and roadmap details in feature catalogue
- *(Ascension)* Update functional roadmap to version 1.4
- *(administrative)* Update action plan for greenlight milestone
- *(admin)* Update acceptance and beta test plans
- *(agents)* Update densho metadata header guidelines
- *(architecture)* Update go version to 1.27.1 and refactor task naming
- *(pre-prompt-fr)* Correct minor typos and grammatical errors
- Update server documentation
- Update "markdown-guidelines"
- Update "pricing-subscriptions", "functional-roadmap"
- Update "features-catalog"
- Update "action-plan", "beta-test-plan", "api-routes", "architecture", "implementing-a-crud" (+2 more)
- Update "database-schema"
- Update "overview"
- Update "architecture"
- Update "folder-files"
- Update "developer", "git-branch-standards-guide", "globale-architecture"
- *(admin)* Add infrastructure needs documentation
- Update "new-mobile-design"
- Update "backend"
- Update "backend"
- Update "Untitled"
- Trash "Untitled"
- Update "Décomposition de la pipeline 2D"
- Update "oral_25-02_ppt_content", "production", "prototype-pool-sprint", "impacts-risks", "tech-func-specs" (+2 more)
- Update "overview", "audit-draft", "methodologie", "current-state-audit", "overview" (+36 more)
- Update "issues-to-create", "markdown-guidelines"
- Update "administrative", "pitch"
- Update "pitch"
- Update "pipeline-details"
- Update "overview"
- Update "overview"
- Update "overview"
- Update "overview"
- Update "folder-files"
- Update "eip-objective"
- Update "eip-objectives-delivery", "folder-files"
- Update "Untitled"
- Update "26", "Untitled", "Untitled", "Untitled"
- Update "26-09"
- Update "26-09-28"
- Update "Untitled", "26-09-28"
- Update "Untitled", "26-10-05"
- Update "Untitled"
- Update "26-10-05", "Untitled"
- Update "26"
- Update "Untitled"
- Update "26-10-19"
- Update "26-10-26"
- *(administrative)* Append discussion notes to memo 26-10-26
- Update "Untitled"
- Add questionnaire for Lionel Reveret
- Update "bills", "10"
- Update "folder-files"
- Update "folder-files"
- Update "Questionnaire pour Lionel REVERET - Ascension"
- Update "Questionnaire pour Lionel REVERET"
- Update "Questionnaire pour Lionel REVERET"
- Update "Questionnaire pour Lionel REVERET"
- Trash "Questionnaire pour Lionel REVERET"
- Update "new-mobile-design", trash "pool-draft"
- Trash "plan-d-action-technique"
- Trash "new-audit", "issues-to-create"
- Trash "communication-inter-apps-audit-et-recommandations"
- Update "complementary-C", "complementary-D", "mandatory-1", "mandatory-2"
- Update "complementary-C"
- Update "complementary-D", "complementary-C"
- Update "complementary-D"
- Update "mandatory-2"
- Update "mandatory-2", "mandatory-1"
- Update "complementary-C", "mandatory-1", "complementary-D"
- Update "mandatory-2"
- Update "mandatory-1"
- Update "mandatory-2", "mandatory-1"
- Update "mandatory-2"
- Update "complementary-D", trash "folder-files"
- Update "complementary-C"
- *(readme)* Update postgresql badge to version 18
- *(benchmark)* Update postgresql version in backend diagram
- File metadata dates and authors across the project
- *(infrastructure)* Use the jenkins and sonarqube subdomains
- *(jenkins)* Add the jenkins and sonarqube guide for developers
- *(jenkins)* Add the jenkins and sonarqube administration guide
- *(jenkins)* Build main, staging, dev and pull requests in every job
- *(jenkins)* Explain which branches jenkins builds
- *(jenkins)* Document the sonarqube host settings and the docker image cleanup
- Update team responsibilities
- Update "eip-project-objectives"
- Update "new-mobile-design"
- Update "new-mobile-design"
- Update "Untitled"
- Update "Caractérisation du point dur et dispositif de veille opérationnel"
- Update "Caractérisation du point dur et dispositif de veille opérationnel"
- Update "system-overview"
- *(architecture)* Add technical diagrams and update infrastructure documentation
- Update "globale-architecture"
- Update "Caractérisation du point dur et dispositif de veille opérationnel"
- Update "Schèmas Ascension"
- *(mentoring)* Add notes, transcript and recap for session 4
- Trash "folder-files"
- Trash "folder-files"
- *(ascension)* Update documentation banner assets
- Update "development"
- Update "production"
- Update "deployment"
- Update "production"
- Update "production"
- Update "object-storage"
- *(architecture)* Update cloud hosting and object storage documentation to reflect transition to OVHcloud
- *(architecture)* Update database schema reference link
- *(Ascension)* Update project scope and roadmap documentation
- Update "prototype-pool"
- Update "block-1", "prototype-pool"
- Update "block-1"
- *(server)* Document the climbing session endpoints
- *(infra)* Add the n8n technology watch guide
- *(administrative)* Replace google scholar with openalex in the technology watch
- Update "hard-problem-characterization-and-technology-watch"
- *(server)* Document the analysis job contract
- *(infra)* Add the s3 object storage guide
- *(infra)* Add the api deployment guide
- *(infra)* Add the ai worker deployment guide
- *(server)* Document the user body constraint endpoints
- *(server)* Document the friends, user search and feed routes
- *(infra)* Add the backup and restore guide
- *(infra)* Describe the real backups and the jenkins cache mounts
- *(infra)* Rewrite the production runbook for the vps and coolify
- *(infra)* Document the coolify discord alerts
- Update "overview"
- Update "administrative"
- Update "globale-architecture"
- *(infra)* Document the server coverage and test report in jenkins
- Update "jenkins-sonarqube-guide"
- Update "jenkins-sonarqube-guide"
- Update "user"
- Update "user"
- Update "user"
- Update "user"

### 🔀 Merges

- "refactor/database-schema-constraints" into "fix/database-migrations"
- "fix/user-email-case" into "fix/database-migrations"
- "refactor/mobile-ui" into "dev"
- "refactor/adapt-documentation" into "dev"
- "dev" into "docs/database-schema-spec"
- "docs/database-schema-spec" into "dev"
- "dev" into "feat/database-schema-migrations"
- "feat/database-schema-migrations" into "dev"
- "dev" into "dev"
- "dev" into "dev"
- Dev into server/finish-rebase
- "refactor/ai" into "dev"
- "dev" into "dev"
- "dev" into "dev"
- "dev" into "dev"
- `dev` into `staging`
- "dev" into "dev"
- "refactor/mobile-application" into "dev"
- `dev` into `staging`
- "dev" into "dev"
- "dev" into "dev"
- "dev" into "dev"
- "docs/postgresql-18-version" into "dev"
- "build/mobile-ios-cocoapods" into "dev"
- "refactor/ai" into "dev"
- "ci/jenkins-pipelines" into "dev"
- "docs/jenkins-sonarqube-urls" into "dev"
- "docs/jenkins-sonarqube-guides" into "dev"
- "agents/update-densho-skill" into "dev"
- "docs/jenkins-branch-discovery" into "dev"
- Dev into feat/user_profile
- "fix/docker-compose-postgres-build" into "dev"
- "dev" into "dev"
- "dev" into "dev"
- "dev" into "dev"
- "dev" into "dev"
- "feat/climbing-sessions-crud" into "dev"
- "feat/n8n-technology-watch" into "dev"
- "feat/s3-object-storage" into "dev"
- "feat/api-coolify-deploy" into "feat/s3-object-storage"
- "feat/worker-coolify-deploy" into "feat/s3-object-storage"
- "fix/analysis-worker-contract" into "dev"
- "feat/user-body-constraints" into "dev"
- "feat/friendships-and-feed" into "dev"
- "feat/vps-backups" into "dev"
- "docs/vps-coolify-runbook" into "dev"
- "docs/coolify-discord-alerts" into "dev"
- "dev" into "dev"
- Dev into feat/server-queue-message-flow
- "feat/server-queue-message-flow" into "dev"
- "test/server-unit-tests" into "dev"
- "ci/server-coverage-exclusions" into "dev"
- "dev" into "dev"
- `dev` into `staging`
- `staging` into `main`

### 🚀 Features

- *(server)* Add devenv and air to server
- *(server)* Upgrade to 1.27, google/uuid -> stdlib/uuid
- *(server)* User validation
- *(server)* Hash session token
- *(server)* New cmd for cron
- *(docs)* Audit_storage
- *(db)* Copy dev migrations
- *(server)* Implement new user table
- *(server)* Implement new session table
- *(server)* Implement new video table
- *(server)* Implement new analysis table
- Shadcn-ui-flutter components and guides
- Remove outdated squad documentation and logs
- Add interactive performance donut, circular gauge, and concentric rings components
- Forui documentation for forms, hooks, layout, overlays, setup, styling, theming, and widget previews
- *(build)* Add database migration task
- *(analysis)* Implement multi-type analysis and custom migration driver
- *(docs)* Add mentoring resources and update EIP intranet files
- *(build)* Upgrade moon to v2.5.4 and add automated update script
- *(tools)* Add automated stand-up generator script
- *(database)* Add enum types for the new schema
- *(database)* Migrate users table to username and full name
- *(database)* Add user profile, body constraint and tutorial tables
- *(database)* Store hashed refresh tokens in sessions
- *(database)* Add gyms and climbing sessions tables
- *(database)* Migrate videos table to the new schema
- *(database)* Migrate analyses table to job status and structured hints
- *(database)* Add analysis scores table
- *(database)* Add routes, holds, ghosts and comparisons tables
- *(database)* Add coaching and training tables
- *(database)* Add friendships and follows tables
- *(database)* Add subscription and quota tables
- *(database)* Split cleanup cron jobs for uploads and video retention
- *(ai)* Scaffold new AI worker with pose landmarking pipeline
- *(ai)* Add minio storage service and fix broker connection
- *(migrate)* Add database migration cli tool
- *(subscription)* Implement updated subscription tiers and quotas
- *(server)* User profile with auto creation, get, update
- *(agents)* Add gemini-review command and documentation
- *(mobile)* Implement core architecture and navigation
- *(runner)* Update window title and size
- *(api)* Update auth endpoints to include v1 prefix
- *(l10n)* Add auth and settings translations
- *(core)* Add map and flatMap to Result
- *(auth)* Implement authentication data layer and UI
- *(profile)* Add settings screen and navigation
- *(routing)* Add welcome and settings routes
- *(test)* Add golden and component testing infrastructure
- *(mobile)* Add build task and update dependencies
- *(server)* Get video, list videos
- *(cron)* Add CleanOldQuotaUsage cron
- *(storage)* Minio -> rustfs on server
- *(db)* Video_context table (empty)
- *(docs)* Add infrastructure architecture documentation
- Update pedogical follow up list and fix bug with the first pdf
- Build analyses payload with landmarks and joint angles
- Unit tests for pose advice, movements, PostgreSQL operations, RustFS service, and schemas
- Lock updated
- *(db)* Fix migrations
- *(mobile)* Configure network access and automate dev environment setup
- *(climb_session)* Add climb session feature implementation
- *(docs)* Add guide to manage virtual machines
- *(docs)* Add expert outreach register and update mentoring follow-up records
- *(ui)* Overhaul application theme and screen layouts
- *(server)* Add the climbing session model and repository
- *(server)* Add the climbing session and analysis list services
- *(server)* Expose the climbing session endpoints
- *(infra)* Add the n8n coolify service
- *(infra)* Add the technology watch n8n workflow
- *(infra)* Add the ovh object storage access policy
- *(server)* Add the coolify compose of the api
- *(ai)* Add the coolify compose of the worker
- *(server)* Add the user body constraint model
- *(server)* Add the user body constraint repository
- *(server)* Add the user body constraint service
- *(server)* Expose the user body constraint endpoints
- *(server)* Add friendship, user search and feed domain model
- *(server)* Add postgres friendship and feed queries with their test doubles
- *(server)* Add friendship and feed services
- *(server)* Add friends, user search and feed endpoints
- *(infra)* Add the access policy of the backups bucket
- Feat(server):

- cron for stale analyses
- fix weight validation
- add listAnalysesByFilter, deleteAnalysis
- base for POST /v1/analyses/:id/retry-advice but wait for #318
- *(mobile)* Migrate environment configuration to dart-define-from-file
- *(core)* Update api endpoint paths and add new routes
- *(climb_session)* Integrate remote api for climbing sessions

### 🚚 Restructuring

- *(docs)* Rename ascension alpha test plan to acceptance test plan
- *(docs)* Rename pitch deck files to remove parentheses and update documentation references
- Replace "new_*" version by current version and old version by "old_*" version

### 🚜 Refactoring

- *(database)* Add check constraint on users role
- *(database)* Store user password hash as text
- *(database)* Add check constraint on videos status
- *(database)* Add range check on analyses progress
- *(database)* Store analyses advice as text
- *(database)* Enforce lowercase users email
- *(database)* Reject users email with surrounding whitespace
- *(config)* Standardize environment variable naming convention
- *(ai)* Modularize pose analysis service
- *(database)* Rename analysis fields and include error logging
- *(database)* Reorganize and update migration files
- *(docs)* Modernize document headers and update project structure
- *(docs)* Reorganize documentation structure and directory names
- *(agents)* Reorganize agent commands, rules, and documentation structure
- *(server)* Align users and sessions with the new schema
- *(server)* Align analyses with job status and structured hints
- *(server)* Align videos with the new schema and retention period
- *(docs)* Consolidate directory structure and cleanup documentation
- *(docs)* Remove mandatory table of contents from markdown files
- Code structure for improved readability and maintainability
- Clean up configuration and enhance RabbitMQ integration
- *(ai)* Move broker bindings to macro and extract payload validator
- Reorganize video processing code and introduce PoseSkeleton class
- Clean up imports and update file metadata in rabbitmq and pose_skeleton modules
- Enhance broker and job handling with new routing keys and job status management
- Restructure job handling and introduce shared models for job status and routing keys
- Update TODO comments for job processing and payload schema in pose_detect_request
- Reorder broker connection to ensure proper initialization sequence
- Update date annotations in scripts and settings page
- *(scripts)* Improve header parsing and metadata detection
- *(agents)* Consolidate documentation commands
- *(docs)* Remove redundant original language from headers
- *(build)* Unify task configurations and update migration execution
- *(auth)* Rename signup to register
- *(auth)* Use diacritic package for string normalization
- *(ai)* Improve code robustness and maintenance
- File dates to 2026-10-30 across multiple source and test files in the old AI and old mobile applications. Added a new document for the 2D pipeline decomposition detailing technical bricks and project status.
- Pose detection pipeline: split into modular components
- *(mobile)* Migrate to riverpod 3 and flutter_secure_storage 11
- *(docs)* Remove system-overview and integrate content into architecture guide

### 🤖 AI & Automation Agents

- *(ai)* Update go version in ai instructions

### 🧪 Testing

- *(server)* Add unit tests for user email normalization
- Add auth, profile, and settings screens tests
- *(server)* Cover the climbing sessions and the analysis list
- *(server)* Extend the in-memory repository to users, sessions and videos
- *(server)* Add a helper to skip the known bug tests
- *(server)* Cover the models with unit tests
- *(server)* Cover the http request and response dtos
- *(server)* Cover the postgresql dtos and query builders
- *(server)* Cover the services with unit tests
- *(server)* Cover the cron jobs
- *(server)* Cover every http route through the router
- *(server)* Cover the middlewares and http utils
- *(server)* Cover the configuration and the logger
- *(server)* Cover the rabbitmq and rustfs adapters

### 🧹 Maintenance

- *(assets)* Update mobile app logo and rename legacy documentation images
- *(config)* Update postgres host and add devtools configuration
- *(docker)* Update service configurations and env templates
- *(docker)* Standardize container configuration and networking
- *(build)* Skip database migrations in CI environment
- *(metadata)* Update file headers and maintainer information
- *(moon)* Add inputs to migrate task and define stand-up task
- *(build)* Configure output style for moon tasks
- *(docs)* Reorganize documentation structure
- *(docs)* Standardize file paths and update documentation frontmatter
- *(refactor)* Update file paths to remove numerical prefixes from documentation directories
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- *(headers)* Update date and authors of modified files
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- *(docs)* Sanitize filenames and update documentation links
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Normalize file header dates and author attributions
- *(core)* Update file headers and maintainer metadata
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- *(meta)* Update file headers and maintainer information
- *(deps)* Update project dependencies and infrastructure
- *(new_mobile)* Remove unused README.md
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- *(linux)* Remove url_launcher_linux plugin registration
- Sync pages
- Sync pages
- *(docs)* Update ghost mode definition and roadmap
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- *(gitignore)* Ignore macos pods and flutter ephemeral files
- Update date in __init__.py headers
- Update date in multiple __init__.py files to 2026-11-02
- Sync pages
- Sync pages
- *(agents)* Update the densho skill to its latest version
- Add GITHUB_TOKEN to CI workflow
- *(docs)* Update infrastructure references to RustFS and OVHcloud S3
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- *(ai)* Remove author from pose skeleton metadata
- Sync pages
- Sync pages
- *(env)* Document the s3 region variables
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Sync pages
- Update dev-to-staging cron schedule
- *(docs)* Update file paths for documentation and guidelines
- *(meta)* Update file headers across projects
- Update project file metadata
- Update author in config_test.go and knownbug.go

## [0.2.0] - 2026-09-03

### 🏗️ Build System

- *(deps)* Bump the docker-dependencies group across 2 directories with 3 updates
- *(deps)* Bump the docker-dependencies group across 2 directories with 3 updates
- *(deps)* Bump the docker-compose-dependencies group with 2 updates
- *(deps)* Bump the docker-compose-dependencies group with 2 updates
- *(deps)* Bump the go-dependencies group
- *(deps)* Bump the go-dependencies group in /apps/server with 3 updates
- *(deps)* Bump the github-actions-dependencies group with 5 updates
- *(deps)* Bump the github-actions-dependencies group with 5 updates
- *(deps)* Bump video_player
- *(deps)* Bump video_player from 2.13.0 to 2.14.0 in /apps/mobile in the pub-dependencies group
- *(deps)* Upgrade go to 1.26.0 and flutter to 3.47.2

### 👷 Continuous Integration

- *(workflows)* Remove reviewer notification from dev-to-staging pipeline
- *(script)* Allow staging branch in branch validation script

### 🔀 Merges

- `dev` into `staging`
- `dev` into `staging`
- `staging` into `main`

### 🚜 Refactoring

- *(ui)* Update setting section card to use material widget

### 🧹 Maintenance

- *(ai)* Replace psycopg2 with psycopg2-binary dependency
- *(moon)* Update task input patterns and configurations
- *(build)* Update project dependencies and environment
- *(release)* Update changelog for v0.2.0

## [0.1.13] - 2026-09-03

### ➕ Additions

- *(rust-backup)* Add the rust server as backup for migrate to the Go server
- *(scripts)* Add gemini automation tools
- *(docs)* Include technical track student guide for tech 4
- *(ci)* Implement gemini pr review workflow

### ➖ Removals

- *(useless-backup)* Remove the old useless backup of the rust server
- *(docs)* Remove figma prototype directory and files
- *(sam-3d-legacy-code)* Delete sam_3d_body model and dependencies
- *(deps)* Delete npm configuration and package.json
- *(ci)* Delete deprecated squad workflow automation files

### 🏗️ Build System

- *(deps)* Bump softprops/action-gh-release from 2 to 3
- *(deps)* Bump softprops/action-gh-release from 2 to 3
- *(deps)* Bump conda-incubator/setup-miniconda from 3 to 4
- *(deps)* Bump conda-incubator/setup-miniconda from 3 to 4
- *(deps)* Bump actions/github-script from 8 to 9
- *(deps)* Bump actions/github-script from 8 to 9
- *(deps)* Bump rich from 14.3.3 to 15.0.0 in /apps/ai
- *(deps)* Bump rich from 14.3.3 to 15.0.0 in /apps/ai
- *(deps)* Bump wandb from 0.25.1 to 0.26.1 in /apps/ai
- *(deps)* Bump wandb from 0.25.1 to 0.26.1 in /apps/ai
- *(deps)* Bump minio from 0.3.0 to 0.4.0 in /apps/server
- *(deps)* Bump minio from 0.3.0 to 0.4.0 in /apps/server
- *(deps-dev)* Update ruff requirement in /apps/ai
- *(deps-dev)* Update ruff requirement from <1,>=0.9 to >=0.15.12,<1 in /apps/ai
- *(deps)* Bump openssl from 0.10.76 to 0.10.78 in /apps/server
- *(deps)* Bump openssl from 0.10.76 to 0.10.78 in /apps/server
- *(deps-dev)* Bump @moonrepo/cli from 2.1.3 to 2.2.3
- *(deps-dev)* Bump @moonrepo/cli from 2.1.3 to 2.2.3
- *(deps-dev)* Update build requirement in /apps/ai
- *(deps-dev)* Update build requirement from <2,>=1 to >=1.5.0,<2 in /apps/ai
- *(deps)* Bump pillow from 12.1.1 to 12.2.0 in /apps/ai
- *(deps)* Bump pillow from 12.1.1 to 12.2.0 in /apps/ai
- *(deps)* Bump lapin from 4.4.0 to 4.6.0 in /apps/server
- *(deps)* Bump lapin from 4.4.0 to 4.6.0 in /apps/server
- *(deps)* Bump axum from 0.8.8 to 0.8.9 in /apps/server
- *(deps)* Bump axum from 0.8.8 to 0.8.9 in /apps/server
- *(deps)* Bump uuid from 1.23.0 to 1.23.1 in /apps/server
- *(deps)* Bump uuid from 1.23.0 to 1.23.1 in /apps/server
- *(deps)* Bump go_router from 17.1.0 to 17.2.2 in /apps/mobile
- *(deps)* Bump go_router from 17.1.0 to 17.2.2 in /apps/mobile
- *(deps)* Bump image_picker from 1.2.1 to 1.2.2 in /apps/mobile
- *(deps)* Bump image_picker from 1.2.1 to 1.2.2 in /apps/mobile
- *(ai)* Migrate from conda to uv
- *(android)* Configure gradle properties for flutter migration
- *(core)* Downgrade python version to 3.11
- Add update and clean tasks to moon config
- *(ci)* Update github action versions

### 🐛 Bug Fixes

- *(server)* /refresh
- *(server)* Transaction closure error in TriggerAnalysis, json tags for Marshal in TriggerAnalysis
- *(server)* GetVideoInfoByUserID -> GetCompletedVideoInfoByUserID
- *(server)* Update entry point path in dockerfile

### 👷 Continuous Integration

- *(ai)* Update workflow for uv migration
- *(hooks)* Update file staging logic in pre-commit hook
- *(server)* Migrate backend from rust to go
- *(github)* Add automated dev to staging synchronization workflow
- *(workflow)* Migrate dev-to-production to staging-to-main
- *(deploy)* Update release action configuration
- *(docs)* Trigger wiki update from staging pipeline
- *(ci)* Update actions and adjust build steps

### 💼 Other

- Revert "docs: update "index", "drafts", "client-needs-and-functional-scope", "context-audit-compliance", "costs" (+103 more)"

This reverts commit 8c0f0f28db48f2eb7893b98c62ad4a0024e930fa.

### 📚 Documentation

- Update conda references to uv across documentation
- *(instructions)* Update section numbering in documentation
- *(ai)* Correct typos in coordinator documentation
- *(ai)* Update agent instructions and workspace config for go
- Update "index", "drafts", "client-needs-and-functional-scope", "context-audit-compliance", "costs" (+103 more)
- *(template)* Update pull request instructions and cleanup sections

### 🔀 Merges

- "dev" into "dev"
- "dev" into "refactor/server-language"
- "refactor/server-language" into "dev"
- `dev` into `main`

### 🚀 Features

- *(server)* /users fully implemented
- *(server)* /signup, /login
- *(server)* /logout
- *(server)* Middleware auth, guest, admin, user
- *(server)* /refresh
- *(server)* Delete old server
- *(server)* Add /upload-url with validation but no logic
- *(server)* /videos/upload-url
- *(server)* /upload-done/:id without minIO verification
- *(server)* /upload-done/:id
- *(server)* POST /analysis/
- *(server)* GET /analysis
- *(server)* /signup act now as SignupAndLogin
- *(server)* Cron for delete expired sessions, upload but depends on a custom postgres image
- *(server)* /videos/download-url/:id
- *(docs)* Add Go vs Rust functional comparison guideremove: remove old useless folder
- *(deps)* Update app requirements with specific version constraints for dependencies
- *(ai)* Update generative model to gemini-3.1-flash-lite-preview
- *(hooks)* Add automated graphify rebuild hooks
- *(build)* Add docker orchestration tasks to moon config
- *(utils)* Add header management script
- *(sonar)* Integrate sonarqube for static analysis
- *(scripts)* Improve author identification and rename sonarqube setup script
- *(tasks)* Add commit task definition to moon.yml
- *(agents)* Add AI command and skill definitions for documentation and graphify workflows

### 🚚 Restructuring

- *(ci)* Rename dev-to-staging workflow file

### 🚜 Refactoring

- *(server)* Update minio client implementation
- *(agents)* Consolidate squad and ai instructions
- *(server)* Migrate project language from rust to go
- *(server)* Migrate api gateway from rust to go
- *(moon)* Standardize task configurations and update dependencies
- *(infrastructure)* Consolidate docker-compose configurations
- *(ci)* Extract no-ci detection logic to reusable workflow

### 🧹 Maintenance

- *(docker)* Rename service containers to include project prefix
- *(mobile)* Update dependencies in pubspec.lock
- *(postgres)* Update shebang to env bash in init script
- *(docker)* Rename RUST_LOG to LOG_LEVEL
- *(docs)* Migrate backend stack documentation from rust to go
- *(moon)* Update task options and dependency ordering
- *(ci)* Update dependabot configuration
- *(config)* Standardize ignore files and clean up project structure
- *(build)* Update project ignore patterns and task dependencies
- *(server)* Add file headers to source code
- *(mobile)* Add standardized file headers and fix bug in header component
- *(ai)* Add project header documentation to source files
- *(git)* Exclude generated files from linguist statistics
- *(docs)* Update documentation for backend migration to go
- *(docs)* Update architecture documentation and ci workflows

## [0.1.12] - 2026-04-29

### ➖ Removals

- *(squad-template)* Remove outdated squad workflows and templates
- Delete obsolete MCP configuration file

### 🏗️ Build System

- *(deps)* Bump uuid from 1.22.0 to 1.23.0 in /apps/server
- *(deps)* Bump uuid from 1.22.0 to 1.23.0 in /apps/server
- *(deps)* Bump timm from 1.0.25 to 1.0.26 in /apps/ai
- *(deps)* Bump timm from 1.0.25 to 1.0.26 in /apps/ai
- *(deps)* Bump lapin from 4.3.0 to 4.4.0 in /apps/server
- *(deps)* Bump lapin from 4.3.0 to 4.4.0 in /apps/server
- *(deps-dev)* Bump @moonrepo/cli from 2.0.4 to 2.1.3
- *(deps-dev)* Bump @moonrepo/cli from 2.0.4 to 2.1.3
- *(deps)* Bump trimesh from 4.11.3 to 4.11.5 in /apps/ai
- *(deps)* Bump trimesh from 4.11.3 to 4.11.5 in /apps/ai
- *(deps)* Bump numpy from 2.4.3 to 2.4.4 in /apps/ai
- *(deps)* Bump numpy from 2.4.3 to 2.4.4 in /apps/ai
- *(deps)* Bump pandas from 3.0.1 to 3.0.2 in /apps/ai
- *(deps)* Bump pandas from 3.0.1 to 3.0.2 in /apps/ai
- *(deps)* Bump shared_preferences from 2.5.4 to 2.5.5 in /apps/mobile
- *(deps)* Bump shared_preferences from 2.5.4 to 2.5.5 in /apps/mobile
- *(deps)* Bump cupertino_icons from 1.0.8 to 1.0.9 in /apps/mobile
- *(deps)* Bump cupertino_icons from 1.0.8 to 1.0.9 in /apps/mobile
- *(deps)* Update moon version from 2.0.4 to 2.1.3 in .prototools

### 🐛 Bug Fixes

- Correct spelling and formatting errors in product documentation
- Update authors and status in action, alpha, and beta test plans; add PDF files for alpha and beta test plans
- *(docs)* Update path to git commit standards guide
- *(docs)* Update markdown guidelines with new version, authors, and language specifications
- *(.gitignore)* Update temporary file pattern to include all tmp files
- *(docs)* Add markdownlint directive to required header block in guidelines
- *(docs)* Update Table of Contents and add GitHub Issue Standards link

### 📚 Documentation

- *(portotype-pool-rex)* Create a REX for the prototype pool

### 🔀 Merges

- `dev` into `main`

### 🚀 Features

- Add new presentation for Block 1 in RNCP compliance documentation
- Update accessibility documentation and guidelines
- Enhance user experience with new features for ghost mode and onboarding
- Update AI pre-prompt documentation for version 1.3 and improve clarity
- Add functional roadmap documentation for project planning and execution
- Add catalogue of features to product documentation
- Add Alpha and Beta Test Plans for Ascension project
- *(docs)* Add GitHub Issue Standards Guide to define issue creation and management standards
- *(docs)* Add Copilot instructions to define behavior and guidelines for usage
- *(docs)* Add modern logo image for enhanced branding
- *(docs)* Update issues-to-create document with comprehensive backlog audit and action plan

### 🚜 Refactoring

- Remove submodule handling from pre-commit hook and update file listing command

## [0.1.11] - 2026-03-18

### 🎨 Styling

- Reformat the code

### 🏗️ Build System

- *(deps)* Bump actions/create-github-app-token from 2 to 3
- *(deps)* Bump actions/create-github-app-token from 2 to 3
- *(deps)* Bump appleboy/scp-action from 0.1.7 to 1.0.0
- *(deps)* Bump appleboy/scp-action from 0.1.7 to 1.0.0
- *(deps)* Bump black from 26.3.0 to 26.3.1 in /apps/ai
- *(deps)* Bump black from 26.3.0 to 26.3.1 in /apps/ai
- *(deps)* Bump wandb from 0.25.0 to 0.25.1 in /apps/ai
- *(deps)* Bump wandb from 0.25.0 to 0.25.1 in /apps/ai
- *(deps)* Bump huggingface-hub from 1.6.0 to 1.7.1 in /apps/ai
- *(deps)* Bump huggingface-hub from 1.6.0 to 1.7.1 in /apps/ai
- *(deps)* Bump lapin from 4.2.1 to 4.3.0 in /apps/server
- *(deps)* Bump lapin from 4.2.1 to 4.3.0 in /apps/server
- *(deps)* Bump networkx from 3.2.1 to 3.6.1 in /apps/ai
- *(deps)* Bump networkx from 3.2.1 to 3.6.1 in /apps/ai
- *(deps)* Bump tracing-subscriber in /apps/server
- *(deps)* Bump tracing-subscriber from 0.3.22 to 0.3.23 in /apps/server
- *(deps)* Bump openssl from 0.10.75 to 0.10.76 in /apps/server
- *(deps)* Bump openssl from 0.10.75 to 0.10.76 in /apps/server
- *(deps)* Bump bcrypt from 0.17.1 to 0.19.0 in /apps/server
- *(deps)* Bump bcrypt from 0.17.1 to 0.19.0 in /apps/server
- *(deps)* Bump fl_chart from 1.1.1 to 1.2.0 in /apps/mobile
- *(deps)* Bump fl_chart from 1.1.1 to 1.2.0 in /apps/mobile
- *(deps)* Bump video_player from 2.11.0 to 2.11.1 in /apps/mobile
- *(deps)* Bump video_player from 2.11.0 to 2.11.1 in /apps/mobile
- *(deps)* Bump just_audio from 0.9.46 to 0.10.5 in /apps/mobile
- *(deps)* Bump just_audio from 0.9.46 to 0.10.5 in /apps/mobile

### 🐛 Bug Fixes

- *(git-hooks)* Fix moon error with reformate code
- *(reformat_code)* Add interactive mode to reformat script
- Update VPS deploy condition to include repository check
- Update dependabot schedule from weekly to monthly for all package ecosystems
- Update branch validation logic to allow main, dev, and dependabot branches
- Update AppLocalizations usage in video upload component for better readability

### 💼 Other

- Details: see detailled commit below
feat(auth): enhance login, logout, and register endpoints with OpenAPI documentation

- Added OpenAPI annotations to the login, logout, and register handlers.
- Updated request and response structs to include schema definitions.
- Improved documentation for authentication endpoints.

feat(user): add OpenAPI documentation for user management endpoints

- Annotated user creation, deletion, retrieval, listing, and updating endpoints with OpenAPI specs.
- Enhanced request and response structs with schema definitions.

feat(video): document video upload URL endpoint with OpenAPI

- Added OpenAPI annotations for the get upload URL handler.
- Updated request and response structs to include schema definitions.

docs: update various documentation files with last updated dates and versioning

- Updated last modified dates and version numbers across multiple documentation files.
- Added Swagger UI guide for API documentation access and maintenance.
- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into dev
- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into dev

### 📚 Documentation

- *(resources)* Update and add PPTs
- Add RNCP resources and update draft documentation
- Delete docs/30-compliance/rncp/block-1/audit/README
- Delete docs/30-compliance/rncp/block-1/audit/stack-summary
- Delete docs/30-compliance/rncp/block-1/audit/tech-stack
- Delete docs/90-drafts/bloc-1
- Update M1 oral slides document with new version and additional content

### 🔀 Merges

- `dev` into `main`

### 🚀 Features

- Add comprehensive documentation for RNCP Block 1 including risk evolution, audit overview, tech stack decisions, and observables evidence matrix
- Add Mobile Accessibility Implementation Guide and update RNCP Block 1 documentation
- Implement accessibility features and localization support
- Enhance EIP project objectives documentation with detailed mandatory and complementary objectives

### 🚜 Refactoring

- *(reformat_code)* Remove unnecessary environment variable exports
- Move docs files

## [0.1.10] - 2026-03-12

### ➕ Additions

- Human detection, segmentation, and FOV estimation tools

### 🎨 Styling

- *(auth)* Suppress dead_code warnings in auth module
- *(docs)* Standardize formatting of metadata across multiple documents
- *(mobile)* Wrap if statements in blocks in auth_service
- Reformat the code
- Lint and reformat code

### 🏗️ Build System

- *(ios)* Add audio_session and just_audio pods to Podfile.lock

### 🐛 Bug Fixes

- *(http)* Change root route response status from NO_CONTENT to OK
- *(upload)* Replace hard-coded user ID with AuthService
- *(server)* Set set _role = null alongside _userId/_username/_email to keep state consistent
- *(server)* Add more error handling

### 💼 Other

- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into feat/ai-sam3d
- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into feat/ai-sam3d

### 🔀 Merges

- "feat/ai-sam3d" into "dev"
- "feat/profile-page" into "feat/stats-page"
- "feat/stats-page" into "dev"
- "dev" into "feat/pose-analysis-hints"
- "feat/pose-analysis-hints" into "dev"
- `dev` into `main`

### 🚀 Features

- *(analysis)* Add real-time progress tracking for video analyses
- SAM 3D Body integration and utilities for pose analysis
- *(audio)* Implement audio service for background music playback
- *(stats)* Add analysis history list to stats page
- *(auth)* Persist username, email, role and add getUser endpoint
- *(profile)* Implement full profile page with edit support and API sync
- *(mobile)* Add refresh every time in stats
- *(mobile)* Add more error checks
- *(env)* Add GEMINI_API_KEY to environment configuration
- *(ai)* Integrate Gemini API for climbing advice and enhance data summarization
- Add example-2 post-analysis video to the project
- Add Google Generative AI dependency and enhance climbing advice generation
- Add hints column to analyses and update related models and handlers
- Integrate coaching hints feature with markdown support in analysis page
- Enhance video upload and analysis screens with improved UI and functionality
- Update audio service to disable music by default and adjust video player volume during analysis

### 🚜 Refactoring

- *(http)* Simplify root route definition by removing unnecessary middleware layers
- Remove unused pose analysis backup module

### 🧹 Maintenance

- Remove sam-3d-body subproject

## [0.1.9] - 2026-03-11

### 🐛 Bug Fixes

- *(analyze)* Correct frame skipping logic and add null check for RGB frame
- *(ai)* Fix increment logic to ensure proper frame skipping.
- *(pose_analysis)* Optimize angle calculation logic and adjust frame processing parameters
- *(moon.yml)* Update task dependencies to ensure setup-git-config is prioritized
- *(docker)* Update runtime base image from debian:bookworm-slim to debian:trixie-slim

### 💼 Other

- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into dev

### 🔀 Merges

- "fix/media-pipe-angles" into "dev"
- `dev` into `main`

### 🚀 Features

- *(pose_analysis)* Add angle calculations for elbows, knees, and hips in pose analysis
- *(hooks)* Add post-checkout hook for branch name compliance check
- *(git)* Add setup-git-config task and reorganize project tasks
- *(memos)* Add memos for 10/02, 16/02, 02/03, and 09/03 with updates and tasks
- *(auth)* Add settings button to login and register pages
- *(analysis)* Synchronize skeleton overlay with video playback and enhance angle stats display
- *(analysis)* Enhance video frame synchronization and add angles toggle in skeleton viewer

### 🚜 Refactoring

- (pose_analysis): simplify angle calculation and improve frame processing logic
- *(api)* Replace backend URL key with default backend URL constant
- *(login)* Remove unused header import from login_page.dart
- *(analysis)* Remove average angle display from analysis summary card
- *(format)* Remove unnecessary exit code option from format task
- *(pose_analysis)* Improve code readability by formatting angle calculations and logging statements
- *(analysis)* Rename lookahead constant and simplify joint color definitions

## [0.1.8] - 2026-03-10

### 🎨 Styling

- Apply code formatting to server and mobile modules

### 🏗️ Build System

- *(deps)* Bump lapin from 2.5.5 to 4.2.1 in /apps/server
- *(deps)* Bump docker/setup-buildx-action from 3 to 4
- *(deps)* Bump docker/setup-buildx-action from 3 to 4
- *(deps)* Bump actions/github-script from 7 to 8
- *(deps)* Bump actions/github-script from 7 to 8
- *(deps)* Bump Andrew-Chen-Wang/github-wiki-action
- *(deps)* Bump Andrew-Chen-Wang/github-wiki-action from 5.0.3 to 5.0.4
- *(deps)* Bump lapin from 2.5.5 to 4.2.1 in /apps/server
- *(deps)* Bump fl_chart from 0.69.2 to 1.1.1 in /apps/mobile
- *(deps)* Bump fl_chart from 0.69.2 to 1.1.1 in /apps/mobile

### 🐛 Bug Fixes

- *(test)* Correct username validation boundary test input
- *(project)* Update bundle identifier and remove unnecessary name entry
- *(script)* Correct regex for kebab-case validation in branch naming
- *(imports)* Update import paths for app_constants in auth_service and api_service
- *(rabbitmq)* Convert constants to owned strings for queue and exchange declarations

### 💼 Other

- Merge branch 'dev' into dependabot/cargo/apps/server/dev/lapin-4.2.1

### 🔀 Merges

- "feature/authentication" into "dev"
- `dev` into `main`

### 🚀 Features

- *(http)* Change health check route from '/healthz' to '/'
- Update app branding and identifiers to Ascension
- *(docker)* Update comments for clarity on sqlx cache and migrations
- *(auth)* Implement user authentication and registration
- *(auth)* Expose user_id in auth response and improve validation
- *(auth)* Implement login and register pages with routing
- *(auth)* Replace placeholder icon with logo image
- *(profile)* Add logout button with confirmation dialog
- *(deploy)* Add VPS deployment workflow and production Docker Compose configuration

## [0.1.7] - 2026-03-09

### 🔀 Merges

- `dev` into `main`

### 🚀 Features

- *(docker)* Add perl and make installation in the build stage

## [0.1.6] - 2026-03-09

### ➕ Additions

- *(mobile)* Add AppConstants class to core/constants
- *(mobile)* Add typed failure classes to core/error

### 🎨 Styling

- *(mobile)* Apply dart formatter to mobile files

### 🏗️ Build System

- *(mobile)* Add shared_preferences_foundation pod
- *(mobile)* Add equatable dependency
- *(deps)* Bump mockall from 0.13.1 to 0.14.0 in /apps/server
- *(deps)* Bump uuid from 1.21.0 to 1.22.0 in /apps/server
- *(deps)* Bump docker/login-action from 3 to 4
- *(deps)* Bump docker/login-action from 3 to 4
- *(deps)* Bump docker/build-push-action from 6 to 7
- *(deps)* Bump docker/build-push-action from 6 to 7
- *(deps)* Bump actions/create-github-app-token from 1 to 2
- *(deps)* Bump actions/create-github-app-token from 1 to 2
- *(deps)* Bump everlytic/branch-merge from 1.1.2 to 1.1.5
- *(deps)* Bump everlytic/branch-merge from 1.1.2 to 1.1.5
- *(deps)* Bump numpy from 2.4.2 to 2.4.3 in /apps/ai
- *(deps)* Bump numpy from 2.4.2 to 2.4.3 in /apps/ai
- *(deps)* Bump actions/checkout from 4 to 6
- *(deps)* Bump actions/checkout from 4 to 6
- *(deps)* Update black requirement in /apps/ai
- *(deps)* Update black requirement from <24,>=23.3.0 to >=23.3.0,<27 in /apps/ai
- *(deps)* Bump tokio from 1.49.0 to 1.50.0 in /apps/server
- *(deps)* Bump tokio from 1.49.0 to 1.50.0 in /apps/server
- *(deps)* Bump uuid from 1.21.0 to 1.22.0 in /apps/server
- *(deps)* Bump mockall from 0.13.1 to 0.14.0 in /apps/server

### 🐛 Bug Fixes

- *(ai)* Align moon/docs on ai-env and add dockerignore
- *(ai)* Remove --force option from conda environment setup and delete unused sam-3d-body subproject
- *(server-user)* Improve error handling in get_user method for parsing user data
- *(scripts)* Uncomment AI formatting command in reformat_code script
- *(dependencies)* Add black dependency for code formatting
- *(postgresql)* Cast per_page to i64 for correct pagination offset
- *(server)* Field of service and repo are now Arc
- *(server)* Change generics to dyn
- *(server)* Fix compilation
- *(auth)* Change UUID conversion from slice to string parsing in get_user_by_token
- *(postgresql)* Reorder LIMIT and OFFSET in user query for correct pagination
- *(auth)* Change response status from FORBIDDEN to UNAUTHORIZED in auth middleware
- *(srver-lint)* Fix lint errors in the server and add #[allow(dead_code)] to unused things
- *(tests)* Wrap MockUserRepository in Arc for thread safety in service tests
- *(env)* Update MinIO endpoint and RabbitMQ URL in .env.example
- *(docker)* Add wget installation and download MediaPipe PoseLandmarker model
- *(pyproject)* Add missing comma for psycopg2-binary dependency
- *(android)* Add INTERNET permission and enable cleartext traffic in AndroidManifest.xml
- *(pubspec)* Update http dependency to direct main in pubspec.lock
- *(cargo)* Format dependencies and add missing entries
- *(env)* Correct database URI and update RabbitMQ/MinIO environment variables in docker-compose
- *(main)* Add newline at end of file in main.dart
- *(docker)* Add wget command to download pose_landmarker.task and update dev task for no-capture-output
- *(check-branch)* Update regex to allow slashes in kebab-case validation
- *(server)* Return error instead of panic
- *(video)* Suppress dead code warnings for NotFound variant and minio_bucket field
- Correct indentation for args in dev task in moon.yml
- Remove unnecessary '--capture-output' argument from dev task in moon.yml
- Update import paths for pose_analysis module and adjust BASE_DIR calculation
- *(api)* Simplify response handling by removing unnecessary data extraction
- *(video_upload)* Extend polling duration for analysis completion and improve error handling
- Add worker.pid to .gitignore to prevent tracking of PID files
- *(moon.yml)* Add --no-capture-output flag to dev, lint, test, and format tasks
- *(workflow)* Prevent AI review job from running on dependabot branches
- *(docker)* Update Dockerfile to include sqlx offline query cache and migrations

### 💼 Other

- Merge branch 'dev' into server/auth-middleware
- Merge branch 'dev' into server/auth-middleware
- [no-ci] details:
- feat(settings): add settings page to configure backend URL and persist it
- feat(header): enhance header component to include action buttons
- fix(api): update ApiService to load and set backend URL from SharedPreferences
- chore(env): update SERVER_PORT and add BACKEND_URL to .env.example
- chore(moon): modify build tasks to include backend URL as a dart define
- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into dev
- Merge branch 'dev' into dependabot/cargo/apps/server/dev/uuid-1.22.0
- Merge branch 'dev' into dependabot/cargo/apps/server/dev/mockall-0.14.0
- Merge branch 'dev' into feat/server-auth-middleware

### 📚 Documentation

- Add developer quickstart and environment strategy logs
- Update docs/README
- Update docs/README
- Update README and architecture guide with test instructions and new resource structure
- Add comprehensive developer guide for server setup and API routes

### 🔀 Merges

- "dev" into "feat/ai-conda-setup"
- "feat/ai-conda-setup" into "dev"
- "ci/conda-replacement" into "dev"
- "server/user-crud" into "dev"
- "feat/server-user-crud" into "dev"
- "ci/auto-ai-review" into "dev"
- 'server/auth-middleware' into dev
- "server/auth-middleware" into "dev"
- "feat/server-auth-middleware" into "dev"
- "test/link-all" into "dev"
- Branch 'dev' into refactor/mobile-architecture
- "refactor/mobile-architecture" into "dev"
- `dev` into `main`

### 🚀 Features

- *(ai)* Shift to conda-based dev environment and dual-env strategy
- *(ai)* Enhance AI environment setup and documentation alignment with conda contract
- *(ci)* Replace Python setup with Conda and update caching for environment files
- *(ci)* Export CONDA_EXE for moon tasks and update caching for conda environment
- *(docs)* Add .docignore file and update documentation prompt for ignored files
- *(docs)* Add RNCP documentation with detailed competency blocks and evaluation modalities
- *(server)* Hexagonal architecture base
- *(api)* Implement generic API response structures for success and error handling
- *(env)* Add database URL and JWT key to example environment file
- *(server-user-routes)* Create user CRUD file handler and update routing
- *(server-user)* Add UpdateUserInput and UpdateUserOutput structures with error handling
- *(server-user)* Add ListUsersInput and ListUsersOutput structures with error handling
- *(server-user-routes)* Update user routes to correct HTTP methods for CRUD operations
- *(server-user)* Add user retrieval and listing methods to UserService
- *(server-user)* Add ListUsersInput, ListUsersOutput, GetUserInput, GetUserOutput structures with error handling
- *(server-user)* Add DeleteUserInput, DeleteUserOutput, and DeleteUserError structures with error handling
- *(server-user)* Add CreateUserInput, GetUserInput, UpdateUserInput, and DeleteUserInput structures with error handling
- *(server-user)* Implement update user functionality with error handling
- *(server-user)* Implement get user functionality with error handling and response struct
- *(server-user)* Implement delete user functionality with error handling and response struct
- *(server-user)* Add get user route to API for retrieving user details
- *(server-user)* Enhance GetUserOutput structure with detailed user fields and conversion from User
- *(server-user)* Refactor get_user method to accept GetUserData struct
- *(server-user)* Update update_user method to use axum's StatusCode for response
- *(server-user)* Implement the list user handler
- *(server-user)* Add ListUserOutput struct and update ListUsersOutput to use it
- *(docs)* Add developer guides for adding routes and implementing CRUD operations
- *(server-user)* Update repository methods to return specific output structs for user operations
- *(server-user)* Implement get_user method and update user repository methods to return specific output structs
- *(server-user)* Update user routes to use path parameters for user ID
- *(ai)* Add format task to run black for code formatting
- *(moon)* Separate format and format-check tasks in moon.yml
- *(ai)* Add black configuration for code formatting in pyproject.toml
- *(user)* Implement user CRUD operations in postgresql.rs
- *(user)* Update ListUsers structs to use Option for page and per_page
- *(user)* Return full user list in ListUsersOutput
- *(user)* Rename limit to per_page in ListUsersParams for clarity
- *(user)* Enhance list_users and update_user/delete_user methods for better error handling and pagination
- *(dependencies)* Add mockall and update dev-dependencies in Cargo.toml
- *(user)* Add SQLX_OFFLINE environment variable for offline mode and clean up user model methods
- *(moon.yml)* Include .sqlx/**/* in inputs for build, build-release, test, and lint tasks
- *(postgresql)* Enhance user listing and deletion error handling
- *(postgresql)* Enhance user listing and deletion error handling
- *(images)* Add team photos for Christophe Vandevoir, Gianni Tuero, Lou Pellegrino, Nicolas Toro, and Olivier Pouech
- *(workflows)* Add Squad AI PR review workflow and enhance routing comment logic
- *(workflows)* Update permissions to include models read access
- *(workflows)* Enhance AI review with inline suggestions and improved comment handling
- *(workflows)* Enhance AI review comments with domain-specific details
- *(ci)* Add no-ci detection to skip CI checks based on commit message prefix
- *(server)* Basic auth middleware need UserRepository
- *(server)* Log
- *(server)* Middleware start of implementation
- *(server)* Middleware auth error
- *(server)* AuthService
- *(sqlx)* Add SQL queries for user operations (insert, delete, select, update)
- *(consumer)* Implement RabbitMQ connection retries and improve error handling
- *(pose_analysis)* Optimize frame processing and memory usage in analyze function
- *(video_upload)* Implement video upload and analysis workflow with error handling
- *(migrations)* Add videos and analyses tables with triggers for updated_at
- *(server)* Add video and analysis services with RabbitMQ integration
- *(mobile)* Add video analysis feature with skeleton overlay and angle charts
- *(ci)* Enhance no-CI detection with additional prefixes for commit messages
- *(ai)* Add example video files for AI application
- *(ai)* Reimplement old ai as backup
- *(docs)* Add comprehensive issues-to-create documentation for CI/CD workflows
- *(server)* Rate limiter
- *(server)* Clean backend
- Implement vision.skeleton pipeline for AI worker with video analysis and event publishing
- Add logs in consumer AI
- *(ai)* Add type hint for RABBITMQ_RETRY_DELAY to improve code clarity.
- *(ai)* Consider using a configuration file or environment variable for RABBITMQ_RETRY_DELAY to improve flexibility
- *(ai)* Nsure default retry delay is explicitly set as an integer
- Add initial __init__.py file to the ai module
- *(consumer, pose_analysis)* Implement PID lock mechanism and enhance logging
- Feat(dependabot): add npm update schedule for weekly checks on Mondays at 09:00
chore: update moon version to 2.0.4 in .prototools
feat: add package.json for dependency tracking with @moonrepo/cli
- *(docker)* Add healthcheck for PostgreSQL service and ensure dependencies are healthy for server
- *(ci)* Enable AI image build and push in GitHub Actions workflow
- *(ai)* Add download-model task to fetch pose_landmarker model
- *(mobile)* Add build task for platform-specific Flutter builds
- *(server)* Add install-sqlx and migrate tasks to moon.yml
- *(docs)* Add various resource files including images, audio, and PDFs
- *(scripts)* Refactor model download and build tasks into separate scripts

### 🚚 Restructuring

- *(mobile)* Move api_service from services to core/network
- *(mobile)* Move components to shared/components and update imports
- *(mobile)* Migrate pages to feature-based architecture
- *(ai)* Move example videos and results

### 🚜 Refactoring

- *(server-user)* Update error handling in user service methods
- *(server-user)* Remove unused error variant and clean up CreateUserHttpRequestBody
- *(server-user)* Clean up imports in list_users handler
- *(server-user)* Remove unused imports and parameters in user handlers and repository methods
- *(user)* Clean up code formatting and improve readability across user-related modules
- *(mobile)* Move layout to shared directory and extract app theme
- *(mobile)* Centralize backend URL config in AppConstants
- Simplify code formatting in video upload and analysis view pages
- Streamline function signatures and error handling across various modules
- Update task arguments in moon.yml and enhance pyproject.toml configuration
- *(tests)* Update user model imports and adjust mock repository methods

### 🧪 Testing

- *(server-user-crud)* Add comprehensive user model and service tests with mock repository

### 🧹 Maintenance

- *(squad)* Metadata maintenance and documentation cleanup
- *(squad)* Make Ralph propose review fix suggestions without auto-apply
- *(squad)* Enforce H1 reviewer title format in Ralph reviews
- *(keywords)* Add 'tests' and 'temp' keywords to keywords.txt
- Update dependencies in Cargo.lock and Cargo.toml; add serde feature to uuid

## [0.1.5] - 2026-03-03

### ➕ Additions

- Create a template for commit messages with guidelines

### ➖ Removals

- *(github-actions)* Remove useless GitHub actions workflows for squad
- Delete obsolete squad promote workflow
- *(docs-draft)* Remove useless draft

### 🏗️ Build System

- *(deps)* Bump actions/download-artifact from 4 to 8
- *(deps)* Bump actions/download-artifact from 4 to 8
- *(deps)* Bump actions/setup-python from 5 to 6
- *(deps)* Bump actions/setup-python from 5 to 6
- *(deps)* Bump actions/cache from 4 to 5
- *(deps)* Bump actions/cache from 4 to 5
- *(deps)* Bump actions/checkout from 4 to 6
- *(deps)* Bump actions/checkout from 4 to 6
- *(deps)* Bump actions/upload-artifact from 4 to 7
- *(deps)* Bump actions/upload-artifact from 4 to 7
- *(deps)* Update pytest requirement in /apps/ai
- *(deps)* Update pytest requirement from <9,>=8 to >=8,<10 in /apps/ai

### 🐛 Bug Fixes

- Update CODEOWNERS formatting for improved readability
- Improve formatting and organization of sync squad labels workflow
- Enhance formatting and organization in workflow files
- Add GITHUB_ACTIONS environment variable to squad label cleaner workflow
- Improve formatting and organization in squad issue assign workflow
- Remove obsolete squad heartbeat workflow
- Update agent names in history.json for team formation
- Resolve conflicts by keeping deletions
- Correct tests directory pattern in CODEOWNERS
- Update docs directory path in generate_wiki script
- Update team formation to include an additional agent
- Streamline wiki generation process and improve path mapping
- Update commit guidelines version to v1.1
- Correct role title for Ridjan from "Testing" to "Tester"
- Improve wiki generation script by ensuring directory cleanup and refining path mapping
- Update GitHub Actions & Hooks Guide to reflect version 1.1 and add new workflows
- Update Docker images to specific versions for MinIO, RabbitMQ, and PostgreSQL
- Update AI pre-prompt documentation for English and French versions to reflect latest project status and version
- Add conditional check for repository in sync-labels job

### 💼 Other

- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into dev

### 📚 Documentation

- Update docs/rncp/oral_25-02_ppt_content
- Update docs/rncp/oral_25-02_ppt_content
- Update commit standards guide and keywords for agents

### 🔀 Merges

- "fix/agents-setup" into "dev"
- `dev` into `main`

### 🚀 Features

- Add Ridjan's charter, history, and team role as Tester with responsibilities and testing stack
- Add script to generate wiki from markdown files and special files
- Add 'dependabot' keyword to keywords list
- Add squad pull request review workflow for automatic domain routing
- Add squad label cleaner workflow for managing label exclusivity
- Add GitHub Actions workflow for automatic wiki updates
- Update CI configuration to ignore documentation files and bump test_api version
- Add context, audit, and compliance documentation for workshop deliverable
- Add foundational documentation including Code of Conduct, Contributing guidelines, Security Policy, Support resources, and project overview
- Update documentation files with new headers and table of contents

### 🚚 Restructuring

- *(squad)* Rename squad to epitech squad
- *(docs)* Move some docs files in prototype pool directory

## [0.1.4] - 2026-03-03

### ➖ Removals

- *(docs)* Convert docs submodule to regular directory
- *(ai)* Delete obsolete placeholder and standalone mediapipe script

### 🎨 Styling

- *(mobile)* Format code for better readability in VideoUpload component

### 🏗️ Build System

- *(mobile)* Register generated flutter plugins for new packages
- *(mobile)* Integrate cocoapods for ios and macos native dependencies

### 🐛 Bug Fixes

- Bad commentary for mediapipe
- *(ai)* Restore garbled analyze assignment and comment out heartbeat
- *(ai)* Increase default FPS to 60 for video analysis
- *(ai)* Remove unused `import sys` from pose_analysis.py
- *(ai)* Remove duplicate fps fallback caused by bad rebase

### 💼 Other

- Merge branches 'dev' and 'dev' of github.com:Ascension-EIP/Ascension into dev
- Merge decision inbox, record orchestration log
- Ignore pose_landmarker.task mediapipe model file
- Apps/ai/pose_analysis.py

### 📚 Documentation

- *(ai)* Document vision.skeleton pipeline and update system overview
- Update AI layer documentation and orchestration logs for vision.skeleton pipeline
- *(squad)* Log Ralph round 1 — PR #36 review & lint fix

### 🔀 Merges

- "feature/video-upload" into "dev"
- "feat/api-squad" into "dev"
- "test/ai-reviewer" into "dev"
- `dev` into `main`

### 🚀 Features

- *(ai)* Initialize ai worker with rabbitmq integration
- Initialize Squad team for Ascension
- Add workflows for squad management and release processes
- Add Squad PR review workflow and CODEOWNERS
- *(dependabot)* Add configuration for automated dependency updates
- Add mediapipe for a vid with json out
- *(mobile)* Add VideoUpload component with picker and player preview
- *(ai)* Implement vision.skeleton pipeline

### 🚜 Refactoring

- Rename Squad agents to team member names
- *(ai)* Replace LANDMARKS dict with LM class and add body connections
- *(docker)* Switch all services to env_file and add missing env vars

## [0.1.3] - 2026-03-02

### 🎨 Styling

- *(mobile)* Collapse scaffold constructors to single line in home pages
- *(mobile)* Enforce dark theme and update surface color
- *(mobile)* Remove font weight from header subtitle
- *(mobile)* Use theme color as default for header title and description
- *(mobile)* Format color assignment for description text in Header component

### 🐛 Bug Fixes

- *(layout)* Set default current index to home page
- *(deploy)* Set fetch-depth to 0 for checkout steps
- *(ci)* Update fetch steps to ensure full git history in CI workflows
- *(ci)* Remove redundant git fetch steps and update format/lint commands
- *(workspace)* Update VCS configuration by removing remoteCandidates and ensuring git manager is set
- *(ci)* Clear moon cache before caching Cargo registry
- Correct class naming for StatsPage and UploadPage to follow Dart conventions
- *(ci)* Remove redundant moon cache cleanup and simplify format/lint commands
- *(mobile)* Correct class naming for UploadPage and StatsPage to follow Dart conventions
- *(ci)* Update server commands to run only on affected files based on main branch
- *(ci)* Update cache keys to use github.sha and clean stale moon states
- *(ci)* Improve moon cache cleanup and update format check command
- *(ci)* Remove caching and purge steps for moon store
- *(ci)* Remove affected flag and base reference from server commands
- *(ci)* Disable caching for Rust toolchain setup
- *(ci)* Remove caching for moon store and update moon version to 2.0.1
- *(ci)* Disable caching for moon toolchain setup and enable debug mode for AI dependencies
- *(ci)* Update server commands to use affected flag for format, lint, build, and test steps
- *(ci)* Update caching strategy and format commands for moon toolchain
- *(ci)* Enable recursive submodule checkout for Rust, Flutter, and AI jobs
- *(ci)* Remove affected flag from server, mobile, and AI commands in CI workflow
- *(docs)* Update subproject commit reference

### 💼 Other

- Merge branch 'dev' of github.com:Ascension-EIP/Ascension into dev

### 📚 Documentation

- Update README files for mobile and server subprojects; modify commit reference in docs

### 🔀 Merges

- `dev` into `main`

### 🚀 Features

- *(mobile)* Initialize app structure with navigation, theming, and pages
- *(auth)* Add login and register pages with placeholder text
- *(ci)* Add step to fetch base branch in CI workflows
- *(mobile)* Add app header component with logo and branding
- *(mobile)* Add Header component to profile, stats, and upload pages
- *(docker)* Add Docker Compose configuration for MinIO, RabbitMQ, and PostgreSQL services
- *(hooks)* Add pre-commit hook to update docs submodule
- *(hooks)* Enhance pre-commit hook to format code and update docs submodule

### 🚜 Refactoring

- *(mobile)* Make Header widget configurable with custom properties

### 🧹 Maintenance

- Add .claude/ to gitignore
- *(docs)* Update docs submodule
- *(docs)* Update docs submodule
- *(docs)* Update subproject commit reference

## [0.1.2] - 2026-02-23

### 🔀 Merges

- `dev` into `main`

### 🚀 Features

- Add Dockerfile for server build and runtime stages

## [0.1.1] - 2026-02-23

### 👷 Continuous Integration

- Refactor image prefix handling in deploy.yml to use output variables
- Add condition to branch checker to skip tags
- Add caching for Python virtual environment in AI job

### 🔀 Merges

- `dev` into `main`

## [0.1.0] - 2026-02-23

### 🐛 Bug Fixes

- Update destination repository name in GitHub Actions workflow and add condition for main branch
- Update repository mirroring configuration to use environment variables
- Update condition for mirror repository job to match specific repository name
- Update subproject commit reference in documentation
- Update subproject commit references in documentation and server files
- Improve pull command to include git pull before updating submodules
- Correct indentation for setup task in moon.yml

### 👷 Continuous Integration

- Add GitHub hooks for commit message and branch validation, along with CI workflow configuration
- Enhance CI/CD workflows; add server, mobile, and AI build steps; update deployment configurations
- Enhance CI workflow by adding caching for moon store and setting fetch depth for checkouts
- Add environment variables for server, mobile, and AI jobs; update workspace configuration
- Remove redundant environment variables from server, mobile, and AI jobs
- Update requirements and add install dependency for format task in mobile configuration
- Update Flutter version and add caching for pub dependencies; refine lint and test commands in AI configuration
- Update .gitignore to include Python-related files and directories
- Update test task to use pytest directly and allow failure
- Add pyproject.toml for AI component configuration
- Add build dependency to requirements for AI component
- Add placeholder test for AI component
- Add dummy test for continuous integration
- Update main.dart formatting, set language to dart in moon.yml, and bump test_api version in pubspec.lock
- Update moon installation steps to use setup-toolchain action with auto-install
- Update dev-to-production workflow to trigger on workflow_dispatch and merge dev branch directly
- Update moon.yml to add outputs for setup and install tasks

### 💼 Other

- Initial commit
- Organization's repositories added in submodules
- Merge branch 'main' of github.com:Ascension-EIP/Ascension
- Merge branch 'main' of github.com:Ascension-EIP/Ascension

### 📚 Documentation

- Update README with setup instructions and submodule management
- Update submodule reference to latest commit
- Update submodule reference to latest commit
- Update submodule references to latest commits in docs and server

### 🔀 Merges

- "dev" into "main"

### 🚀 Features

- Add initial project setup files including .env.example, docker-compose.yml, and justfile
- *(server)* Initialize Rust server with Axum framework
- Update moon configuration for AI, mobile, and server applications with environment variables and options
- Add submodule for documentation repository
- Update project configurations and add dotenv support for server; implement main entry point for AI service
- Add CI and deployment workflows; implement branch merging and token generation

### 🚜 Refactoring

- Sync submodules to correct branches (dev/main)

### 🧹 Maintenance

- Update subproject commit references in .env.example, docs, and server
- Update subproject commit reference in documentation
- Update subproject commit reference in documentation
- Update subproject commit reference in documentation
- Update subproject commit reference in documentation
- Remove submodules, convert to standalone repo
- Merge remote, keep submodules removed locally
- Update .gitignore and add workspace configuration for Moon
- Comment out mirror repository steps in action.yml and update workflow reference in dev.workflow.yml
- Update submodule commit reference in documentation
- Update .gitignore to include additional file types and directories; update submodule reference in docs

<!-- generated by git-cliff -->
