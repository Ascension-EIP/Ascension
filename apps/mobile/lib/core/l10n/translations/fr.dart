// @date 2026-11-13
// @file fr.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done / French (fr) translations.
const Map<String, String> frTranslations = {
  // Navigation
  'nav.home': 'Accueil',
  'nav.sessions': 'Sessions',
  'nav.training': 'Entraînement',
  'nav.profile': 'Profil',

  // Common
  'common.appName': 'Ascension',
  'common.loading': 'Chargement...',
  'common.error': 'Une erreur est survenue',
  'common.retry': 'Réessayer',
  'common.cancel': 'Annuler',
  'common.save': 'Enregistrer',
  'common.yes': 'Oui',
  'common.no': 'Non',
  'common.continueLater': 'Continuer plus tard',
  'common.notAvailable': 'Non disponible pour le moment. Cette fonctionnalité sera bientôt disponible sur Ascension.',

  // Auth
  'auth.login': 'Connexion',
  'auth.register': 'Inscription',
  'auth.signIn': 'Connexion',
  'auth.signUp': 'Inscription',
  'auth.slogan': 'Visualiser l\'invisible !',
  'auth.forgotPassword': 'Mot de passe oublié ?',
  'auth.identifier': 'Email ou nom d\'utilisateur',
  'auth.email': 'Email',
  'auth.password': 'Mot de passe',
  'auth.confirmPassword': 'Confirmer le mot de passe',
  'auth.firstName': 'Prénom',
  'auth.lastName': 'Nom',
  'auth.username': "Nom d'utilisateur",
  'auth.logout': 'Déconnexion',
  'auth.noAccount': 'Pas encore de compte ?',
  'auth.hasAccount': 'Déjà un compte ?',
  'auth.rememberMe': 'Se souvenir de moi',
  'auth.passwordsDoNotMatch': 'Les mots de passe ne correspondent pas',
  'auth.invalidEmail': 'Veuillez saisir une adresse email valide',
  'auth.requiredField': 'Ce champ est requis',

  // Settings
  'settings.title': 'Paramètres',
  'settings.account': 'Compte',
  'settings.logout': 'Se déconnecter',

  // Home
  'home.title': 'Tableau de bord',
  'home.welcome': 'Bienvenue sur Ascension',
  'home.currentSession': 'Session en cours',
  'home.noActiveSession': 'Aucune session active',

  // Sessions
  'sessions.title': 'Sessions',
  'sessions.startNew': 'Démarrer une nouvelle session',
  'sessions.resume': 'Revenir à la session en cours',
  'sessions.previous': 'Sessions précédentes',
  'sessions.sortBy': 'Triée par',
  'sessions.empty': 'Aucune session enregistrée',
  'sessions.startAnalysisButton': 'Démarrer une analyse',
  'sessions.previousAnalysesTitle': 'Analyses précédentes',
  'sessions.noPreviousAnalyses': 'Aucune analyse précédente enregistrée',
  'sessions.newSessionTitle': 'Nouvelle session',
  'sessions.sessionNameLabel': 'Nom de la session',
  'sessions.sessionNameHint': 'Ex: Session du matin, Bloc Arkose...',
  'sessions.sessionLocationLabel': 'Lieu',
  'sessions.locationDisabledNote': '(Pour l\'instant, on désactive cette option, on verra plus tard comment gérer ça)',
  'sessions.locationHint': 'Rechercher une salle ou un spot',
  'sessions.sessionVisibilityLabel': 'Visibilité',
  'sessions.startSessionButton': 'Démarrer la session',
  'sessions.activeSessionTitle': 'Session en cours',
  'sessions.activeSessionLabel': 'Session en cours',
  'sessions.noActiveSession': 'Aucune session active',
  'sessions.noAnalysesYetInSession': 'Aucune analyse dans cette session.\nDémarrez votre première analyse ci-dessous !',
  'sessions.analysisSingular': 'analyse',
  'sessions.analysesPlural': 'analyses',
  'sessions.since': 'Depuis',
  'sessions.newAnalysisButton': 'Nouvelle analyse',
  'sessions.endSessionButton': 'Terminer la session',
  'sessions.endSessionConfirmTitle': 'Terminer la session ?',
  'sessions.endSessionConfirmBody': 'Êtes-vous sûr de vouloir terminer cette session ? Ses analyses seront conservées dans votre historique.',
  'sessions.noSessionDialogTitle': 'Aucune session en cours',
  'sessions.noSessionDialogBody': 'Aucune session en cours.\nVoulez-vous créer une nouvelle session pour cette analyse ?',
  'sessions.analysisMenuTitle': 'Analyse',
  'sessions.selectAnalysisPrompt': 'Sélectionnez le type d\'analyse souhaité',
  'sessions.analysisPose2dTitle': 'Analyse de pose 2D',
  'sessions.analysisPose2dDesc':
      'Détection 2D des 33 points clés par MediaPipe',
  'sessions.analysisPose3dTitle': 'Analyse de pose 3D',
  'sessions.analysisPose3dDesc': 'Reconstruction 3D et posture biomécanique',
  'sessions.analysisGhostTitle': 'Mode fantôme',
  'sessions.analysisGhostDesc': 'Guidage pas à pas et beta optimale',
  'sessions.analysisAssistedTitle': 'Grimpe assistée',
  'sessions.analysisAssistedDesc': 'Analyse temps réel avec guidage vocal',

  // Visibility
  'sessions.visibility.public': 'Publique',
  'sessions.visibility.friends': 'Amis',
  'sessions.visibility.private': 'Privée',

  // Filters / Sorting
  'sessions.sort.all': 'Toutes',
  'sessions.sort.friends': 'Amis seulement',
  'sessions.sort.public': 'Publiques',
  'sessions.sort.private': 'Privées',

  // Status
  'sessions.status.inProgress': 'En cours',
  'sessions.status.completed': 'Terminée',
  'sessions.status.failed': 'Échouée',

  // Training
  'training.title': 'Programmes d\'entraînement',
  'training.personalized': 'Entraînements personnalisés',

  // Profile
  'profile.title': 'Profil',
  'profile.climberProfile': 'Profil Grimpeur & Paramètres',
  'profile.birthDate': 'Date de naissance',
  'profile.height': 'Taille',
  'profile.weight': 'Poids',
  'profile.wingspan': 'Envergure',
  'profile.apeIndex': 'APE Index',
  'profile.manualInput': 'Manuellement (guidé par Ascension)',
  'profile.videoAnalysis': 'Analyse vidéo par notre IA',
  'profile.painOrInjury': 'Notes sur les douleurs & membres manquants',
};
