# Changelog

All notable changes to this project will be documented in this file.

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
