// @date 2026-11-07
// @file sessions_screen_test.dart
// @brief Widget tests for SessionsScreen, NewSessionScreen, ActiveSessionScreen, and AnalysisSelectionScreen.
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
import 'package:mobile/features/climb_session/presentation/screens/active_session_screen.dart';
import 'package:mobile/features/climb_session/presentation/screens/analysis_selection_screen.dart';
import 'package:mobile/features/climb_session/presentation/screens/new_session_screen.dart';
import 'package:mobile/features/climb_session/presentation/screens/sessions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestableWidget({
  required Widget child,
  required SharedPreferences prefs,
}) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => FTheme(
        data: AppTheme.dark(),
        child: Material(type: MaterialType.transparency, child: child!),
      ),
      home: child,
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('SessionsScreen Widget Tests', () {
    testWidgets(
      'renders session header, start session button, and past sessions',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(child: const SessionsScreen(), prefs: prefs),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sessions'), findsOneWidget);
        expect(find.text('Démarrer une nouvelle session'), findsOneWidget);
        expect(find.text('Sessions précédentes'), findsOneWidget);
        expect(find.text('Démarrer une analyse'), findsOneWidget);
      },
    );

    testWidgets(
      'shows no-session dialog when tapping start analysis without active session',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(child: const SessionsScreen(), prefs: prefs),
        );
        await tester.pumpAndSettle();

        final startAnalysisButton = find.widgetWithText(
          FButton,
          'Démarrer une analyse',
        );
        await tester.ensureVisible(startAnalysisButton);
        await tester.tap(startAnalysisButton);
        await tester.pumpAndSettle();

        expect(find.text('Aucune session en cours'), findsOneWidget);
        expect(find.text('Oui'), findsOneWidget);
        expect(find.text('Non'), findsOneWidget);
      },
    );

    testWidgets(
      'shows sort popup menu with all filter options including private',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(child: const SessionsScreen(), prefs: prefs),
        );
        await tester.pumpAndSettle();

        // Find the sort button (shows initial filter label 'Toutes')
        final sortButton = find.text('Toutes');
        expect(sortButton, findsOneWidget);

        await tester.tap(sortButton);
        await tester.pumpAndSettle();

        // Verify all options are present in the popup menu
        expect(find.text('Toutes'), findsWidgets);
        expect(find.text('Amis'), findsOneWidget);
        expect(find.text('Publiques'), findsOneWidget);
        expect(find.text('Privées'), findsOneWidget);

        // Select 'Privées'
        await tester.tap(find.text('Privées'));
        await tester.pumpAndSettle();

        // The button text should now update to 'Privées'
        expect(find.text('Privées'), findsOneWidget);
      },
    );
  });

  group('NewSessionScreen Widget Tests', () {
    testWidgets('renders new session form fields and disabled location note', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(child: const NewSessionScreen(), prefs: prefs),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle session'), findsOneWidget);
      expect(find.text('Nom de la session'), findsOneWidget);
      expect(find.text('Lieu'), findsOneWidget);
      expect(
        find.text(
          "(Pour l'instant, on désactive cette option, on verra plus tard comment gérer ça)",
        ),
        findsOneWidget,
      );
      expect(find.text('Visibilité'), findsOneWidget);
      expect(find.text('Démarrer la session'), findsOneWidget);
    });

    testWidgets(
      'start session button is disabled when name is empty and enabled when populated',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(child: const NewSessionScreen(), prefs: prefs),
        );
        await tester.pumpAndSettle();

        final buttonFinder = find.widgetWithText(
          FButton,
          'Démarrer la session',
        );
        final startButton = tester.widget<FButton>(buttonFinder);
        expect(startButton.onPress, isNotNull);

        final nameInputFinder = find.byType(EditableText).first;
        await tester.enterText(nameInputFinder, '');
        await tester.pumpAndSettle();

        final disabledButton = tester.widget<FButton>(buttonFinder);
        expect(disabledButton.onPress, isNull);
      },
    );
  });

  group('AnalysisSelectionScreen Widget Tests', () {
    testWidgets(
      'renders 2D pose and ghost mode while masking 3D pose and assisted climbing for BTP',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const AnalysisSelectionScreen(),
            prefs: prefs,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Analyse'), findsOneWidget);
        expect(find.text('Analyse de pose 2D'), findsOneWidget);
        expect(find.text('Mode fantôme'), findsOneWidget);

        // Verify BTP-masked features are not shown in UI
        expect(find.text('Analyse de pose 3D'), findsNothing);
        expect(find.text('Grimpe assistée'), findsNothing);
      },
    );
  });

  group('ActiveSessionScreen Widget Tests', () {
    testWidgets(
      'renders no active session placeholder when no session is running',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const ActiveSessionScreen(),
            prefs: prefs,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Aucune session active'), findsOneWidget);
      },
    );
  });
}
