// @date 2026-11-21
// @file record_screen_test.dart
// @brief Widget tests for RecordScreen (selection mode and camera options sheet).
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
import 'package:mobile/features/climb_session/data/repositories/climb_session_repository_impl.dart';
import 'package:mobile/features/video_upload/presentation/screens/record_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helper.dart';

Widget _buildRecordScreenTestableWidget({required SharedPreferences prefs}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      climbSessionRepositoryProvider.overrideWithValue(
        TestClimbSessionRepository(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => FTheme(
        data: AppTheme.dark(),
        child: Material(type: MaterialType.transparency, child: child!),
      ),
      home: const RecordScreen(),
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('RecordScreen Widget Tests', () {
    testWidgets(
      'renders selection view with header, actions, and framing tips',
      (tester) async {
        await tester.pumpWidget(_buildRecordScreenTestableWidget(prefs: prefs));
        await tester.pumpAndSettle();

        // Header
        expect(find.text('Analyse de pose'), findsOneWidget);

        // Hero Title and Subtitle
        expect(find.text('Filmer sa grimpe'), findsWidgets);
        expect(
          find.text(
            'Enregistrez votre montée pour analyser votre posture, vos mouvements et obtenir un coaching personnalisé par l\'IA.',
          ),
          findsOneWidget,
        );

        // Buttons
        expect(find.text('Sélectionner une vidéo'), findsOneWidget);
        expect(
          find.text('Ouvre la caméra avec options et retardateur'),
          findsOneWidget,
        );

        // Framing tips
        expect(find.text('Conseils pour une analyse optimale'), findsOneWidget);
        expect(
          find.text(
            'Cadrez l\'ensemble du mur et gardez le grimpeur visible de la tête aux pieds.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Posez ou stabilisez votre smartphone sur un support fixe ou un trépied.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Privilégiez un bon éclairage uniforme et évitez les contre-jours puissants.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping Filmer sa grimpe opens camera options bottom sheet', (
      tester,
    ) async {
      await tester.pumpWidget(_buildRecordScreenTestableWidget(prefs: prefs));
      await tester.pumpAndSettle();

      final filmButton = find.text(
        'Ouvre la caméra avec options et retardateur',
      );
      expect(filmButton, findsOneWidget);

      await tester.tap(filmButton);
      await tester.pumpAndSettle();

      // Check that bottom sheet opened with all 3 options
      expect(find.text('Options d\'enregistrement'), findsOneWidget);
      expect(find.text('Ouvrir la caméra directement'), findsOneWidget);
      expect(find.text('Enregistrement avec retardateur (5s)'), findsOneWidget);
      expect(find.text('Choisir dans la galerie'), findsOneWidget);
    });
  });
}
