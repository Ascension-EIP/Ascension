// @date 2026-11-21
// @file record_screen.dart
// @brief Screen managing video recording, selection, preview, and pose analysis flow.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/analysis/presentation/controllers/pose_analysis_controller.dart';
import 'package:mobile/features/analysis/presentation/controllers/pose_analysis_state.dart';
import 'package:mobile/features/analysis/presentation/widgets/analysis_processing_view.dart';
import 'package:mobile/features/analysis/presentation/widgets/analysis_results_view.dart';
import 'package:mobile/features/analysis/presentation/widgets/video_preview_view.dart';
import 'package:mobile/features/climb_session/presentation/controllers/climb_session_controller.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  void _openCameraMenu() {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.theme.colors.primary.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FLucideIcons.video,
                      size: 20,
                      color: context.theme.colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Options d\'enregistrement',
                      style: context.theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FTile(
                prefix: const Icon(FLucideIcons.camera),
                title: const Text('Ouvrir la caméra directement'),
                subtitle: const Text(
                  'Lancer immédiatement l\'enregistrement vidéo',
                ),
                onPress: () {
                  Navigator.of(sheetContext).pop();
                  ref
                      .read(poseAnalysisControllerProvider.notifier)
                      .recordVideo();
                },
              ),
              const SizedBox(height: 8),
              FTile(
                prefix: const Icon(FLucideIcons.timer),
                title: const Text('Enregistrement avec retardateur (5s)'),
                subtitle: const Text(
                  'Délai pour vous positionner au pied de la voie',
                ),
                onPress: () {
                  Navigator.of(sheetContext).pop();
                  _startCountdownAndRecord(5);
                },
              ),
              const SizedBox(height: 8),
              FTile(
                prefix: const Icon(FLucideIcons.folderOpen),
                title: const Text('Choisir dans la galerie'),
                subtitle: const Text('Importer une vidéo déjà tournée'),
                onPress: () {
                  Navigator.of(sheetContext).pop();
                  ref
                      .read(poseAnalysisControllerProvider.notifier)
                      .pickVideoFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startCountdownAndRecord(int seconds) async {
    int remaining = seconds;
    await showFDialog<void>(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        animation: animation,
        builder: (ctx, dialogStyle) => StatefulBuilder(
          builder: (builderContext, setDialogState) {
            Future.delayed(const Duration(seconds: 1), () {
              if (dialogContext.mounted) {
                if (remaining > 1) {
                  setDialogState(() {
                    remaining--;
                  });
                } else {
                  Navigator.of(dialogContext).pop();
                  ref
                      .read(poseAnalysisControllerProvider.notifier)
                      .recordVideo();
                }
              }
            });

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Préparation', style: dialogStyle.titleTextStyle),
                  const SizedBox(height: 12),
                  Text(
                    '$remaining',
                    style: ctx.theme.typography.display.xl.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                      color: ctx.theme.colors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Positionnez-vous face au mur...',
                    style: dialogStyle.bodyTextStyle,
                  ),
                  const SizedBox(height: 20),
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleBackPress() {
    final state = ref.read(poseAnalysisControllerProvider);
    if (state.isPreview) {
      ref.read(poseAnalysisControllerProvider.notifier).cancelPreview();
    } else if (state.isCompleted) {
      ref.read(poseAnalysisControllerProvider.notifier).reset();
      context.pop();
    } else if (state.isProcessing) {
      ref.read(poseAnalysisControllerProvider.notifier).cancelPreview();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(poseAnalysisControllerProvider);
    final activeSession = ref
        .watch(climbSessionControllerProvider)
        .activeSession;

    final String headerTitle = switch (state.flowStep) {
      PoseAnalysisFlowStep.selection => context.tr(
        'analysis.recordHeaderTitle',
      ),
      PoseAnalysisFlowStep.preview => context.tr('analysis.previewTitle'),
      PoseAnalysisFlowStep.processing => 'Analyse en cours',
      PoseAnalysisFlowStep.completed => context.tr('analysis.resultsTitle'),
      PoseAnalysisFlowStep.error => 'Erreur d\'analyse',
    };

    return FScaffold(
      header: FHeader.nested(
        title: Text(headerTitle),
        prefixes: [FHeaderAction.back(onPress: _handleBackPress)],
        suffixes: state.isCompleted
            ? [
                FHeaderAction(
                  icon: const Icon(FLucideIcons.check),
                  onPress: () {
                    ref.read(poseAnalysisControllerProvider.notifier).reset();
                    context.pop();
                  },
                ),
              ]
            : [],
      ),
      child: SafeArea(
        top: false,
        child: _buildCurrentFlowStep(context, state, activeSession?.id),
      ),
    );
  }

  Widget _buildCurrentFlowStep(
    BuildContext context,
    PoseAnalysisState state,
    String? activeSessionId,
  ) {
    switch (state.flowStep) {
      case PoseAnalysisFlowStep.selection:
        return _buildSelectionView(context);

      case PoseAnalysisFlowStep.preview:
        return VideoPreviewView(
          videoFile: state.selectedVideoFile!,
          videoSizeBytes: state.videoSizeBytes,
          onConfirm: () {
            ref
                .read(poseAnalysisControllerProvider.notifier)
                .confirmAndStartAnalysis(
                  climbingSessionId: activeSessionId,
                  title: 'Analyse de grimpe',
                );
          },
          onCancel: () {
            ref.read(poseAnalysisControllerProvider.notifier).cancelPreview();
          },
        );

      case PoseAnalysisFlowStep.processing:
        return AnalysisProcessingView(
          uploadProgress: state.uploadProgress,
          analysisProgress: state.analysisProgress,
          currentStep: state.currentProcessingStep,
          onCancel: () {
            ref.read(poseAnalysisControllerProvider.notifier).cancelPreview();
          },
        );

      case PoseAnalysisFlowStep.completed:
        return AnalysisResultsView(
          videoFile: state.selectedVideoFile,
          analysisResult: state.analysisResult!,
        );

      case PoseAnalysisFlowStep.error:
        return _buildErrorView(context, state.errorMessage);
    }
  }

  Widget _buildSelectionView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: context.theme.colors.primary.withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          FLucideIcons.personStanding,
                          size: 38,
                          color: context.theme.colors.primary,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .scale(begin: const Offset(0.9, 0.9)),

              const SizedBox(height: 16),

              Text(
                context.tr('analysis.recordTitle'),
                textAlign: TextAlign.center,
                style: context.theme.typography.display.sm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                context.tr('analysis.recordSubtitle'),
                textAlign: TextAlign.center,
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 28),

              // BIG ACTION BUTTON: Filmer sa grimpe
              GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openCameraMenu,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.theme.colors.primary,
                            context.theme.colors.primary.withValues(
                              alpha: 0.85,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: context.theme.colors.primary.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              FLucideIcons.video,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('analysis.recordTitle'),
                                  style: context.theme.typography.body.lg
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ouvre la caméra avec options et retardateur',
                                  style: context.theme.typography.body.xs
                                      .copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            FLucideIcons.arrowRight,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 250.ms, delay: 50.ms)
                  .slideY(begin: 0.05),

              const SizedBox(height: 14),

              // SECOND ACTION BUTTON: Sélectionner une vidéo
              FButton(
                    variant: FButtonVariant.outline,
                    onPress: () {
                      ref
                          .read(poseAnalysisControllerProvider.notifier)
                          .pickVideoFromGallery();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FLucideIcons.folderOpen, size: 18),
                        const SizedBox(width: 8),
                        Text(context.tr('analysis.selectVideo')),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 250.ms, delay: 100.ms)
                  .slideY(begin: 0.05),

              const SizedBox(height: 28),

              // Framing Tips Card
              FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                FLucideIcons.lightbulb,
                                size: 18,
                                color: context.theme.colors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.tr('analysis.tipsTitle'),
                                  style: context.theme.typography.body.sm
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTipRow(
                            context,
                            icon: FLucideIcons.maximize2,
                            text: context.tr('analysis.tipFrame'),
                          ),
                          const SizedBox(height: 10),
                          _buildTipRow(
                            context,
                            icon: FLucideIcons.smartphone,
                            text: context.tr('analysis.tipStability'),
                          ),
                          const SizedBox(height: 10),
                          _buildTipRow(
                            context,
                            icon: FLucideIcons.sun,
                            text: context.tr('analysis.tipLighting'),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 250.ms, delay: 150.ms)
                  .slideY(begin: 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: context.theme.colors.mutedForeground),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.theme.colors.destructive.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FLucideIcons.alertTriangle,
                size: 36,
                color: context.theme.colors.destructive,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('analysis.errorTitle'),
              textAlign: TextAlign.center,
              style: context.theme.typography.body.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Une erreur inattendue est survenue.',
              textAlign: TextAlign.center,
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            FButton(
              onPress: () {
                ref
                    .read(poseAnalysisControllerProvider.notifier)
                    .cancelPreview();
              },
              child: Text(context.tr('analysis.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
