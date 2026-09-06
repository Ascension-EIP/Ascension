// @date 2026-09-07
// @file settings_page_accessibility_test.dart
// @brief Tests unitaires d'accessibilité de SettingsPage avec Forui.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/accessibility/accessibility_settings_service.dart';
import 'package:mobile/features/profile/presentation/pages/settings_page.dart';
import 'package:mobile/shared/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp() {
  return MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: FTheme(
      data: FThemeData(colors: FColors.neutralLight, touch: true),
      child: const FToaster(child: FTooltipGroup(child: SettingsPage())),
    ),
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
    // The Apparence/Thème section adds height above the accessibility
    // section, so use a tall surface to keep every assertion below visible
    // without needing to scroll.
    await tester.binding.setSurfaceSize(const Size(400, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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

    final contrastRow = find
        .ancestor(of: contrastLabel, matching: find.byType(Row))
        .first;
    final contrastSwitch = find.descendant(
      of: contrastRow,
      matching: find.byType(FSwitch),
    );
    await tester.tap(contrastSwitch);
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
