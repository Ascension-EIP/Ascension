# Kotlin Migration Guide (Mobile)

## Objectif

Migrer `apps/mobile` (Flutter) vers une app Android native Kotlin dans `apps/mobile-kotlin`.

## État actuel

Le socle Kotlin est en place avec :

- Auth login/register branchée sur `POST /v1/auth/login` et `POST /v1/auth/register`
- Persistance locale de session (tokens + profil + backend URL)
- Navigation protégée (auth gate)
- Main layout avec tabs : Home / Upload / Stats / Profile
- Paramètres backend URL (équivalent `SettingsPage` Flutter)
- Pipeline Upload fonctionnel (sélection vidéo + upload MinIO)
- Trigger analyse + polling des statuts (`queued` / `completed` / `failed`)
- Historique local des analyses par utilisateur (SharedPreferences)
- Écran `Stats` Kotlin alimenté par cet historique local
- Capture vidéo caméra Android depuis l’onglet Upload (`Filmer`)
- Vue détail d’une analyse depuis `Stats` (métriques + JSON formaté)
- Visualisation avancée de l’analyse (squelette + timeline + lecture)
- Audio de fond porté avec préférence persistante (`music_enabled`)
- Hints coaching rendus en blocs markdown-like (titres/listes) avec liens et timecodes cliquables
- Annulation d’upload/analyse en cours + retry sans re-sélection

## Mapping Flutter -> Kotlin

- `core/auth/auth_service.dart` -> `data/local/SessionStore.kt` + `data/AuthRepository.kt`
- `core/network/api_service.dart` -> `data/network/ApiEndpoints.kt` + `ApiClientFactory.kt`
- `features/auth/*` -> `AscensionApp.kt` (`LoginScreen`, `RegisterScreen`)
- `shared/layout/mobile_layout.dart` -> `AscensionApp.kt` (`MainRoot` + `NavigationBar`)
- `features/profile/*` -> `AscensionApp.kt` (`ProfileScreen`, `SettingsScreen`)
- `shared/components/video_upload.dart` -> `ui/upload/UploadScreen.kt` + `data/upload/UploadRepository.kt`
- `core/services/analysis_history_service.dart` -> `data/history/AnalysisHistoryService.kt`
- `features/stats/presentation/pages/stats_page.dart` -> `ui/stats/StatsScreen.kt`
- Détail d’analyse (nouveau en Kotlin) -> `ui/stats/StatsScreen.kt` (`AnalysisDetailScreen`)
- Viewer d’analyse (nouveau) -> `ui/analysis/AnalysisViewerScreen.kt`
- Audio service Flutter (`core/audio/audio_service.dart`) -> `core/audio/AudioService.kt`

## Ce qui reste à porter

1. Synchronisation serveur plus riche pour les Stats (agrégats avancés)
2. Finitions sécurité/perms autour des captures longues
3. Rendu markdown enrichi complet (gras/italique/tables et cas complexes)
4. Navigation multi-écrans plus structurée (NavHost dédié)

## Build

```bash
cd apps/mobile-kotlin
gradle :app:assembleDebug
```

## Stratégie recommandée

- Porter ensuite `Stats` + historique local
- Puis la vue d’analyse avancée (gros bloc UI)
- Finaliser par audio + polish UX
