// @date 2026-10-25
// @file test_helper.dart
// @brief Shared helpers, mock providers and wrappers for widget and golden tests.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:mobile/app/app_theme.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/entities/auth_session.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestAuthRepository implements AuthRepository {
  Result<AuthSession>? loginResult;
  Result<AuthSession>? registerResult;
  Result<void>? logoutResult;

  String? lastLoginIdentifier;
  String? lastLoginPassword;
  String? lastRegisterUsername;
  String? lastRegisterFirstName;
  String? lastRegisterLastName;
  String? lastRegisterEmail;
  bool logoutCalled = false;

  @override
  Future<Result<AuthSession>> login({
    required String identifier,
    required String password,
    bool remember = true,
  }) async {
    lastLoginIdentifier = identifier;
    lastLoginPassword = password;
    return loginResult ??
        const Success(
          AuthSession(
            accessToken: 'dummy_acc',
            refreshToken: 'dummy_ref',
            tokenType: 'Bearer',
            expiresIn: 3600,
            user: User(
              id: 'u1',
              username: 'tester',
              email: 'test@ascension.app',
              firstName: 'Test',
              lastName: 'User',
            ),
          ),
        );
  }

  @override
  Future<Result<AuthSession>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    bool remember = true,
  }) async {
    lastRegisterUsername = username;
    lastRegisterFirstName = firstName;
    lastRegisterLastName = lastName;
    lastRegisterEmail = email;
    return registerResult ??
        const Success(
          AuthSession(
            accessToken: 'dummy_acc',
            refreshToken: 'dummy_ref',
            tokenType: 'Bearer',
            expiresIn: 3600,
            user: User(
              id: 'u2',
              username: 'new_tester',
              email: 'new@ascension.app',
              firstName: 'New',
              lastName: 'Tester',
            ),
          ),
        );
  }

  @override
  Future<Result<void>> logout() async {
    logoutCalled = true;
    return logoutResult ?? const Success(null);
  }

  @override
  Future<bool> hasValidSession() async => true;
}

Widget createTestableWidget({
  required Widget child,
  SharedPreferences? prefs,
  AuthRepository? repo,
  Locale locale = const Locale('en'),
  bool isDark = true,
  List<Override> additionalOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
      if (repo != null) authRepositoryProvider.overrideWithValue(repo),
      ...additionalOverrides,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => FTheme(
        data: isDark ? AppTheme.dark() : AppTheme.light(),
        child: child!,
      ),
      home: child,
    ),
  );
}
