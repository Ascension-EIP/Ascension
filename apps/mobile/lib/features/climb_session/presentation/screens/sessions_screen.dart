// @date 2026-11-13
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

enum _SessionFilter { all, friends, public, private }

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
        case _SessionFilter.private:
          return s.visibility == ClimbSessionVisibility.private;
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                        Skeleton.ignore(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.tr('sessions.sortBy'),
                                style: context.theme.typography.body.xs
                                    .copyWith(
                                      color:
                                          context.theme.colors.mutedForeground,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              PopupMenuButton<_SessionFilter>(
                                initialValue: _selectedFilter,
                                onSelected: (filter) =>
                                    setState(() => _selectedFilter = filter),
                                color: context.theme.colors.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: context.theme.colors.border,
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: _SessionFilter.all,
                                    child: Text(
                                      context.tr('sessions.sort.all'),
                                      style: context.theme.typography.body.sm
                                          .copyWith(
                                            fontWeight:
                                                _selectedFilter ==
                                                    _SessionFilter.all
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: _SessionFilter.friends,
                                    child: Text(
                                      context.tr('sessions.sort.friends'),
                                      style: context.theme.typography.body.sm
                                          .copyWith(
                                            fontWeight:
                                                _selectedFilter ==
                                                    _SessionFilter.friends
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: _SessionFilter.public,
                                    child: Text(
                                      context.tr('sessions.sort.public'),
                                      style: context.theme.typography.body.sm
                                          .copyWith(
                                            fontWeight:
                                                _selectedFilter ==
                                                    _SessionFilter.public
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: _SessionFilter.private,
                                    child: Text(
                                      context.tr('sessions.sort.private'),
                                      style: context.theme.typography.body.sm
                                          .copyWith(
                                            fontWeight:
                                                _selectedFilter ==
                                                    _SessionFilter.private
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ),
                                ],
                                child: _FilterChip(
                                  label: _filterLabel(context, _selectedFilter),
                                ),
                              ),
                            ],
                          ),
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

  String _filterLabel(BuildContext context, _SessionFilter filter) {
    switch (filter) {
      case _SessionFilter.all:
        return context.tr('sessions.sort.all');
      case _SessionFilter.friends:
        return context.tr('sessions.sort.friends');
      case _SessionFilter.public:
        return context.tr('sessions.sort.public');
      case _SessionFilter.private:
        return context.tr('sessions.sort.private');
    }
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
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: context.theme.colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('sessions.resume'),
                        style: context.theme.typography.body.xs.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.theme.colors.primary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    FLucideIcons.chevronRight,
                    size: 16,
                    color: context.theme.colors.mutedForeground,
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${session.analyses.length} ${session.analyses.length > 1 ? context.tr('sessions.analysesPlural') : context.tr('sessions.analysisSingular')}',
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  FBadge(
                    variant: FBadgeVariant.primary,
                    child: Text(
                      '${context.tr('sessions.since')} $formattedDuration',
                    ),
                  ),
                ],
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat(
      'EEEE d MMMM, HH:mm',
      locale,
    ).format(session.startedAt);
    final capitalizedDate = dateStr.isNotEmpty
        ? dateStr[0].toUpperCase() + dateStr.substring(1)
        : '';
    final durationStr = _formatDuration(session.duration);

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
                    capitalizedDate,
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                FBadge(
                  variant: FBadgeVariant.outline,
                  child: Text(context.tr(session.visibility.translationKey)),
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
            if (session.location != null && session.location!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    FLucideIcons.mapPin,
                    size: 14,
                    color: context.theme.colors.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      session.location!,
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  FLucideIcons.scan,
                  size: 14,
                  color: context.theme.colors.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.analyses.length} ${session.analyses.length > 1 ? context.tr('sessions.analysesPlural') : context.tr('sessions.analysisSingular')}',
                  style: context.theme.typography.body.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  FLucideIcons.clock,
                  size: 14,
                  color: context.theme.colors.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  durationStr,
                  style: context.theme.typography.body.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
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
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat(
      'd MMMM, HH:mm',
      locale,
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
              child: Text(context.tr(analysis.status.translationKey)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    );
  }
}
