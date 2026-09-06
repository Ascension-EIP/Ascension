// @date 2026-09-07
// @file profile_page_test.dart
// @brief Tests unitaires et d'interface pour la page de profil Forui.
// @project Ascension
// @author Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile/features/profile/presentation/widgets/forui_profile_view.dart';
import 'package:mobile/shared/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildProfileTestApp() {
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
      child: const FToaster(child: FTooltipGroup(child: ProfilePage())),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService().init();
  });

  testWidgets('ProfilePage renders with Forui UI and components', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildProfileTestApp());
    await tester.pumpAndSettle();

    // Verify Forui view is present
    expect(find.byType(ForuiProfileView), findsOneWidget);
    expect(find.byType(FAvatar), findsOneWidget);

    // Verify action buttons exist
    expect(find.byIcon(FLucideIcons.pencil), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);

    // Open bottom sheet
    await tester.tap(find.byIcon(FLucideIcons.pencil));
    await tester.pumpAndSettle();

    // Verify sheet contents
    expect(find.text('Modifier le profil'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);

    // Close sheet
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Mettez à jour vos informations de compte'), findsNothing);
  });
}
