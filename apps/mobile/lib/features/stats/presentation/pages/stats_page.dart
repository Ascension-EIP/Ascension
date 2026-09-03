// @date 2026-09-03
// @file stats_page.dart
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/features/upload/presentation/pages/analysis_page.dart';
import 'package:mobile/shared/components/header.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

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
    final theme = ShadTheme.of(context);
    final history = _history;

    if (history == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (history.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          _EmptyState(
            icon: Icons.insights_rounded,
            title: l10n.t('stats.emptyTitle'),
            subtitle: l10n.t('stats.emptySubtitle'),
          ),
        ],
      );
    }

    final filtered = _applyFilter(history);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SummaryGrid(history: history),
        const SizedBox(height: 16),
        _ActivityChartCard(history: history),
        const SizedBox(height: 24),
        Text(l10n.t('stats.recentTitle'), style: theme.textTheme.h4),
        const SizedBox(height: 12),
        _FilterBar(
          value: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _EmptyState(
              icon: Icons.filter_alt_off_rounded,
              title: l10n.t('stats.emptyFilterTitle'),
              subtitle: l10n.t('stats.emptyFilterSubtitle'),
              compact: true,
            ),
          )
        else
          ...filtered.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnalysisCard(entry: e),
            ),
          ),
      ],
    );
  }
}

// ── Summary grid ──

class _SummaryGrid extends StatelessWidget {
  final List<AnalysisHistoryEntry> history;
  const _SummaryGrid({required this.history});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);

    final total = history.length;
    final completed = history.where((e) => e.isCompleted).toList();
    final successRate = total == 0 ? 0.0 : completed.length / total * 100;

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

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: [
        _StatCard(
          icon: Icons.bar_chart_rounded,
          label: l10n.t('stats.totalAnalyses'),
          value: '$total',
          color: theme.colorScheme.primary,
        ),
        _StatCard(
          icon: Icons.check_circle_rounded,
          label: l10n.t('stats.successRate'),
          value: '${successRate.toStringAsFixed(0)}%',
          color: _AccentColors.emerald,
        ),
        _StatCard(
          icon: Icons.timer_rounded,
          label: l10n.t('stats.avgDuration'),
          value: '${avgDurationS.toStringAsFixed(1)}s',
          color: _AccentColors.amber,
        ),
        _StatCard(
          icon: Icons.person_search_rounded,
          label: l10n.t('stats.avgDetection'),
          value: '${avgDetection.toStringAsFixed(0)}%',
          color: _AccentColors.sky,
        ),
      ],
    );
  }
}

/// Minimal accent palette so summary cards get distinct colors without
/// depending on the app's single-brand shadcn scheme.
class _AccentColors {
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const sky = Color(0xFF0EA5E9);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.muted.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Activity chart ──

class _ActivityChartCard extends StatelessWidget {
  final List<AnalysisHistoryEntry> history;
  const _ActivityChartCard({required this.history});

  static const _dayKeys = [
    'date.day.monday',
    'date.day.tuesday',
    'date.day.wednesday',
    'date.day.thursday',
    'date.day.friday',
    'date.day.saturday',
    'date.day.sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    final counts = days.map((day) {
      return history.where((e) {
        final d = e.createdAt;
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).length;
    }).toList();

    final maxCount = counts.fold<int>(1, (m, c) => c > m ? c : m);

    return ShadCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.t('stats.activityTitle'), style: theme.textTheme.h4),
          Text(l10n.t('stats.activitySubtitle'), style: theme.textTheme.muted),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: (maxCount + 1).toDouble(),
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.popover,
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      rod.toY.toInt().toString(),
                      theme.textTheme.small.copyWith(
                        color: theme.colorScheme.popoverForeground,
                      ),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        final weekday = days[index].weekday - 1;
                        final label = l10n.t(_dayKeys[weekday]);
                        final isToday = index == days.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label.substring(0, 3),
                            style: theme.textTheme.small.copyWith(
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isToday
                                  ? theme.colorScheme.foreground
                                  : theme.colorScheme.mutedForeground,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(days.length, (i) {
                  final isToday = i == days.length - 1;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: counts[i].toDouble(),
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                        color: isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.35),
                      ),
                    ],
                  );
                }),
              ),
            ),
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
    final theme = ShadTheme.of(context);

    final options = [
      (_Filter.all, l10n.t('stats.filterAll')),
      (_Filter.completed, l10n.t('stats.filterCompleted')),
      (_Filter.failed, l10n.t('stats.filterFailed')),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.5),
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
                  color: isSelected
                      ? theme.colorScheme.background
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: theme.colorScheme.border)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  o.$2,
                  style: theme.textTheme.small.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.foreground
                        : theme.colorScheme.mutedForeground,
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
    final theme = ShadTheme.of(context);
    final isCompleted = entry.isCompleted;
    final accent = isCompleted
        ? theme.colorScheme.primary
        : theme.colorScheme.destructive;
    final canOpen = isCompleted && entry.resultJson != null;

    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : Icons.priority_high_rounded,
                  size: 20,
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
                            style: theme.textTheme.small.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        isCompleted
                            ? ShadBadge(
                                backgroundColor: accent.withValues(alpha: 0.12),
                                foregroundColor: accent,
                                child: Text(l10n.t('stats.statusCompleted')),
                              )
                            : ShadBadge.destructive(
                                backgroundColor: accent.withValues(alpha: 0.12),
                                foregroundColor: accent,
                                child: Text(l10n.t('stats.statusFailed')),
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
                            _StatChip(
                              icon: Icons.timer_outlined,
                              label:
                                  '${(entry.processingTimeMs! / 1000).toStringAsFixed(1)} s',
                            ),
                          if (entry.frameCount > 0)
                            _StatChip(
                              icon: Icons.video_file_outlined,
                              label: l10n.tr('stats.frames', {
                                'count': '${entry.frameCount}',
                              }),
                            ),
                          if (entry.frameCount > 0)
                            _StatChip(
                              icon: Icons.person_outlined,
                              label: l10n.tr('stats.detectedRate', {
                                'rate': entry.detectionRate.toStringAsFixed(0),
                              }),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (canOpen) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.mutedForeground,
                ),
              ],
            ],
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.small.copyWith(fontSize: 12)),
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
    final theme = ShadTheme.of(context);
    return Column(
      children: [
        Container(
          width: compact ? 56 : 72,
          height: compact ? 56 : 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.muted,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: compact ? 26 : 32,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.muted,
        ),
      ],
    );
  }
}
