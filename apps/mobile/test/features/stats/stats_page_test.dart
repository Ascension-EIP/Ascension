// @date 2026-09-07
// @file stats_page_test.dart
// @brief Tests pour la page de statistiques avec diagrammes interactifs.
// @project Ascension
// @author Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/features/stats/presentation/pages/stats_page.dart';
import 'package:mobile/features/stats/presentation/widgets/interactive_activity_chart.dart';
import 'package:mobile/features/stats/presentation/widgets/interactive_performance_donut.dart';
import 'package:mobile/shared/components/interactive_circular_gauge.dart';
import 'package:mobile/shared/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildStatsTestApp() {
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
      child: const FToaster(child: FTooltipGroup(child: StatsPage())),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService().init();
  });

  testWidgets(
    'StatsPage renders with interactive performance donut and circular gauges',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Log in mock user and seed history
      await AuthService().saveTokens(
        accessToken: 'mock-token',
        refreshToken: 'mock-refresh',
        userId: 'test-user',
      );
      await AuthService().init();

      final entry = AnalysisHistoryEntry(
        analysisId: 'test-1',
        createdAt: DateTime.now(),
        status: 'completed',
        processingTimeMs: 12000,
        resultJson: '{"frames":[{"pose_detected":true}]}',
      );
      await AnalysisHistoryService().saveEntry('test-user', entry);

      await tester.pumpWidget(_buildStatsTestApp());
      await tester.pumpAndSettle();

      // Verify page renders
      expect(find.byType(StatsPage), findsOneWidget);
      expect(find.byType(InteractivePerformanceDonut), findsOneWidget);
      expect(find.byType(InteractiveActivityChart), findsOneWidget);
      expect(find.byType(InteractiveCircularGauge), findsWidgets);
    },
  );
}
