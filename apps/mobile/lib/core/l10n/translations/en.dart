// @date 2026-11-13
// @file en.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done / English (en) translations - Base default language.
const Map<String, String> enTranslations = {
  // Navigation
  'nav.home': 'Home',
  'nav.sessions': 'Sessions',
  'nav.training': 'Training',
  'nav.profile': 'Profile',

  // Common
  'common.appName': 'Ascension',
  'common.loading': 'Loading...',
  'common.error': 'An error occurred',
  'common.retry': 'Retry',
  'common.cancel': 'Cancel',
  'common.save': 'Save',
  'common.yes': 'Yes',
  'common.no': 'No',
  'common.continueLater': 'Continue later',
  'common.notAvailable':
      'Not available yet. This feature will be coming soon to Ascension.',

  // Auth
  'auth.login': 'Sign In',
  'auth.register': 'Sign Up',
  'auth.signIn': 'Sign In',
  'auth.signUp': 'Sign Up',
  'auth.slogan': 'Visualise the invisible!',
  'auth.forgotPassword': 'Forgot password?',
  'auth.identifier': 'Email or Username',
  'auth.email': 'Email',
  'auth.password': 'Password',
  'auth.confirmPassword': 'Confirm password',
  'auth.firstName': 'First name',
  'auth.lastName': 'Last name',
  'auth.username': 'Username',
  'auth.logout': 'Sign Out',
  'auth.noAccount': "Don't have an account?",
  'auth.hasAccount': 'Already have an account?',
  'auth.rememberMe': 'Remember me',
  'auth.passwordsDoNotMatch': 'Passwords do not match',
  'auth.invalidEmail': 'Please enter a valid email address',
  'auth.requiredField': 'This field is required',
  'auth.biometricPrompt': 'Authenticate to access Ascension',
  'auth.biometricSignIn': 'Biometric sign in',
  'auth.biometricUnavailable': 'Biometrics is not available on this device',

  // Settings
  'settings.title': 'Settings',
  'settings.account': 'Account',
  'settings.security': 'Security',
  'settings.biometrics': 'Biometric sign in',
  'settings.biometricsSubtitle': 'Use fingerprint or Face ID to sign in',
  'settings.biometricsEnablePrompt':
      'Confirm your identity to enable biometrics',
  'settings.biometricsPasswordTitle': 'Confirm your password',
  'settings.biometricsPasswordPrompt':
      'Enter your password to enable biometric sign-in',
  'settings.logout': 'Sign Out',

  // Home
  'home.title': 'Dashboard',
  'home.welcome': 'Welcome to Ascension',
  'home.currentSession': 'Current session',
  'home.noActiveSession': 'No active session',

  // Sessions
  'sessions.title': 'Sessions',
  'sessions.startNew': 'Start a new session',
  'sessions.resume': 'Resume current session',
  'sessions.previous': 'Previous sessions',
  'sessions.sortBy': 'Sorted by',
  'sessions.empty': 'No sessions recorded yet',
  'sessions.startAnalysisButton': 'Start an analysis',
  'sessions.previousAnalysesTitle': 'Previous analyses',
  'sessions.noPreviousAnalyses': 'No previous analyses recorded',
  'sessions.newSessionTitle': 'New Session',
  'sessions.sessionNameLabel': 'Session name',
  'sessions.sessionNameHint': 'E.g., Morning session, Arkose boulder...',
  'sessions.sessionLocationLabel': 'Location',
  'sessions.locationDisabledNote':
      '(For now, this option is disabled, we will handle it later)',
  'sessions.locationHint': 'Search climbing gym or crag',
  'sessions.sessionVisibilityLabel': 'Visibility',
  'sessions.startSessionButton': 'Start session',
  'sessions.activeSessionTitle': 'Active Session',
  'sessions.activeSessionLabel': 'Current session',
  'sessions.noActiveSession': 'No active session',
  'sessions.noAnalysesYetInSession':
      'No analyses in this session yet.\nStart your first analysis below!',
  'sessions.analysisSingular': 'analysis',
  'sessions.analysesPlural': 'analyses',
  'sessions.since': 'Since',
  'sessions.newAnalysisButton': 'New analysis',
  'sessions.endSessionButton': 'End session',
  'sessions.endSessionConfirmTitle': 'End session?',
  'sessions.endSessionConfirmBody': 'Are you sure you want to end this session? Its analyses will be preserved in your history.',
  'sessions.noSessionDialogTitle': 'No active session',
  'sessions.noSessionDialogBody': 'No active session.\nDo you want to create a new session for this analysis?',
  'sessions.analysisMenuTitle': 'Analysis',
  'sessions.selectAnalysisPrompt': 'Select the desired analysis type',
  'sessions.analysisPose2dTitle': '2D Pose Analysis',
  'sessions.analysisPose2dDesc': 'Film a video of your climb. The AI tracks your movements, analyzes your posture, and gives you personalized coaching advice to improve.',
  'sessions.analysisPose3dTitle': '3D Pose Analysis',
  'sessions.analysisPose3dDesc': 'Visualize your climb in 3D to explore your movements and posture from any angle.',
  'sessions.analysisGhostTitle': 'Ghost Mode',
  'sessions.analysisGhostDesc': 'Take a photo of a route or boulder. The AI finds a movement sequence tailored to your body and guides you hold by hold.',
  'sessions.analysisAssistedTitle': 'Assisted Climbing',
  'sessions.analysisAssistedDesc':
      'Real-time audio voice guidance during your climb.',
  'sessions.analysisBadgeVideo': 'Video',
  'sessions.analysisBadgePhoto': 'Photo',
  'sessions.analysisStartAction': 'Start',
  'sessions.analysisActionVideo': 'Record my climb',
  'sessions.analysisActionPhoto': 'Analyze route',

  // Visibility
  'sessions.visibility.public': 'Public',
  'sessions.visibility.friends': 'Friends only',
  'sessions.visibility.private': 'Private',

  // Filters / Sorting
  'sessions.sort.all': 'All',
  'sessions.sort.friends': 'Friends only',
  'sessions.sort.public': 'Public',
  'sessions.sort.private': 'Private',

  // Status
  'sessions.status.inProgress': 'In progress',
  'sessions.status.completed': 'Completed',
  'sessions.status.failed': 'Failed',

  // Training
  'training.title': 'Training Programs',
  'training.personalized': 'Personalized workouts',

  // Profile
  'profile.title': 'Profile',
  'profile.climberProfile': 'Climber Profile & Settings',
  'profile.birthDate': 'Birth date',
  'profile.height': 'Height',
  'profile.weight': 'Weight',
  'profile.wingspan': 'Wingspan',
  'profile.apeIndex': 'APE Index',
  'profile.manualInput': 'Manually (guided by Ascension)',
  'profile.videoAnalysis': 'Video analysis by our AI',
  'profile.painOrInjury': 'Pain notes & missing limbs declaration',
};
