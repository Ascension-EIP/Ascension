// @date 2026-11-06
// @file en.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
/// English (en) translations - Base default language.
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

  // Settings
  'settings.title': 'Settings',
  'settings.account': 'Account',
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
  'sessions.sessionNameLabel': 'Session name:',
  'sessions.sessionNameHint': 'E.g., Morning session, Arkose boulder...',
  'sessions.sessionLocationLabel': 'Location:',
  'sessions.locationDisabledNote':
      '(For now, this option is disabled, we will handle it later)',
  'sessions.locationHint': 'Search climbing gym or crag',
  'sessions.sessionVisibilityLabel': 'Visibility:',
  'sessions.startSessionButton': 'Start session',
  'sessions.activeSessionTitle': 'Active Session',
  'sessions.activeSessionLabel': 'Current session',
  'sessions.noActiveSession': 'No active session',
  'sessions.noAnalysesYetInSession':
      'No analyses in this session yet.\nStart your first analysis below!',
  'sessions.analysisSingular': 'analysis',
  'sessions.analysesPlural': 'analyses',
  'sessions.newAnalysisButton': 'New analysis',
  'sessions.endSessionButton': 'End session',
  'sessions.endSessionConfirmTitle': 'End session?',
  'sessions.endSessionConfirmBody': 'Are you sure you want to end this session? Its analyses will be preserved in your history.',
  'sessions.noSessionDialogTitle': 'No active session',
  'sessions.noSessionDialogBody': 'No active session.\nDo you want to create a new session for this analysis?',
  'sessions.analysisMenuTitle': 'Analysis',
  'sessions.selectAnalysisPrompt': 'Select the desired analysis type:',
  'sessions.analysisPose2dTitle': '2D Pose Analysis',
  'sessions.analysisPose2dDesc': '2D extraction of 33 keypoints via MediaPipe',
  'sessions.analysisPose3dTitle': '3D Pose Analysis',
  'sessions.analysisPose3dDesc': '3D reconstruction and biomechanical posture',
  'sessions.analysisGhostTitle': 'Ghost Mode',
  'sessions.analysisGhostDesc': 'Step-by-step guidance and optimal beta',
  'sessions.analysisAssistedTitle': 'Assisted Climbing',
  'sessions.analysisAssistedDesc': 'Real-time analysis with audio guidance',

  // Training
  'training.title': 'Training Programs',
  'training.personalized': 'Personalized workouts',

  // Profile
  'profile.title': 'Profile & Morphology',
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
