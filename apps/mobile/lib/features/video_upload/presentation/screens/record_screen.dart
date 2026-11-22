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
  void _handleBackPress() {
    final state = ref.read(poseAnalysisControllerProvider);
    if (state.isError) {
      ref
          .read(poseAnalysisControllerProvider.notifier)
          .returnToPreviewOrSelection();
    } else if (state.isPreview) {
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
      PoseAnalysisFlowStep.processing => context.tr(
        'analysis.processingHeader',
      ),
      PoseAnalysisFlowStep.completed => context.tr('analysis.resultsTitle'),
      PoseAnalysisFlowStep.error => context.tr('analysis.errorHeader'),
    };

    return PopScope(
      canPop: state.isSelection,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: FScaffold(
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
        return _buildErrorView(context, state.errorMessage, activeSessionId);
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

              // ACTION BUTTON 1: Filmer sa grimpe
              FButton(
                    onPress: () {
                      ref
                          .read(poseAnalysisControllerProvider.notifier)
                          .recordVideo();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(FLucideIcons.video, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            context.tr('analysis.recordTitle'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 250.ms, delay: 50.ms)
                  .slideY(begin: 0.05),

              const SizedBox(height: 12),

              // ACTION BUTTON 2: Sélectionner une vidéo
              FButton(
                    variant: FButtonVariant.outline,
                    onPress: () {
                      ref
                          .read(poseAnalysisControllerProvider.notifier)
                          .pickVideoFromGallery();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(FLucideIcons.folderOpen, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            context.tr('analysis.selectVideo'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 15,
            color: context.theme.colors.mutedForeground,
          ),
        ),
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

  Widget _buildErrorView(
    BuildContext context,
    String? errorMessage,
    String? activeSessionId,
  ) {
    final hasVideo =
        ref.read(poseAnalysisControllerProvider).selectedVideoFile != null;
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
                final controller = ref.read(
                  poseAnalysisControllerProvider.notifier,
                );
                if (hasVideo) {
                  controller.confirmAndStartAnalysis(
                    climbingSessionId: activeSessionId,
                    title: 'Analyse de grimpe',
                  );
                } else {
                  controller.cancelPreview();
                }
              },
              child: Text(context.tr('analysis.retry')),
            ),
            if (hasVideo) ...[
              const SizedBox(height: 10),
              FButton(
                variant: FButtonVariant.outline,
                onPress: () {
                  ref
                      .read(poseAnalysisControllerProvider.notifier)
                      .returnToPreviewOrSelection();
                },
                child: Text(context.tr('analysis.backToPreview')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
