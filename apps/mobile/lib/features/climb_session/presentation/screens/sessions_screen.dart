// @date 2026-11-06
// @file sessions_screen.dart
// @brief Main sessions screen with active session banner, history, and analysis entry.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:mobile/features/climb_session/presentation/controllers/climb_session_controller.dart';
import 'package:mobile/features/climb_session/presentation/widgets/no_session_dialog.dart';
import 'package:mobile/routing/routes.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum _SessionFilter { all, friends, public }

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  _SessionFilter _selectedFilter = _SessionFilter.all;

  Future<void> _handleStartAnalysis() async {
    final state = ref.read(climbSessionControllerProvider);
    if (state.hasActiveSession) {
      await context.pushNamed(AppRoute.analysisSelection.name);
      return;
    }

    final wantCreateSession = await showNoSessionDialog(context);
    if (!mounted) return;

    if (wantCreateSession == true) {
      await context.pushNamed(AppRoute.newSession.name);
    } else if (wantCreateSession == false) {
      await context.pushNamed(AppRoute.analysisSelection.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(climbSessionControllerProvider);
    final hasActive = state.hasActiveSession;
    final activeSession = state.activeSession;

    final filteredSessions = state.previousSessions.where((s) {
      switch (_selectedFilter) {
        case _SessionFilter.all:
          return true;
        case _SessionFilter.friends:
          return s.visibility == ClimbSessionVisibility.friends;
        case _SessionFilter.public:
          return s.visibility == ClimbSessionVisibility.public;
      }
    }).toList();

    return FScaffold(
      header: FHeader(title: Text(context.tr('sessions.title'))),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(climbSessionControllerProvider.notifier).loadSessions(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Skeletonizer(
                enabled: state.isLoading,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Action: Start new session OR Resume active session
                    if (hasActive && activeSession != null)
                      _ActiveSessionCard(
                        session: activeSession,
                        formattedDuration: state.formattedActiveDuration,
                        onPress: () => unawaited(
                          context.pushNamed(AppRoute.activeSession.name),
                        ),
                      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04)
                    else
                      FButton(
                        onPress: () => unawaited(
                          context.pushNamed(AppRoute.newSession.name),
                        ),
                        prefix: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(FLucideIcons.play, size: 16),
                        ),
                        child: Text(context.tr('sessions.startNew')),
                      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04),

                    const SizedBox(height: 28),

                    // Section 1: Sessions précédentes with Sort filter
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          context.tr('sessions.previous'),
                          style: context.theme.typography.body.md.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr('sessions.sortBy'),
                              style: context.theme.typography.body.xs.copyWith(
                                color: context.theme.colors.mutedForeground,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _FilterChip(
                              label: _filterLabel(_selectedFilter),
                              onTap: _cycleFilter,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (filteredSessions.isEmpty)
                      FCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          child: Center(
                            child: Text(
                              context.tr('sessions.empty'),
                              style: context.theme.typography.body.sm.copyWith(
                                color: context.theme.colors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (int i = 0; i < filteredSessions.length; i++) ...[
                            _PreviousSessionCard(session: filteredSessions[i])
                                .animate()
                                .fadeIn(
                                  duration: 250.ms,
                                  delay: (30 * i).ms,
                                  curve: Curves.easeOut,
                                )
                                .slideY(begin: 0.03, end: 0),
                            if (i < filteredSessions.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Section 2: Démarrer une analyse Button
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: _handleStartAnalysis,
                      prefix: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(FLucideIcons.scan, size: 16),
                      ),
                      child: Text(context.tr('sessions.startAnalysisButton')),
                    ),

                    const SizedBox(height: 24),

                    // Section 2.b: Analyses précédentes
                    Text(
                      context.tr('sessions.previousAnalysesTitle'),
                      style: context.theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (state.previousAnalyses.isEmpty)
                      FCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Center(
                            child: Text(
                              context.tr('sessions.noPreviousAnalyses'),
                              style: context.theme.typography.body.sm.copyWith(
                                color: context.theme.colors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (
                            int i = 0;
                            i < state.previousAnalyses.length;
                            i++
                          ) ...[
                            _PreviousAnalysisCard(
                                  analysis: state.previousAnalyses[i],
                                )
                                .animate()
                                .fadeIn(
                                  duration: 250.ms,
                                  delay: (30 * i).ms,
                                  curve: Curves.easeOut,
                                )
                                .slideY(begin: 0.03, end: 0),
                            if (i < state.previousAnalyses.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _filterLabel(_SessionFilter filter) {
    switch (filter) {
      case _SessionFilter.all:
        return 'Toutes';
      case _SessionFilter.friends:
        return 'Amis seulement';
      case _SessionFilter.public:
        return 'Publique';
    }
  }

  void _cycleFilter() {
    setState(() {
      _selectedFilter = switch (_selectedFilter) {
        _SessionFilter.all => _SessionFilter.friends,
        _SessionFilter.friends => _SessionFilter.public,
        _SessionFilter.public => _SessionFilter.all,
      };
    });
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.session,
    required this.formattedDuration,
    required this.onPress,
  });

  final ClimbSession session;
  final String formattedDuration;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: context.theme.colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('sessions.resume'),
                        style: context.theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.theme.colors.primary,
                        ),
                      ),
                    ],
                  ),
                  FBadge(
                    variant: FBadgeVariant.primary,
                    child: Text(formattedDuration),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                session.name,
                style: context.theme.typography.body.md.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${session.analyses.length} ${session.analyses.length > 1 ? context.tr('sessions.analysesPlural') : context.tr('sessions.analysisSingular')}',
                style: context.theme.typography.body.xs.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviousSessionCard extends StatelessWidget {
  const _PreviousSessionCard({required this.session});

  final ClimbSession session;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'EEEE d MMMM à HH:mm',
      'fr_FR',
    ).format(session.startedAt);
    final capitalizedDate = dateStr.isNotEmpty
        ? dateStr[0].toUpperCase() + dateStr.substring(1)
        : '';

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    session.authorName != null
                        ? '${session.authorName} | $capitalizedDate'
                        : capitalizedDate,
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                FBadge(
                  variant: FBadgeVariant.outline,
                  child: Text(session.visibility.label),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session.name,
              style: context.theme.typography.body.md.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (session.analyses.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final analysis in session.analyses.take(2))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '• ${analysis.title}',
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ),
              if (session.analyses.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '...',
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviousAnalysisCard extends StatelessWidget {
  const _PreviousAnalysisCard({required this.analysis});

  final ClimbAnalysisSummary analysis;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'd MMMM à HH:mm',
      'fr_FR',
    ).format(analysis.createdAt);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis.title,
                    style: context.theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            FBadge(
              variant: FBadgeVariant.secondary,
              child: Text(analysis.status.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: context.theme.colors.muted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.theme.typography.body.xs.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(FLucideIcons.chevronDown, size: 14),
          ],
        ),
      ),
    );
  }
}
