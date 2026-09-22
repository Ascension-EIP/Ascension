// @date 2026-09-07
// @file interactive_diagrams_test.dart
// @brief Tests pour les jauges circulaires et diagrammes interactifs.
// @project Ascension
// @author Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/features/stats/presentation/widgets/interactive_activity_chart.dart';
import 'package:mobile/features/stats/presentation/widgets/interactive_performance_donut.dart';
import 'package:mobile/shared/components/interactive_circular_gauge.dart';
import 'package:mobile/shared/components/interactive_concentric_rings.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

Widget _wrapTestWidget(Widget child) {
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
      data: FThemeData(colors: FColors.neutralDark, touch: true),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InteractiveCircularGauge', () {
    testWidgets('renders value, label, and responds to hover and tap', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        _wrapTestWidget(
          InteractiveCircularGauge(
            value: 0.85,
            displayValue: '85%',
            label: 'Taux de réussite',
            icon: FLucideIcons.checkCircle,
            color: Colors.green,
            tooltipText: 'Détails de réussite',
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Taux de réussite'), findsOneWidget);
      expect(find.byIcon(FLucideIcons.checkCircle), findsOneWidget);

      // Tap test
      await tester.tap(find.byType(InteractiveCircularGauge));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      // Hover simulation
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(
        tester.getCenter(find.byType(InteractiveCircularGauge)),
      );
      await tester.pumpAndSettle();

      expect(find.text('85%'), findsOneWidget);
    });
  });

  group('InteractiveConcentricRings', () {
    testWidgets('renders multi-rings and interactive center', (tester) async {
      final rings = [
        const ConcentricRingData(
          id: 'success',
          label: 'Réussite',
          valueDisplay: '100%',
          progress: 1.0,
          color: Colors.green,
          icon: FLucideIcons.checkCircle,
          detail: '1/1 réussies',
        ),
        const ConcentricRingData(
          id: 'detection',
          label: 'Détection',
          valueDisplay: '90%',
          progress: 0.9,
          color: Colors.blue,
          icon: FLucideIcons.user,
          detail: '90% moyenne',
        ),
      ];

      await tester.pumpWidget(
        _wrapTestWidget(
          InteractiveConcentricRings(
            rings: rings,
            defaultCenterTitle: 'Global',
            defaultCenterSubtitle: 'Score',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);

      // Tap on chip to change center
      await tester.tap(find.text('Réussite (100%)'));
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('InteractivePerformanceDonut', () {
    testWidgets('renders donut and responds to legend pill tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          const InteractivePerformanceDonut(completedCount: 3, failedCount: 1),
        ),
      );
      await tester.pumpAndSettle();

      // Default center shows success rate (3/4 = 75%)
      expect(find.text('75%'), findsOneWidget);

      // Tap on successful legend pill
      await tester.tap(find.text('Réussies: 3'));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });
  });

  group('InteractiveActivityChart', () {
    testWidgets('renders weekly activity and peak day', (tester) async {
      final now = DateTime.now();
      final history = [
        AnalysisHistoryEntry(
          analysisId: 'a1',
          createdAt: now,
          status: 'completed',
        ),
        AnalysisHistoryEntry(
          analysisId: 'a2',
          createdAt: now,
          status: 'completed',
        ),
      ];

      await tester.pumpWidget(
        _wrapTestWidget(InteractiveActivityChart(history: history)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activité'), findsOneWidget);
      expect(find.text('2 analyses cette semaine'), findsOneWidget);
    });
  });
}
