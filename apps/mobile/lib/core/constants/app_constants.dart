class AppConstants {
  static const String appName = 'Ascension';

  // Passer --dart-define=BASE_URL=http://10.0.2.2:3000 pour Android émulateur
  // ou --dart-define=BASE_URL=http://<IP_LAN>:3000 pour device physique
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Secure storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // Hive boxes
  static const String messagesBox = 'messages';
  static const String conversationsBox = 'conversations';
  static const String usersBox = 'users';
}
