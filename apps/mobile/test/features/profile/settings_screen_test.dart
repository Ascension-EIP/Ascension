// @date 2026-10-25
// @file settings_screen_test.dart
// @brief Widget tests for ProfileScreen settings action and SettingsScreen logout.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mobile/app/app_theme.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/entities/auth_session.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:mobile/features/profile/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthRepository implements AuthRepository {
  bool logoutCalled = false;

  @override
  Future<Result<AuthSession>> login({
    required String identifier,
    required String password,
    bool remember = true,
  }) async => throw UnimplementedError();

  @override
  Future<Result<AuthSession>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    bool remember = true,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void>> logout() async {
    logoutCalled = true;
    return const Success(null);
  }

  @override
  Future<bool> hasValidSession() async => true;
}

Widget createTestableWidget({
  required Widget child,
  required SharedPreferences prefs,
  required FakeAuthRepository repo,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => FTheme(data: AppTheme.dark(), child: child!),
      home: child,
    ),
  );
}

void main() {
  late FakeAuthRepository fakeRepo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeRepo = FakeAuthRepository();
  });

  group('ProfileScreen Settings Icon Tests', () {
    testWidgets('renders profile header with settings action icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const ProfileScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(FLucideIcons.settings), findsOneWidget);
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders settings header and logout button', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const SettingsScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.widgetWithText(FButton, 'Sign Out'), findsOneWidget);
    });

    testWidgets('tapping logout button triggers repository logout', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const SettingsScreen(),
          prefs: prefs,
          repo: fakeRepo,
        ),
      );
      await tester.pumpAndSettle();

      final logoutButton = find.widgetWithText(FButton, 'Sign Out');
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.logoutCalled, isTrue);
    });
  });
}
