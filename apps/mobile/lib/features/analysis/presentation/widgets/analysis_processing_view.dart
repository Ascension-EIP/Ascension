// @date 2026-11-21
// @file analysis_processing_view.dart
// @brief Loading and processing screen showing multi-stage analysis progress.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/l10n/app_localizations.dart';

class AnalysisProcessingView extends StatelessWidget {
  const AnalysisProcessingView({
    super.key,
    required this.uploadProgress,
    required this.analysisProgress,
    required this.currentStep,
    required this.onCancel,
  });

  final double uploadProgress;
  final int analysisProgress;
  final String currentStep;
  final VoidCallback onCancel;

  double get _overallProgress {
    if (uploadProgress < 1.0) {
      return (uploadProgress * 0.4).clamp(0.05, 0.4);
    }
    return (0.4 + (analysisProgress / 100.0) * 0.6).clamp(0.4, 0.99);
  }

  @override
  Widget build(BuildContext context) {
    final overall = _overallProgress;
    final percentInt = (overall * 100).toInt();

    final isUploadComplete = uploadProgress >= 1.0;
    final isPoseDetectionActive = isUploadComplete && analysisProgress >= 0;
    final isMetricsActive = isUploadComplete && analysisProgress >= 50;
    final isAdviceActive = isUploadComplete && analysisProgress >= 80;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated Pulse Icon
              Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: context.theme.colors.primary.withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          FLucideIcons.brainCircuit,
                          size: 46,
                          color: context.theme.colors.primary,
                        ),
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.05, 1.05),
                    duration: 1200.ms,
                  ),

              const SizedBox(height: 24),

              // Current Status description
              Text(
                currentStep.isNotEmpty
                    ? (context.tr(currentStep) != currentStep
                          ? context.tr(currentStep)
                          : currentStep)
                    : context.tr('analysis.statusProcessing'),
                textAlign: TextAlign.center,
                style: context.theme.typography.body.md.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // Linear Progress Bar & Percentage
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: overall,
                      minHeight: 10,
                      backgroundColor: context.theme.colors.muted,
                      valueColor: AlwaysStoppedAnimation(
                        context.theme.colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isUploadComplete
                            ? context.tr('analysis.analyzing')
                            : context.tr('analysis.uploading'),
                        style: context.theme.typography.body.xs.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                      Text(
                        '$percentInt%',
                        style: context.theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.theme.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Multi-step Timeline Card
              FCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStepItem(
                        context,
                        title: context.tr('analysis.stepUpload'),
                        isDone: isUploadComplete,
                        isActive: !isUploadComplete,
                      ),
                      const SizedBox(height: 12),
                      _buildStepItem(
                        context,
                        title: context.tr('analysis.stepDetection'),
                        isDone: analysisProgress >= 50,
                        isActive:
                            isPoseDetectionActive && analysisProgress < 50,
                      ),
                      const SizedBox(height: 12),
                      _buildStepItem(
                        context,
                        title: context.tr('analysis.stepMetrics'),
                        isDone: analysisProgress >= 80,
                        isActive: isMetricsActive && analysisProgress < 80,
                      ),
                      const SizedBox(height: 12),
                      _buildStepItem(
                        context,
                        title: context.tr('analysis.stepAdvice'),
                        isDone: analysisProgress >= 100,
                        isActive: isAdviceActive && analysisProgress < 100,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Cancel button
              FButton(
                variant: FButtonVariant.outline,
                onPress: onCancel,
                child: Text(context.tr('analysis.cancelUpload')),
              ),
            ],
          ).animate().fadeIn(duration: 250.ms),
        ),
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context, {
    required String title,
    required bool isDone,
    required bool isActive,
  }) {
    Widget iconWidget;
    if (isDone) {
      iconWidget = Icon(
        FLucideIcons.checkCircle2,
        size: 18,
        color: context.theme.colors.primary,
      );
    } else if (isActive) {
      iconWidget =
          const Icon(FLucideIcons.loader2, size: 18, color: Color(0xFF00E5FF))
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1000.ms, curve: Curves.linear);
    } else {
      iconWidget = Icon(
        FLucideIcons.circle,
        size: 18,
        color: context.theme.colors.mutedForeground.withValues(alpha: 0.4),
      );
    }

    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: isActive || isDone
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: isActive || isDone
                  ? context.theme.colors.foreground
                  : context.theme.colors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}
