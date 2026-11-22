// @date 2026-11-21
// @file analysis_advice_tab.dart
// @brief Tab presenting AI coaching advice or deployment placeholder.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';

class AnalysisAdviceTab extends StatelessWidget {
  const AnalysisAdviceTab({super.key, this.advice});

  final AnalysisAdvice? advice;

  @override
  Widget build(BuildContext context) {
    if (advice == null || advice!.items.isEmpty) {
      return _buildPendingPlaceholder(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coach Summary Card
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          FLucideIcons.sparkles,
                          size: 20,
                          color: context.theme.colors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('analysis.summaryTitle'),
                              style: context.theme.typography.body.md.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Modèle : ${advice!.model}',
                              style: context.theme.typography.body.xs.copyWith(
                                color: context.theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FBadge(
                        variant: FBadgeVariant.secondary,
                        child: Text('${advice!.items.length} conseils'),
                      ),
                    ],
                  ),
                  if (advice!.summary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      advice!.summary,
                      style: context.theme.typography.body.sm.copyWith(
                        color: context.theme.colors.foreground,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05),

          const SizedBox(height: 16),

          // Advice Items List
          for (int i = 0; i < advice!.items.length; i++) ...[
            _buildAdviceCard(context, advice!.items[i], i),
            if (i < advice!.items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildAdviceCard(BuildContext context, AdviceItem item, int index) {
    return FCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCategoryBadge(context, item.category),
                    const SizedBox(width: 8),
                    FBadge(
                      variant: FBadgeVariant.outline,
                      child: Text('Priorité ${item.priority}'),
                    ),
                    const Spacer(),
                    if (item.frameStart != null && item.frameEnd != null)
                      Text(
                        'Frames ${item.frameStart}–${item.frameEnd}',
                        style: context.theme.typography.body.xs.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: context.theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                    height: 1.45,
                  ),
                ),
                if (item.bodyZones.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final zone in item.bodyZones)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.theme.colors.muted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _translateBodyZone(zone),
                            style: context.theme.typography.body.xs.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms, delay: (50 * index).ms)
        .slideY(begin: 0.05);
  }

  Widget _buildCategoryBadge(BuildContext context, String category) {
    switch (category.toLowerCase()) {
      case 'technique':
        return FBadge(
          variant: FBadgeVariant.primary,
          child: const Text('Technique'),
        );
      case 'strength':
      case 'force':
        return FBadge(
          variant: FBadgeVariant.destructive,
          child: const Text('Force'),
        );
      case 'flexibility':
      case 'souplesse':
        return FBadge(
          variant: FBadgeVariant.secondary,
          child: const Text('Souplesse'),
        );
      case 'endurance':
        return FBadge(
          variant: FBadgeVariant.outline,
          child: const Text('Endurance'),
        );
      default:
        return FBadge(variant: FBadgeVariant.secondary, child: Text(category));
    }
  }

  String _translateBodyZone(String zone) {
    switch (zone.toLowerCase()) {
      case 'left_elbow':
        return 'Coude gauche';
      case 'right_elbow':
        return 'Coude droit';
      case 'left_wrist':
        return 'Poignet gauche';
      case 'right_wrist':
        return 'Poignet droit';
      case 'left_knee':
        return 'Genou gauche';
      case 'right_knee':
        return 'Genou droit';
      case 'left_ankle':
        return 'Cheville gauche';
      case 'right_ankle':
        return 'Cheville droite';
      case 'left_foot':
        return 'Pied gauche';
      case 'right_foot':
        return 'Pied droit';
      case 'torso':
        return 'Buste';
      case 'lower_back':
        return 'Bas du dos';
      default:
        return zone.replaceAll('_', ' ');
    }
  }

  Widget _buildPendingPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.theme.colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FLucideIcons.brainCircuit,
                size: 48,
                color: context.theme.colors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('analysis.advicePending'),
              textAlign: TextAlign.center,
              style: context.theme.typography.body.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('analysis.advicePendingDesc'),
              textAlign: TextAlign.center,
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      FLucideIcons.info,
                      size: 18,
                      color: context.theme.colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'L\'analyse biomécanique 2D est quant à elle complète et accessible dans les onglets "Vidéo" et "Statistiques".',
                        style: context.theme.typography.body.xs.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
      ),
    );
  }
}
