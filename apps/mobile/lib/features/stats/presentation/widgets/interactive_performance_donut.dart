// @date 2026-09-07
// @file interactive_performance_donut.dart
// @brief Diagramme circulaire (donut) interactif au survol pour la répartition des ascensions.
// @project Ascension
// @author Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

class InteractivePerformanceDonut extends StatefulWidget {
  final int completedCount;
  final int failedCount;

  const InteractivePerformanceDonut({
    super.key,
    required this.completedCount,
    required this.failedCount,
  });

  @override
  State<InteractivePerformanceDonut> createState() =>
      _InteractivePerformanceDonutState();
}

class _InteractivePerformanceDonutState
    extends State<InteractivePerformanceDonut> {
  int _touchedIndex = -1;

  static const Color _successColor = Color(0xFF10B981); // Emerald
  static const Color _failedColor = Color(0xFFEF4444); // Red/destructive

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    final total = widget.completedCount + widget.failedCount;
    final successRate = total == 0
        ? 0.0
        : (widget.completedCount / total) * 100;

    String centerTitle;
    String centerSubtitle;
    Color centerColor;

    if (_touchedIndex == 0) {
      centerTitle = '${widget.completedCount}';
      centerSubtitle =
          '${l10n.t('stats.successBreakdown')} (${successRate.toStringAsFixed(0)}%)';
      centerColor = _successColor;
    } else if (_touchedIndex == 1) {
      final failRate = total == 0 ? 0.0 : (widget.failedCount / total) * 100;
      centerTitle = '${widget.failedCount}';
      centerSubtitle =
          '${l10n.t('stats.failedBreakdown')} (${failRate.toStringAsFixed(0)}%)';
      centerColor = _failedColor;
    } else {
      centerTitle = total == 0 ? '0' : '${successRate.toStringAsFixed(0)}%';
      centerSubtitle = l10n.t('stats.successRate');
      centerColor = colors.foreground;
    }

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 4,
                  centerSpaceRadius: 58,
                  sections: _buildSections(total),
                ),
              ),

              // Animated Center Readout
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Column(
                  key: ValueKey('center-$_touchedIndex-$total'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerTitle,
                      style: typo.display.md.copyWith(
                        fontWeight: FontWeight.w800,
                        color: centerColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      centerSubtitle,
                      textAlign: TextAlign.center,
                      style: typo.body.xs.copyWith(
                        color: colors.mutedForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Interactive interactive chips
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            _LegendPill(
              label: l10n.t('stats.successBreakdown'),
              count: widget.completedCount,
              color: _successColor,
              isSelected: _touchedIndex == 0,
              onTap: () {
                setState(() => _touchedIndex = _touchedIndex == 0 ? -1 : 0);
              },
            ),
            _LegendPill(
              label: l10n.t('stats.failedBreakdown'),
              count: widget.failedCount,
              color: _failedColor,
              isSelected: _touchedIndex == 1,
              onTap: () {
                setState(() => _touchedIndex = _touchedIndex == 1 ? -1 : 1);
              },
            ),
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(int total) {
    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.withValues(alpha: 0.25),
          value: 1,
          radius: 22,
          showTitle: false,
        ),
      ];
    }

    final isCompletedSelected = _touchedIndex == 0;
    final isFailedSelected = _touchedIndex == 1;

    final List<PieChartSectionData> list = [];

    if (widget.completedCount > 0) {
      list.add(
        PieChartSectionData(
          color: _successColor,
          value: widget.completedCount.toDouble(),
          radius: isCompletedSelected ? 30 : 24,
          showTitle: false,
          badgeWidget: isCompletedSelected
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FLucideIcons.check,
                    color: _successColor,
                    size: 12,
                  ),
                )
              : null,
          badgePositionPercentageOffset: 1.15,
        ),
      );
    }

    if (widget.failedCount > 0) {
      list.add(
        PieChartSectionData(
          color: _failedColor,
          value: widget.failedCount.toDouble(),
          radius: isFailedSelected ? 30 : 24,
          showTitle: false,
          badgeWidget: isFailedSelected
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FLucideIcons.circleAlert,
                    color: _failedColor,
                    size: 12,
                  ),
                )
              : null,
          badgePositionPercentageOffset: 1.15,
        ),
      );
    }

    return list;
  }
}

class _LegendPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _LegendPill({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : colors.muted.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : colors.border.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                '$label: $count',
                style: typo.body.xs.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colors.foreground
                      : colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
