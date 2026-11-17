// @date 2026-11-06
// @file routes.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done / Centralized application route definitions.
enum AppRoute {
  welcome('/welcome', 'welcome'),
  login('/login', 'login'),
  register('/register', 'register'),
  home('/home', 'home'),
  sessions('/sessions', 'sessions'),
  newSession('/sessions/new', 'newSession'),
  activeSession('/sessions/active', 'activeSession'),
  analysisSelection('/sessions/analysis', 'analysisSelection'),
  record('/record', 'record'),
  training('/training', 'training'),
  profile('/profile', 'profile'),
  settings('/settings', 'settings');

  const AppRoute(this.path, this.name);

  final String path;
  final String name;
}
