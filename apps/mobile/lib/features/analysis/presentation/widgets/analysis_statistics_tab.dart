// @date 2026-11-21
// @file analysis_statistics_tab.dart
// @brief Tab presenting detailed biomechanical climbing statistics.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';

class AnalysisStatisticsTab extends StatelessWidget {
  const AnalysisStatisticsTab({super.key, required this.analysisResult});

  final PoseAnalysisResult analysisResult;

  @override
  Widget build(BuildContext context) {
    final metrics = analysisResult.metrics;
    final detectionRate = metrics?.poseDetectionRate ?? 1.0;
    final durationSec = (metrics?.durationMs ?? 0) / 1000.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Core KPIs Overview Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  icon: FLucideIcons.scan,
                  title: context.tr('analysis.statPoseRate'),
                  value: '${(detectionRate * 100).toStringAsFixed(1)}%',
                  subtitle: '${analysisResult.frames.length} images capturées',
                  accentColor: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  icon: FLucideIcons.timer,
                  title: context.tr('analysis.statDuration'),
                  value: '${durationSec.toStringAsFixed(1)}s',
                  subtitle:
                      '${analysisResult.fps.toStringAsFixed(0)} FPS standard',
                  accentColor: const Color(0xFFFFD600),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05),

          const SizedBox(height: 14),

          // 2. Arm Extension & Bent Arm Ratio Cards
          FCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            FLucideIcons.dumbbell,
                            size: 18,
                            color: context.theme.colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Extension & Posture des bras',
                            style: context.theme.typography.body.md.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Avg Arm Extension
                      Text(
                        context.tr('analysis.statAvgArmExt'),
                        style: context.theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSideProgressRow(
                        context,
                        leftValue: metrics?.avgArmExtension?.left ?? 0.8,
                        rightValue: metrics?.avgArmExtension?.right ?? 0.78,
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Bent Arm Ratio
                      Row(
                        children: [
                          Text(
                            context.tr('analysis.statBentArmRatio'),
                            style: context.theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          FBadge(
                            variant: FBadgeVariant.secondary,
                            child: const Text('Moins = Mieux'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pourcentage du temps où les bras sont restés fléchis au lieu d\'être verrouillés en suspension squelettique.',
                        style: context.theme.typography.body.xs.copyWith(
                          color: context.theme.colors.mutedForeground,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSideProgressRow(
                        context,
                        leftValue: metrics?.bentArmRatio?.left ?? 0.35,
                        rightValue: metrics?.bentArmRatio?.right ?? 0.42,
                        isWarningMetric: true,
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 250.ms, delay: 50.ms)
              .slideY(begin: 0.05),

          const SizedBox(height: 14),

          // 3. Average Limb Speeds
          if (metrics?.avgSpeed != null && metrics!.avgSpeed!.isNotEmpty)
            FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FLucideIcons.gauge,
                              size: 18,
                              color: context.theme.colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('analysis.statLimbSpeeds'),
                              style: context.theme.typography.body.md.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mesurée en longueurs de buste par seconde (torso/s)',
                          style: context.theme.typography.body.xs.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final entry in metrics.avgSpeed!.entries) ...[
                          Row(
                            children: [
                              Text(
                                _translateLimbName(entry.key),
                                style: context.theme.typography.body.sm
                                    .copyWith(fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Text(
                                '${entry.value.toStringAsFixed(2)} buste/s',
                                style: context.theme.typography.body.sm
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (entry.value / 3.0).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: context.theme.colors.muted,
                              valueColor: AlwaysStoppedAnimation(
                                context.theme.colors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 250.ms, delay: 100.ms)
                .slideY(begin: 0.05),

          const SizedBox(height: 14),

          // 4. Movement Dynamics (Movements & Pauses)
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FLucideIcons.footprints,
                        size: 18,
                        color: context.theme.colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('analysis.statMovementsAndPauses'),
                        style: context.theme.typography.body.md.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.theme.colors.muted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${analysisResult.movements.length}',
                                style: context.theme.typography.display.md
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.theme.colors.primary,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.tr('analysis.statMovementsCount'),
                                style: context.theme.typography.body.xs
                                    .copyWith(
                                      color:
                                          context.theme.colors.mutedForeground,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.theme.colors.muted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${analysisResult.pauses.length}',
                                style: context.theme.typography.display.md
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFFD600),
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.tr('analysis.statPausesCount'),
                                style: context.theme.typography.body.xs
                                    .copyWith(
                                      color:
                                          context.theme.colors.mutedForeground,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (analysisResult.pauses.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Temps d\'arrêt détectés :',
                      style: context.theme.typography.body.xs.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (int i = 0; i < analysisResult.pauses.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD600),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pause #${i + 1} (${(analysisResult.pauses[i].durationMs / 1000.0).toStringAsFixed(1)}s)',
                              style: context.theme.typography.body.xs.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(analysisResult.pauses[i].startMs / 1000.0).toStringAsFixed(1)}s → ${(analysisResult.pauses[i].endMs / 1000.0).toStringAsFixed(1)}s',
                              style: context.theme.typography.body.xs.copyWith(
                                color: context.theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(duration: 250.ms, delay: 150.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accentColor),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: context.theme.typography.display.sm.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: context.theme.typography.body.xs.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideProgressRow(
    BuildContext context, {
    required double leftValue,
    required double rightValue,
    bool isWarningMetric = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.tr('analysis.statArmLeft'),
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(leftValue * 100).toStringAsFixed(0)}%',
                    style: context.theme.typography.body.xs.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: leftValue.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: context.theme.colors.muted,
                  valueColor: AlwaysStoppedAnimation(
                    isWarningMetric
                        ? (leftValue > 0.5
                              ? context.theme.colors.destructive
                              : const Color(0xFFFFD600))
                        : const Color(0xFF00E5FF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.tr('analysis.statArmRight'),
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(rightValue * 100).toStringAsFixed(0)}%',
                    style: context.theme.typography.body.xs.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rightValue.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: context.theme.colors.muted,
                  valueColor: AlwaysStoppedAnimation(
                    isWarningMetric
                        ? (rightValue > 0.5
                              ? context.theme.colors.destructive
                              : const Color(0xFFFFD600))
                        : const Color(0xFF8C52FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _translateLimbName(String limb) {
    switch (limb.toLowerCase()) {
      case 'left_wrist':
      case 'left_hand':
        return 'Main gauche';
      case 'right_wrist':
      case 'right_hand':
        return 'Main droite';
      case 'left_ankle':
      case 'left_foot':
        return 'Pied gauche';
      case 'right_ankle':
      case 'right_foot':
        return 'Pied droit';
      default:
        return limb.replaceAll('_', ' ');
    }
  }
}
