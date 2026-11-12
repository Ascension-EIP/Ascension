// @date 2026-11-07
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
import 'package:mobile/features/climb_session/presentation/controllers/climb_session_controller.dart';
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
    // Record analysis entry into active session or standalone history
    final newAnalysis = ClimbAnalysisSummary(
      id: 'analysis-${DateTime.now().millisecondsSinceEpoch}',
      title: type.displayName,
      type: type,
      status: AnalysisStatus.completed,
      createdAt: DateTime.now(),
      progressPercentage: 100,
    );

    ref.read(climbSessionControllerProvider.notifier).addAnalysis(newAnalysis);

    // If an active session exists, navigate back to active session
    final hasActive = ref.read(climbSessionControllerProvider).hasActiveSession;
    if (hasActive) {
      context.goNamed(AppRoute.activeSession.name);
    } else {
      context.goNamed(AppRoute.sessions.name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<_AnalysisOption> options = [
      _AnalysisOption(
        type: AnalysisType.pose2d,
        title: context.tr('sessions.analysisPose2dTitle'),
        description: context.tr('sessions.analysisPose2dDesc'),
        icon: FLucideIcons.video,
        visible: true,
      ),
      _AnalysisOption(
        type: AnalysisType.pose3d,
        title: context.tr('sessions.analysisPose3dTitle'),
        description: context.tr('sessions.analysisPose3dDesc'),
        icon: FLucideIcons.box,
        visible: _show3DPoseAnalysis, // Masqué pour le BTP
      ),
      _AnalysisOption(
        type: AnalysisType.ghostMode,
        title: context.tr('sessions.analysisGhostTitle'),
        description: context.tr('sessions.analysisGhostDesc'),
        icon: FLucideIcons.ghost,
        visible: true,
      ),
      _AnalysisOption(
        type: AnalysisType.assistedClimbing,
        title: context.tr('sessions.analysisAssistedTitle'),
        description: context.tr('sessions.analysisAssistedDesc'),
        icon: FLucideIcons.sparkles,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('sessions.selectAnalysisPrompt'),
                  style: context.theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    for (int i = 0; i < visibleOptions.length; i++) ...[
                      GestureDetector(
                            onTap: () => _onSelectAnalysis(
                              context,
                              ref,
                              visibleOptions[i].type,
                            ),
                            child: FCard(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: context.theme.colors.muted,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        visibleOptions[i].icon,
                                        size: 26,
                                        color: context.theme.colors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            visibleOptions[i].title,
                                            style: context
                                                .theme
                                                .typography
                                                .body
                                                .md
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            visibleOptions[i].description,
                                            style: context
                                                .theme
                                                .typography
                                                .body
                                                .xs
                                                .copyWith(
                                                  color: context
                                                      .theme
                                                      .colors
                                                      .mutedForeground,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      FLucideIcons.chevronRight,
                                      size: 18,
                                      color:
                                          context.theme.colors.mutedForeground,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(
                            duration: 250.ms,
                            delay: (50 * i).ms,
                            curve: Curves.easeOut,
                          )
                          .slideY(begin: 0.04, end: 0),
                      if (i < visibleOptions.length - 1)
                        const SizedBox(height: 14),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisOption {
  const _AnalysisOption({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.visible,
  });

  final AnalysisType type;
  final String title;
  final String description;
  final IconData icon;
  final bool visible;
}
