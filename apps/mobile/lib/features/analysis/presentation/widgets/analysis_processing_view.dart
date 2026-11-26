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
import 'package:mobile/features/analysis/presentation/controllers/pose_analysis_state.dart';

class AnalysisProcessingView extends StatelessWidget {
  const AnalysisProcessingView({
    super.key,
    required this.uploadProgress,
    required this.analysisProgress,
    required this.currentStep,
    required this.onCancel,
    this.processingStage,
    this.adviceProgress = 0,
    this.uploadSpeedBytesPerSec,
    this.estimatedRemainingSeconds,
  });

  final double uploadProgress;
  final int analysisProgress;
  final String currentStep;
  final VoidCallback onCancel;
  final AnalysisProcessingStage? processingStage;
  final int adviceProgress;
  final double? uploadSpeedBytesPerSec;
  final int? estimatedRemainingSeconds;

  AnalysisProcessingStage get _stage {
    if (processingStage != null) return processingStage!;
    if (uploadProgress < 1.0) return AnalysisProcessingStage.uploading;
    if (analysisProgress < 70) return AnalysisProcessingStage.detectingPose;
    if (analysisProgress < 100) return AnalysisProcessingStage.computingMetrics;
    if (adviceProgress < 100) return AnalysisProcessingStage.generatingAdvice;
    return AnalysisProcessingStage.finishing;
  }

  /// Logical overall progress weighting reflecting real pipeline duration:
  /// - Step 1 (Upload to S3 + trigger):     0% ->  25%
  /// - Step 2 (MediaPipe skeleton 0..70):  25% ->  75%
  /// - Step 3 (Metrics & movements):       75% ->  85%
  /// - Step 4 (AI coaching advice):        85% ->  99%
  /// - Finalizing micro-animation:        100%
  double get _overallProgress {
    switch (_stage) {
      case AnalysisProcessingStage.uploading:
        return (uploadProgress.clamp(0.0, 1.0) * 0.25).clamp(0.02, 0.25);
      case AnalysisProcessingStage.detectingPose:
        final ratio = (analysisProgress.clamp(0, 70) / 70.0);
        return (0.25 + ratio * 0.50).clamp(0.25, 0.75);
      case AnalysisProcessingStage.computingMetrics:
        final ratio = ((analysisProgress - 70).clamp(0, 30) / 30.0);
        return (0.75 + ratio * 0.10).clamp(0.75, 0.85);
      case AnalysisProcessingStage.generatingAdvice:
        final ratio = (adviceProgress.clamp(0, 100) / 100.0);
        return (0.85 + ratio * 0.14).clamp(0.85, 0.99);
      case AnalysisProcessingStage.finishing:
        return 1.0;
    }
  }

  String _stageLabel(BuildContext context, AnalysisProcessingStage stage) {
    switch (stage) {
      case AnalysisProcessingStage.uploading:
        return context.tr('analysis.uploading');
      case AnalysisProcessingStage.detectingPose:
      case AnalysisProcessingStage.computingMetrics:
        return context.tr('analysis.analyzing');
      case AnalysisProcessingStage.generatingAdvice:
        return context.tr('analysis.generatingAdvice');
      case AnalysisProcessingStage.finishing:
        return context.tr('analysis.completed');
    }
  }

  String? _formatSpeed(BuildContext context) {
    final speed = uploadSpeedBytesPerSec;
    if (speed == null || speed <= 0) return null;
    if (speed >= 1024 * 1024) {
      final mb = (speed / (1024 * 1024)).toStringAsFixed(1);
      return context.tr('analysis.uploadSpeedMb', {'speed': mb});
    }
    final kb = (speed / 1024).round().toString();
    return context.tr('analysis.uploadSpeedKb', {'speed': kb});
  }

  String? _formatEta(BuildContext context) {
    final eta = estimatedRemainingSeconds;
    if (eta == null || eta <= 0) return null;
    if (eta <= 3) {
      return context.tr('analysis.etaFewSeconds');
    }
    if (eta < 60) {
      return context.tr('analysis.etaRemaining', {'time': '$eta s'});
    }
    final mins = eta ~/ 60;
    final secs = eta % 60;
    final formatted = secs > 0 ? '$mins min $secs s' : '$mins min';
    return context.tr('analysis.etaRemaining', {'time': formatted});
  }

  IconData _centerIcon(AnalysisProcessingStage stage) {
    switch (stage) {
      case AnalysisProcessingStage.uploading:
        return FLucideIcons.cloudUpload;
      case AnalysisProcessingStage.detectingPose:
      case AnalysisProcessingStage.computingMetrics:
        return FLucideIcons.brainCircuit;
      case AnalysisProcessingStage.generatingAdvice:
        return FLucideIcons.sparkles;
      case AnalysisProcessingStage.finishing:
        return FLucideIcons.checkCircle2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    final overall = _overallProgress;
    final isFinishing = stage == AnalysisProcessingStage.finishing;
    final speedText = stage == AnalysisProcessingStage.uploading
        ? _formatSpeed(context)
        : null;
    final etaText = !isFinishing ? _formatEta(context) : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated Center Icon (pulses while processing, pops to check on finish)
              Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: context.theme.colors.primary.withValues(
                          alpha: isFinishing ? 0.22 : 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutBack,
                            ),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Icon(
                            _centerIcon(stage),
                            key: ValueKey(stage),
                            size: 46,
                            color: context.theme.colors.primary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .animate(
                    key: ValueKey('pulse_$isFinishing'),
                    onPlay: isFinishing ? null : (c) => c.repeat(reverse: true),
                  )
                  .scale(
                    begin: isFinishing
                        ? const Offset(0.85, 0.85)
                        : const Offset(0.95, 0.95),
                    end: isFinishing
                        ? const Offset(1.08, 1.08)
                        : const Offset(1.05, 1.05),
                    duration: isFinishing ? 320.ms : 1200.ms,
                    curve: isFinishing ? Curves.easeOutBack : Curves.easeInOut,
                  ),

              const SizedBox(height: 24),

              // Current Status description
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  currentStep.isNotEmpty
                      ? (context.tr(currentStep) != currentStep
                            ? context.tr(currentStep)
                            : currentStep)
                      : context.tr('analysis.statusProcessing'),
                  key: ValueKey(currentStep),
                  textAlign: TextAlign.center,
                  style: context.theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Smooth Linear Progress Bar, Percentage & Telemetry (Speed / ETA)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: overall),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) {
                  final percentInt = (animatedValue * 100).round();
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: animatedValue,
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
                            _stageLabel(context, stage),
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
                      if (speedText != null || etaText != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            if (speedText != null)
                              _buildTelemetryPill(
                                context,
                                icon: FLucideIcons.gauge,
                                label: speedText,
                              ),
                            if (etaText != null)
                              _buildTelemetryPill(
                                context,
                                icon: FLucideIcons.clock,
                                label: etaText,
                              ),
                          ],
                        ).animate().fadeIn(duration: 200.ms),
                      ],
                    ],
                  );
                },
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
                        isDone:
                            stage.index >
                            AnalysisProcessingStage.uploading.index,
                        isActive: stage == AnalysisProcessingStage.uploading,
                      ),
                      const SizedBox(height: 12),
                      _buildStepItem(
                        context,
                        title: context.tr('analysis.stepDetection'),
                        isDone:
                            stage.index >
                            AnalysisProcessingStage.detectingPose.index,
                        isActive:
                            stage == AnalysisProcessingStage.detectingPose,
                      ),
                      const SizedBox(height: 12),
                      _buildStepItem(
                        context,
                        title: context.tr('analysis.stepMetrics'),
                        isDone:
                            stage.index >
                            AnalysisProcessingStage.computingMetrics.index,
                        isActive:
                            stage == AnalysisProcessingStage.computingMetrics,
                      ),
                      const SizedBox(height: 12),
                      _buildStepItem(
                        context,
                        title: context.tr('analysis.stepAdvice'),
                        isDone: isFinishing,
                        isActive:
                            stage == AnalysisProcessingStage.generatingAdvice,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Cancel button
              FButton(
                variant: FButtonVariant.outline,
                onPress: isFinishing ? null : onCancel,
                child: Text(context.tr('analysis.cancelUpload')),
              ),
            ],
          ).animate().fadeIn(duration: 250.ms),
        ),
      ),
    );
  }

  Widget _buildTelemetryPill(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.theme.colors.muted.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.theme.colors.mutedForeground),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        key: const ValueKey('done'),
        size: 18,
        color: context.theme.colors.primary,
      );
    } else if (isActive) {
      iconWidget =
          const Icon(
                FLucideIcons.loader2,
                key: ValueKey('active'),
                size: 18,
                color: Color(0xFF00E5FF),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1000.ms, curve: Curves.linear);
    } else {
      iconWidget = Icon(
        FLucideIcons.circle,
        key: const ValueKey('pending'),
        size: 18,
        color: context.theme.colors.mutedForeground.withValues(alpha: 0.4),
      );
    }

    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: iconWidget,
        ),
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
