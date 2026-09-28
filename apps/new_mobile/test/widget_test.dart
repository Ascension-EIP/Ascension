// @date 2026-09-29
// @file widget_test.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_mobile/app/app.dart';
import 'package:new_mobile/core/l10n/app_localizations.dart';
import 'package:new_mobile/core/l10n/locale_provider.dart';
import 'package:new_mobile/core/storage/local_storage_service.dart';
import 'package:new_mobile/core/storage/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSecureStorageService extends SecureStorageService {
  FakeSecureStorageService({this.token, this.userId}) : super(const FlutterSecureStorage());

  final String? token;
  final String? userId;

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<String?> getRefreshToken() async => token != null ? 'refresh_$token' : null;

  @override
  Future<String?> getUserId() async => userId;

  @override
  Future<void> clearAuthData() async {}
}

void main() {
  testWidgets('AscensionApp smoke test - unauthenticated redirects to login (English default)',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          secureStorageServiceProvider.overrideWithValue(FakeSecureStorageService()),
        ],
        child: const AscensionApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Default locale is English
    expect(find.text('Sign In'), findsAtLeastNWidgets(1));
    expect(find.text('Visualise the invisible!'), findsOneWidget);
  });

  testWidgets('AscensionApp smoke test - authenticated displays 4-tab shell',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          secureStorageServiceProvider.overrideWithValue(
            FakeSecureStorageService(token: 'valid_jwt_token', userId: 'user_123'),
          ),
        ],
        child: const AscensionApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('AscensionApp smoke test - French locale displays French translations',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          secureStorageServiceProvider.overrideWithValue(
            FakeSecureStorageService(token: 'valid_jwt_token', userId: 'user_123'),
          ),
          localeProvider.overrideWith((ref) => LocaleNotifier(LocalStorageService(sharedPreferences))
            ..setLocale(const Locale('fr'))),
        ],
        child: const AscensionApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tableau de bord'), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Entraînement'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });

  test('AppLocalizations fallback logic test', () {
    const frL10n = AppLocalizations(Locale('fr'));

    // 1. Found in French
    expect(frL10n.tr('nav.home'), 'Accueil');

    // 2. Missing in French -> fallback to English
    expect(frL10n.tr('auth.login'), 'Connexion');

    // 3. Missing in both French and English -> returns raw key
    expect(frL10n.tr('non_existent_key_123'), 'non_existent_key_123');

    // 4. Parameter substitution
    const enL10n = AppLocalizations(Locale('en'));
    expect(enL10n.tr('common.hello {name}', {'name': 'Alex'}), 'common.hello Alex');
  });
}
