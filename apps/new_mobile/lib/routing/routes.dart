// @date 2026-09-25
// @file routes.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
/// Centralized application route definitions.
enum AppRoute {
  login('/login', 'login'),
  register('/register', 'register'),
  home('/home', 'home'),
  sessions('/sessions', 'sessions'),
  training('/training', 'training'),
  profile('/profile', 'profile');

  const AppRoute(this.path, this.name);

  final String path;
  final String name;
}
