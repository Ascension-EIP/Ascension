// @date 2026-11-06
// @file active_session_screen.dart
// @brief Screen displaying the ongoing session metrics, analyses, and live timer.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:mobile/features/climb_session/presentation/controllers/climb_session_controller.dart';
import 'package:mobile/routing/routes.dart';

class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key});

  Future<void> _confirmEndSession(BuildContext context, WidgetRef ref) async {
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        builder: (context, dialogStyle) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('sessions.endSessionConfirmTitle'),
                style: dialogStyle.titleTextStyle,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('sessions.endSessionConfirmBody'),
                style: dialogStyle.bodyTextStyle,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(context).pop(false),
                    child: Text(context.tr('common.cancel')),
                  ),
                  const SizedBox(width: 12),
                  FButton(
                    variant: FButtonVariant.destructive,
                    onPress: () => Navigator.of(context).pop(true),
                    child: Text(context.tr('sessions.endSessionButton')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(climbSessionControllerProvider.notifier)
          .endSession();
      if (success && context.mounted) {
        context.goNamed(AppRoute.sessions.name);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(climbSessionControllerProvider);
    final session = state.activeSession;

    if (session == null) {
      return FScaffold(
        header: FHeader.nested(
          title: Text(context.tr('sessions.activeSessionTitle')),
          prefixes: [
            FHeaderAction.back(
              onPress: () => context.goNamed(AppRoute.sessions.name),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FLucideIcons.mountain, size: 48),
                const SizedBox(height: 16),
                Text(
                  context.tr('sessions.noActiveSession'),
                  style: context.theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                FButton(
                  onPress: () => context.goNamed(AppRoute.newSession.name),
                  child: Text(context.tr('sessions.startNew')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final analyses = session.analyses;

    return FScaffold(
      header: FHeader.nested(
        title: Text(context.tr('sessions.activeSessionTitle')),
        prefixes: [
          FHeaderAction.back(
            onPress: () => context.goNamed(AppRoute.sessions.name),
          ),
        ],
        suffixes: [
          FHeaderAction(
            icon: const Icon(FLucideIcons.squareCheck, size: 20),
            onPress: () => _confirmEndSession(context, ref),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top metrics row (Timer + Analyses count)
                      Row(
                        children: [
                          Expanded(
                            child: FCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(FLucideIcons.clock, size: 24),
                                    const SizedBox(height: 8),
                                    Text(
                                      state.formattedActiveDuration,
                                      style: context.theme.typography.body.sm
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Icon(
                                      FLucideIcons.chartColumn,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${analyses.length} ${analyses.length > 1 ? context.tr('sessions.analysesPlural') : context.tr('sessions.analysisSingular')}',
                                      style: context.theme.typography.body.sm
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05),

                      const SizedBox(height: 24),

                      // Session title & visibility summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              session.name,
                              style: context.theme.typography.body.md.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FBadge(
                            variant: FBadgeVariant.outline,
                            child: Text(session.visibility.label),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Analyses list in current session
                      if (analyses.isEmpty)
                        FCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 32,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  FLucideIcons.activity,
                                  size: 32,
                                  color: context.theme.colors.mutedForeground,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  context.tr('sessions.noAnalysesYetInSession'),
                                  style: context.theme.typography.body.sm
                                      .copyWith(
                                        color: context
                                            .theme
                                            .colors
                                            .mutedForeground,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 250.ms)
                      else
                        Column(
                          children: [
                            for (int i = 0; i < analyses.length; i++) ...[
                              _ActiveSessionAnalysisCard(analysis: analyses[i])
                                  .animate()
                                  .fadeIn(
                                    duration: 250.ms,
                                    delay: (40 * i).ms,
                                    curve: Curves.easeOut,
                                  )
                                  .slideY(begin: 0.04, end: 0),
                              if (i < analyses.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action bar: "Nouvelle analyse"
            Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: FButton(
                  onPress: () =>
                      context.pushNamed(AppRoute.analysisSelection.name),
                  prefix: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(FLucideIcons.plus, size: 18),
                  ),
                  child: Text(context.tr('sessions.newAnalysisButton')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionAnalysisCard extends StatelessWidget {
  const _ActiveSessionAnalysisCard({required this.analysis});

  final ClimbAnalysisSummary analysis;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(analysis.createdAt);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'à $timeStr',
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                FBadge(
                  variant: analysis.isCompleted
                      ? FBadgeVariant.secondary
                      : FBadgeVariant.primary,
                  child: Text(analysis.status.label),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              analysis.title,
              style: context.theme.typography.body.md.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (analysis.isInProgress) ...[
              const SizedBox(height: 10),
              Text(
                'En cours ${analysis.progressPercentage ?? 0}%, encore ${analysis.remainingSeconds ?? 0}s',
                style: context.theme.typography.body.xs.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 6),
              FDeterminateProgress(
                value: ((analysis.progressPercentage ?? 0) / 100.0).clamp(
                  0.0,
                  1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
