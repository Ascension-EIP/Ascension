// @date 2026-11-13
// @file analysis_selection_screen.dart
// @brief Screen presenting available climbing analysis types.
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
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:mobile/routing/routes.dart';

class AnalysisSelectionScreen extends ConsumerWidget {
  const AnalysisSelectionScreen({super.key});

  /// Flags to mask features not targeted for the BTP milestone,
  /// as requested in the design specifications.
  static const bool _show3DPoseAnalysis = false;
  static const bool _showAssistedClimbing = false;

  void _onSelectAnalysis(
    BuildContext context,
    WidgetRef ref,
    AnalysisType type,
  ) {
    context.pushNamed(AppRoute.record.name, extra: {'type': type});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<_AnalysisOption> options = [
      _AnalysisOption(
        type: AnalysisType.pose2d,
        title: context.tr('sessions.analysisPose2dTitle'),
        description: context.tr('sessions.analysisPose2dDesc'),
        icon: FLucideIcons.personStanding,
        badgeText: context.tr('sessions.analysisBadgeVideo'),
        badgeIcon: FLucideIcons.video,
        visible: true,
      ),
      _AnalysisOption(
        type: AnalysisType.pose3d,
        title: context.tr('sessions.analysisPose3dTitle'),
        description: context.tr('sessions.analysisPose3dDesc'),
        icon: FLucideIcons.box,
        badgeText: '3D',
        badgeIcon: FLucideIcons.box,
        visible: _show3DPoseAnalysis, // Masqué pour le BTP
      ),
      _AnalysisOption(
        type: AnalysisType.ghostMode,
        title: context.tr('sessions.analysisGhostTitle'),
        description: context.tr('sessions.analysisGhostDesc'),
        icon: FLucideIcons.ghost,
        badgeText: context.tr('sessions.analysisBadgePhoto'),
        badgeIcon: FLucideIcons.camera,
        visible: true,
      ),
      _AnalysisOption(
        type: AnalysisType.assistedClimbing,
        title: context.tr('sessions.analysisAssistedTitle'),
        description: context.tr('sessions.analysisAssistedDesc'),
        icon: FLucideIcons.sparkles,
        badgeText: 'Audio',
        badgeIcon: FLucideIcons.sparkles,
        visible: _showAssistedClimbing, // Masqué pour le BTP
      ),
    ];

    final visibleOptions = options.where((o) => o.visible).toList();

    return FScaffold(
      header: FHeader.nested(
        title: Text(context.tr('sessions.analysisMenuTitle')),
        prefixes: [FHeaderAction.back(onPress: () => context.pop())],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isConstrained = constraints.maxHeight < 560;

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('sessions.selectAnalysisPrompt'),
                  style: context.theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < visibleOptions.length; i++) ...[
                  if (isConstrained)
                    _buildOptionCard(
                      context,
                      ref,
                      visibleOptions[i],
                      i,
                      isExpanded: false,
                    )
                  else
                    Expanded(
                      child: _buildOptionCard(
                        context,
                        ref,
                        visibleOptions[i],
                        i,
                        isExpanded: true,
                      ),
                    ),
                  if (i < visibleOptions.length - 1)
                    SizedBox(height: isConstrained ? 14 : 16),
                ],
              ],
            );

            if (isConstrained) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: content,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    WidgetRef ref,
    _AnalysisOption option,
    int index, {
    required bool isExpanded,
  }) {
    final cardContent = Container(
      width: double.infinity,
      height: isExpanded ? double.infinity : null,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.theme.colors.muted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  option.icon,
                  size: 26,
                  color: context.theme.colors.primary,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    option.title,
                    textAlign: TextAlign.center,
                    style: context.theme.typography.body.lg.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              FBadge(
                variant: FBadgeVariant.secondary,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      option.badgeIcon,
                      size: 12,
                      color: context.theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(option.badgeText),
                  ],
                ),
              ),
            ],
          ),
          if (isExpanded) const Spacer() else const SizedBox(height: 14),
          Text(
            option.description,
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
              height: 1.45,
            ),
          ),
          if (isExpanded) const Spacer() else const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                context.tr('sessions.analysisStartAction'),
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                FLucideIcons.arrowRight,
                size: 16,
                color: context.theme.colors.primary,
              ),
            ],
          ),
        ],
      ),
    );

    return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onSelectAnalysis(context, ref, option.type),
          child: FCard(child: cardContent),
        )
        .animate()
        .fadeIn(duration: 250.ms, delay: (40 * index).ms, curve: Curves.easeOut)
        .slideY(begin: 0.04, end: 0);
  }
}

class _AnalysisOption {
  const _AnalysisOption({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.badgeText,
    required this.badgeIcon,
    required this.visible,
  });

  final AnalysisType type;
  final String title;
  final String description;
  final IconData icon;
  final String badgeText;
  final IconData badgeIcon;
  final bool visible;
}
