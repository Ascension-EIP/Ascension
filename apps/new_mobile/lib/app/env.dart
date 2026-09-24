// @date 2026-09-25
// @file env.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
/// Application environment configuration.
///
/// Values can be supplied at compile time via `--dart-define`.
class AppEnv {
  AppEnv._();

  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String appName = 'Ascension';
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
}
