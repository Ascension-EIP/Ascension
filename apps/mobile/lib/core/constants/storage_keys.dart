// @date 2026-10-25
// @file storage_keys.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
/// Storage key constants for secure and local preferences.
class StorageKeys {
  StorageKeys._();

  // Secure Storage (Tokens & Sensitive Data)
  static const String accessToken = 'ascension_access_token';
  static const String refreshToken = 'ascension_refresh_token';
  static const String userId = 'ascension_user_id';
  static const String userEmail = 'ascension_user_email';

  // Shared Preferences (App state & Settings)
  static const String themeMode = 'ascension_theme_mode';
  static const String locale = 'ascension_locale';
  static const String onboardingCompleted = 'ascension_onboarding_completed';
}
