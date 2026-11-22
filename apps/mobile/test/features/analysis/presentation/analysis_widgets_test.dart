// @date 2026-11-21
// @file analysis_widgets_test.dart
// @brief Widget tests for AnalysisProcessingView, AnalysisAdviceTab, and AnalysisStatisticsTab.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mobile/app/app_theme.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';
import 'package:mobile/features/analysis/presentation/widgets/analysis_advice_tab.dart';
import 'package:mobile/features/analysis/presentation/widgets/analysis_processing_view.dart';
import 'package:mobile/features/analysis/presentation/widgets/analysis_statistics_tab.dart';

Widget _buildTestableWidget({required Widget child}) {
  return MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, c) => FTheme(
      data: AppTheme.dark(),
      child: Material(type: MaterialType.transparency, child: c!),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('AnalysisProcessingView Widget Tests', () {
    testWidgets('renders progress, status message, and step indicators', (
      tester,
    ) async {
      bool cancelPressed = false;

      await tester.pumpWidget(
        _buildTestableWidget(
          child: AnalysisProcessingView(
            uploadProgress: 0.5,
            analysisProgress: 0,
            currentStep: 'Téléversement en cours...',
            onCancel: () {
              cancelPressed = true;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Analyse biomécanique en cours...'), findsOneWidget);
      expect(find.text('Téléversement en cours...'), findsOneWidget);
      expect(
        find.text('Téléversement sécurisé de la vidéo (S3)'),
        findsOneWidget,
      );
      expect(
        find.text('Extraction des articulations MediaPipe Pose'),
        findsOneWidget,
      );
      expect(
        find.text('Calcul des vitesses et amplitudes de mouvement'),
        findsOneWidget,
      );
      expect(
        find.text('Génération des conseils de coaching par l\'IA'),
        findsOneWidget,
      );

      final cancelFinder = find.text('Annuler');
      expect(cancelFinder, findsOneWidget);
      await tester.ensureVisible(cancelFinder);
      await tester.tap(cancelFinder);
      await tester.pump(const Duration(milliseconds: 200));
      expect(cancelPressed, isTrue);
    });
  });

  group('AnalysisAdviceTab Widget Tests', () {
    testWidgets(
      'renders friendly pending placeholder when advice is null or empty',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(child: const AnalysisAdviceTab(advice: null)),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Génération des conseils par l\'IA en cours'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Notre modèle analyse actuellement les séquences de vos mouvements. Les conseils personnalisés seront disponibles très prochainement !',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders advice items, categories, and summary when populated',
      (tester) async {
        const advice = AnalysisAdvice(
          id: 'adv-123',
          summary:
              'Belle grimpe dynamique. Travaillez le verrouillage des coudes.',
          model: 'gemini-1.5-pro',
          items: [
            AdviceItem(
              title: 'Verrouillage squelettique des bras',
              description: 'Gardez les bras tendus pour économiser l\'énergie.',
              category: 'technique',
              priority: 1,
              bodyZones: ['left_elbow', 'right_elbow'],
              frameStart: 10,
              frameEnd: 45,
            ),
            AdviceItem(
              title: 'Renforcement avant-bras',
              description: 'Augmentez la force de préhension.',
              category: 'force',
              priority: 2,
              bodyZones: ['left_wrist'],
            ),
          ],
        );

        await tester.pumpWidget(
          _buildTestableWidget(child: const AnalysisAdviceTab(advice: advice)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Résumé du coach'), findsOneWidget);
        expect(find.text('Modèle : gemini-1.5-pro'), findsOneWidget);
        expect(find.text('2 conseils'), findsOneWidget);
        expect(
          find.text(
            'Belle grimpe dynamique. Travaillez le verrouillage des coudes.',
          ),
          findsOneWidget,
        );
        expect(find.text('Verrouillage squelettique des bras'), findsOneWidget);
        expect(find.text('Technique'), findsOneWidget);
        expect(find.text('Priorité 1'), findsOneWidget);
        expect(find.text('Coude gauche'), findsOneWidget);
        expect(find.text('Coude droit'), findsOneWidget);
        expect(find.text('Renforcement avant-bras'), findsOneWidget);
        expect(find.text('Force'), findsOneWidget);
      },
    );
  });

  group('AnalysisStatisticsTab Widget Tests', () {
    testWidgets(
      'renders all biomechanical metrics, KPIs, arm extensions and dynamics',
      (tester) async {
        const result = PoseAnalysisResult(
          fps: 30.0,
          width: 1080,
          height: 1920,
          frames: [],
          metrics: AnalysisMetrics(
            durationMs: 14200,
            poseDetectionRate: 0.98,
            avgArmExtension: SidesData(left: 0.85, right: 0.80),
            bentArmRatio: SidesData(left: 0.28, right: 0.32),
            avgSpeed: {'left_wrist': 1.45, 'right_wrist': 1.62},
          ),
          movements: [
            AnalysisMovement(
              startFrame: 30,
              endFrame: 105,
              startMs: 1000,
              endMs: 3500,
              limb: 'right_wrist',
            ),
          ],
          pauses: [
            AnalysisPause(
              startFrame: 105,
              endFrame: 180,
              startMs: 3500,
              endMs: 6000,
            ),
          ],
        );

        await tester.pumpWidget(
          _buildTestableWidget(
            child: const AnalysisStatisticsTab(analysisResult: result),
          ),
        );
        await tester.pumpAndSettle();

        // KPIs
        expect(find.text('Taux de détection'), findsOneWidget);
        expect(find.text('98.0%'), findsOneWidget);
        expect(find.text('Durée de la grimpe'), findsOneWidget);
        expect(find.text('14.2s'), findsOneWidget);

        // Arm Extension
        expect(find.text('Extension & Posture des bras'), findsOneWidget);
        expect(find.text('Extension moyenne des bras'), findsOneWidget);
        expect(find.text('Ratio bras fléchis'), findsOneWidget);
        expect(find.text('85%'), findsOneWidget);
        expect(find.text('80%'), findsOneWidget);

        // Limb speeds
        expect(find.text('Vitesse moyenne des membres'), findsOneWidget);
        expect(find.text('Main gauche'), findsOneWidget);
        expect(find.text('Main droite'), findsOneWidget);
        expect(find.text('1.45 buste/s'), findsOneWidget);
        expect(find.text('1.62 buste/s'), findsOneWidget);

        // Movements & Pauses
        expect(find.text('Dynamique de grimpe'), findsOneWidget);
        expect(find.text('Mouvements détectés'), findsOneWidget);
        expect(find.text('Pauses / Temps de repos'), findsOneWidget);
        expect(find.text('1'), findsWidgets);
        expect(find.text('Pause #1 (2.5s)'), findsOneWidget);
        expect(find.text('3.5s → 6.0s'), findsOneWidget);
      },
    );
  });
}
