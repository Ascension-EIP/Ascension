// @date 2026-09-07
// @file stats_page.dart
// @brief Page des statistiques d'analyses avec composants Forui.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/features/stats/presentation/widgets/interactive_activity_chart.dart';
import 'package:mobile/features/stats/presentation/widgets/interactive_performance_donut.dart';
import 'package:mobile/features/upload/presentation/pages/analysis_page.dart';
import 'package:mobile/shared/components/header.dart';
import 'package:mobile/shared/components/interactive_circular_gauge.dart';
import 'package:mobile/shared/localization/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum _Filter { all, completed, failed }

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<AnalysisHistoryEntry>? _history;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final userId = AuthService().userId;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _history = []);
      return;
    }
    final entries = await AnalysisHistoryService().getHistory(userId);
    if (!mounted) return;
    setState(() => _history = entries);
  }

  List<AnalysisHistoryEntry> _applyFilter(List<AnalysisHistoryEntry> source) {
    switch (_filter) {
      case _Filter.all:
        return source;
      case _Filter.completed:
        return source.where((e) => e.isCompleted).toList();
      case _Filter.failed:
        return source.where((e) => !e.isCompleted).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: Header(
        title: l10n.t('stats.title'),
        description: l10n.t('stats.description'),
      ),
      body: RefreshIndicator(onRefresh: _loadHistory, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    final typo = context.theme.typography;
    final history = _history;

    if (history == null) {
      final dummy = List.generate(
        3,
        (i) => AnalysisHistoryEntry(
          analysisId: 'placeholder-$i',
          createdAt: DateTime.now(),
          status: 'completed',
          processingTimeMs: 1500,
          resultJson: '{"frames":[{"pose_detected":true}]}',
        ),
      );
      return Skeletonizer(
        enabled: true,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _PerformanceOverviewHub(history: dummy),
            const SizedBox(height: 16),
            InteractiveActivityChart(history: dummy),
            const SizedBox(height: 24),
            Text(
              l10n.t('stats.recentTitle'),
              style: typo.display.lg.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final e in dummy)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AnalysisCard(entry: e),
              ),
          ],
        ),
      );
    }

    if (history.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          _EmptyState(
                icon: FLucideIcons.chartSpline,
                title: l10n.t('stats.emptyTitle'),
                subtitle: l10n.t('stats.emptySubtitle'),
              )
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
        ],
      );
    }

    final filtered = _applyFilter(history);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _PerformanceOverviewHub(history: history)
            .animate()
            .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        InteractiveActivityChart(history: history)
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 24),
        Text(
          l10n.t('stats.recentTitle'),
          style: typo.display.lg.copyWith(fontWeight: FontWeight.w700),
        ).animate().fadeIn(
          duration: 350.ms,
          delay: 150.ms,
          curve: Curves.easeOutCubic,
        ),
        const SizedBox(height: 12),
        _FilterBar(
          value: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ).animate().fadeIn(
          duration: 350.ms,
          delay: 180.ms,
          curve: Curves.easeOutCubic,
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _EmptyState(
              icon: FLucideIcons.filterX,
              title: l10n.t('stats.emptyFilterTitle'),
              subtitle: l10n.t('stats.emptyFilterSubtitle'),
              compact: true,
            ),
          ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
        else
          for (int i = 0; i < filtered.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnalysisCard(entry: filtered[i])
                  .animate()
                  .fadeIn(
                    duration: 350.ms,
                    delay: (50 * i).ms,
                    curve: Curves.easeOutCubic,
                  )
                  .slideX(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            ),
      ],
    );
  }
}

// ── Performance overview hub ──

class _PerformanceOverviewHub extends StatelessWidget {
  final List<AnalysisHistoryEntry> history;
  const _PerformanceOverviewHub({required this.history});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    final total = history.length;
    final completed = history.where((e) => e.isCompleted).toList();
    final failed = total - completed.length;
    final successRate = total == 0 ? 0.0 : (completed.length / total) * 100;

    final durations = completed
        .where((e) => e.processingTimeMs != null)
        .map((e) => e.processingTimeMs!)
        .toList();
    final avgDurationS = durations.isEmpty
        ? 0.0
        : durations.reduce((a, b) => a + b) / durations.length / 1000;

    final detectionRates = completed
        .where((e) => e.frameCount > 0)
        .map((e) => e.detectionRate)
        .toList();
    final avgDetection = detectionRates.isEmpty
        ? 0.0
        : detectionRates.reduce((a, b) => a + b) / detectionRates.length;

    return Container(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.t('stats.breakdownTitle'),
                  style: typo.body.md.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(FLucideIcons.pieChart, size: 18, color: colors.primary),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            l10n.t('stats.hoverHint'),
            style: typo.body.xs.copyWith(
              color: colors.mutedForeground,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          // Central Interactive Performance Donut
          InteractivePerformanceDonut(
            completedCount: completed.length,
            failedCount: failed,
          ),

          const SizedBox(height: 20),
          Divider(color: colors.border.withValues(alpha: 0.3)),
          const SizedBox(height: 16),

          // Responsive interactive circular gauges row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: InteractiveCircularGauge(
                  value: total == 0 ? 0.0 : (completed.length / total),
                  displayValue: '${successRate.toStringAsFixed(0)}%',
                  label: l10n.t('stats.successRate'),
                  icon: FLucideIcons.checkCircle,
                  color: const Color(0xFF10B981),
                  size: 78,
                  strokeWidth: 5.5,
                  tooltipText: '${completed.length}/$total réussies',
                ),
              ),
              Expanded(
                child: InteractiveCircularGauge(
                  value: (avgDetection / 100).clamp(0.0, 1.0),
                  displayValue: '${avgDetection.toStringAsFixed(0)}%',
                  label: l10n.t('stats.avgDetection'),
                  icon: FLucideIcons.userCheck,
                  color: const Color(0xFF0EA5E9),
                  size: 78,
                  strokeWidth: 5.5,
                  tooltipText:
                      'Précision IA : ${avgDetection.toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: InteractiveCircularGauge(
                  value: (avgDurationS / 60).clamp(0.0, 1.0),
                  displayValue: '${avgDurationS.toStringAsFixed(1)}s',
                  label: l10n.t('stats.avgDuration'),
                  icon: FLucideIcons.timer,
                  color: const Color(0xFFF59E0B),
                  size: 78,
                  strokeWidth: 5.5,
                  tooltipText:
                      'Durée moyenne : ${avgDurationS.toStringAsFixed(1)}s',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ──

class _FilterBar extends StatelessWidget {
  final _Filter value;
  final ValueChanged<_Filter> onChanged;
  const _FilterBar({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    final options = [
      (_Filter.all, l10n.t('stats.filterAll')),
      (_Filter.completed, l10n.t('stats.filterCompleted')),
      (_Filter.failed, l10n.t('stats.filterFailed')),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: options.map((o) {
          final isSelected = value == o.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? colors.background : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: colors.border) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  o.$2,
                  style: typo.body.sm.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colors.foreground
                        : colors.mutedForeground,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Analysis card ──

class _AnalysisCard extends StatelessWidget {
  final AnalysisHistoryEntry entry;
  const _AnalysisCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final isCompleted = entry.isCompleted;
    final accent = isCompleted ? const Color(0xFF10B981) : colors.destructive;
    final canOpen = isCompleted && entry.resultJson != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canOpen
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AnalysisViewPage(
                        resultJson: entry.resultJson!,
                        processingMs: entry.processingTimeMs,
                        videoFile: null,
                      ),
                    ),
                  );
                }
              : null,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted
                                ? FLucideIcons.check
                                : FLucideIcons.circleAlert,
                            size: 18,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDate(context, entry.createdAt),
                                      style: typo.body.sm.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colors.foreground,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  isCompleted
                                      ? FBadge(
                                          child: Text(
                                            l10n.t('stats.statusCompleted'),
                                          ),
                                        )
                                      : FBadge(
                                          variant: FBadgeVariant.destructive,
                                          child: Text(
                                            l10n.t('stats.statusFailed'),
                                          ),
                                        ),
                                ],
                              ),
                              if (isCompleted) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    if (entry.processingTimeMs != null)
                                      _MetricPill(
                                        icon: FLucideIcons.timer,
                                        label:
                                            '${(entry.processingTimeMs! / 1000).toStringAsFixed(1)} s',
                                      ),
                                    if (entry.frameCount > 0)
                                      _MetricPill(
                                        icon: FLucideIcons.fileVideo,
                                        label: l10n.tr('stats.frames', {
                                          'count': '${entry.frameCount}',
                                        }),
                                      ),
                                    if (entry.frameCount > 0)
                                      _MetricPill(
                                        icon: FLucideIcons.user,
                                        label: l10n.tr('stats.detectedRate', {
                                          'rate': entry.detectionRate
                                              .toStringAsFixed(0),
                                        }),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (canOpen) ...[
                          const SizedBox(width: 8),
                          Icon(
                            FLucideIcons.chevronRight,
                            size: 18,
                            color: colors.mutedForeground,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(dt);
    final time = '${_pad(dt.hour)}:${_pad(dt.minute)}';
    final date = '${_pad(dt.day)}/${_pad(dt.month)}/${dt.year}';

    if (diff.inDays == 0) {
      return l10n.tr('date.todayAt', {'time': time});
    } else if (diff.inDays == 1) {
      return l10n.tr('date.yesterdayAt', {'time': time});
    } else if (diff.inDays < 7) {
      final days = [
        l10n.t('date.day.monday'),
        l10n.t('date.day.tuesday'),
        l10n.t('date.day.wednesday'),
        l10n.t('date.day.thursday'),
        l10n.t('date.day.friday'),
        l10n.t('date.day.saturday'),
        l10n.t('date.day.sunday'),
      ];
      return l10n.tr('date.at', {'day': days[dt.weekday - 1], 'time': time});
    } else {
      return l10n.tr('date.full', {'date': date, 'time': time});
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetricPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.mutedForeground),
        const SizedBox(width: 4),
        Text(label, style: typo.body.xs),
      ],
    );
  }
}

// ── Empty state ──

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return Column(
      children: [
        Container(
          width: compact ? 56 : 72,
          height: compact ? 56 : 72,
          decoration: BoxDecoration(
            color: colors.muted,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: compact ? 26 : 32,
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),
        Text(title, style: typo.body.md.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: typo.body.sm.copyWith(color: colors.mutedForeground),
        ),
      ],
    );
  }
}
