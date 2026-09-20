// @date 2026-09-07
// @file interactive_activity_chart.dart
// @brief Graphique d'activité des 7 derniers jours avec interactions au survol et design modernisé.
// @project Ascension
// @author Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

class InteractiveActivityChart extends StatefulWidget {
  final List<AnalysisHistoryEntry> history;

  const InteractiveActivityChart({super.key, required this.history});

  @override
  State<InteractiveActivityChart> createState() =>
      _InteractiveActivityChartState();
}

class _InteractiveActivityChartState extends State<InteractiveActivityChart> {
  int? _hoveredIndex;

  static const _dayKeys = [
    'date.dayShort.monday',
    'date.dayShort.tuesday',
    'date.dayShort.wednesday',
    'date.dayShort.thursday',
    'date.dayShort.friday',
    'date.dayShort.saturday',
    'date.dayShort.sunday',
  ];

  static const _fullDayKeys = [
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
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    final counts = days.map((day) {
      return widget.history.where((e) {
        final d = e.createdAt;
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).length;
    }).toList();

    final maxCount = counts.fold<int>(1, (m, c) => c > m ? c : m);
    final totalWeekly = counts.fold<int>(0, (sum, c) => sum + c);

    // Find peak day
    int peakIndex = 0;
    for (int i = 1; i < counts.length; i++) {
      if (counts[i] > counts[peakIndex]) {
        peakIndex = i;
      }
    }
    final peakDayName = l10n.t(_fullDayKeys[days[peakIndex].weekday - 1]);

    return Container(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with activity title and badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      FLucideIcons.chartSpline,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.t('stats.activityTitle'),
                        style: typo.body.md.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.foreground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FBadge(
                variant: FBadgeVariant.primary,
                child: Text(l10n.t('stats.activitySubtitle')),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Sub-row: total this week and peak day
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.tr('stats.activeWeekTotal', {'count': '$totalWeekly'}),
                  style: typo.body.xs.copyWith(color: colors.mutedForeground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (totalWeekly > 0) ...[
                const SizedBox(width: 8),
                Text(
                  l10n.tr('stats.peakDay', {'day': peakDayName}),
                  style: typo.body.xs.copyWith(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: (maxCount + 1).toDouble(),
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: mathMax(1.0, (maxCount / 3).toDouble()),
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: colors.border.withValues(alpha: 0.25),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.card,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tooltipBorder: BorderSide(
                      color: colors.primary.withValues(alpha: 0.5),
                    ),
                    getTooltipItem: (group, _, rod, _) {
                      final dayIndex = group.x.toInt();
                      final day = days[dayIndex];
                      final dayLabel = l10n.t(_fullDayKeys[day.weekday - 1]);
                      final dateStr = '${day.day}/${day.month}';
                      return BarTooltipItem(
                        '$dayLabel ($dateStr)\n',
                        typo.body.xs.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} analyses',
                            style: typo.body.xs.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        _hoveredIndex = null;
                        return;
                      }
                      _hoveredIndex = response.spot!.touchedBarGroupIndex;
                    });
                  },
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
                      reservedSize: 30,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        final weekday = days[index].weekday - 1;
                        final label = l10n.t(_dayKeys[weekday]);
                        final isToday = index == days.length - 1;
                        final isHovered = _hoveredIndex == index;

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: typo.body.xs.copyWith(
                              fontWeight: (isToday || isHovered)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isHovered
                                  ? colors.primary
                                  : isToday
                                  ? colors.foreground
                                  : colors.mutedForeground,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(days.length, (i) {
                  final isToday = i == days.length - 1;
                  final isHovered = _hoveredIndex == i;
                  final count = counts[i].toDouble();

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: count,
                        width: isHovered ? 24 : 18,
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isHovered
                              ? [colors.primary, const Color(0xFF10B981)]
                              : isToday
                              ? [
                                  colors.primary.withValues(alpha: 0.8),
                                  colors.primary,
                                ]
                              : [
                                  colors.primary.withValues(alpha: 0.25),
                                  colors.primary.withValues(alpha: 0.5),
                                ],
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: (maxCount + 1).toDouble(),
                          color: colors.muted.withValues(alpha: 0.15),
                        ),
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

  double mathMax(double a, double b) => a > b ? a : b;
}
