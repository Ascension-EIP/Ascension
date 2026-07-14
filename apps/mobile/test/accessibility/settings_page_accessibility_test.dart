import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/accessibility/accessibility_settings_service.dart';
import 'package:mobile/features/profile/presentation/pages/settings_page.dart';
import 'package:mobile/shared/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp() {
  return const MaterialApp(
    locale: Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: SettingsPage(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AccessibilitySettingsService().resetToDefaults();
    await AccessibilitySettingsService().init();
  });

  testWidgets('shows required accessibility settings controls', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Accessibilité'), findsOneWidget);
    expect(find.text('Taille du texte'), findsOneWidget);
    expect(find.text('Mode contraste élevé'), findsOneWidget);
    expect(find.text('Réduire les animations'), findsOneWidget);
    expect(find.text('Interface simplifiée'), findsOneWidget);
    expect(find.text('Sous-titres activés par défaut'), findsOneWidget);
    expect(find.text('Intensité des retours haptiques'), findsOneWidget);
    expect(find.text('Vitesse lecture / playback'), findsOneWidget);
    expect(find.text('Profil dyslexie (espacement)'), findsOneWidget);
    expect(find.text('Réduire les interruptions'), findsOneWidget);
    expect(find.text('Langue de l’application'), findsOneWidget);
  });

  testWidgets('toggle high contrast updates service immediately', (
    tester,
  ) async {
    final service = AccessibilitySettingsService();

    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(service.highContrast, isFalse);

    final contrastLabel = find.text('Mode contraste élevé');
    await tester.scrollUntilVisible(
      contrastLabel,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final contrastTile = find.ancestor(
      of: contrastLabel,
      matching: find.byType(SwitchListTile),
    );
    await tester.tap(contrastTile);
    await tester.pumpAndSettle();

    expect(service.highContrast, isTrue);
  });

  testWidgets('change language to english updates service', (tester) async {
    final service = AccessibilitySettingsService();

    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(service.appLanguage, AppLanguage.french);

    await tester.scrollUntilVisible(
      find.text('Langue de l’application'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(service.appLanguage, AppLanguage.english);
  });
}
