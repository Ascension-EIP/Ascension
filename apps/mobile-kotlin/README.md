# Ascension Mobile Kotlin (Android)

Refonte Android native Kotlin (Jetpack Compose) de l'app mobile Ascension.

## Ce qui est déjà porté

- Authentification (login/register) via l'API backend
- Persistance de session (tokens + profil) en local
- Navigation protégée (auth gate)
- Layout principal avec barre de navigation (Home / Upload / Stats / Profile)
- Page Paramètres pour modifier l'URL du backend
- Upload vidéo (sélection fichier), envoi MinIO et déclenchement d’analyse
- Polling d’analyse côté mobile avec affichage des statuts/progression
- Annulation d’upload/analyse en cours + retry rapide après erreur
- Stats + détail d’analyse avec visualisation squelette/timeline
- Musique de fond Ascension avec toggle persistant dans Paramètres
- Affichage des hints coaching enrichi (titres/listes) avec liens + timecodes cliquables

## Stack

- Kotlin + Jetpack Compose
- Navigation Compose
- Retrofit + OkHttp + Gson
- Coroutines + StateFlow

## Build / Run

Depuis `apps/mobile-kotlin` :

```bash
gradle :app:assembleDebug
gradle :app:installDebug
```

Puis lancer l'application `Ascension` sur un émulateur Android.

## Notes migration

Cette base remplace le socle Flutter et il reste surtout les écrans avancés :

- Historique avancé des stats
- Hints markdown/coach rendus riches (styles markdown avancés à compléter)
- Raffinements UX upload supplémentaires (gestion queue/reprise avancée)
