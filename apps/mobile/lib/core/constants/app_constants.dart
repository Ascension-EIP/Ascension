import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'Ascension';

  static const String _definedBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
  );

  static String get defaultBackendUrl {
    if (_definedBackendUrl.isNotEmpty) return _definedBackendUrl;
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      return 'http://localhost:8080';
    }
    return 'http://10.0.2.2:8080';
  }

  // Secure storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  static const String emailKey = 'email';
  static const String roleKey = 'role';
}
