// @date 2026-09-07
// @file interactive_concentric_rings.dart
// @brief Visualisateur multi-anneaux concentriques interactif pour les métriques biomécaniques.
// @project Ascension
// @author Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class ConcentricRingData {
  final String id;
  final String label;
  final String valueDisplay;
  final double progress; // 0.0 to 1.0
  final Color color;
  final IconData icon;
  final String detail;

  const ConcentricRingData({
    required this.id,
    required this.label,
    required this.valueDisplay,
    required this.progress,
    required this.color,
    required this.icon,
    required this.detail,
  });
}

class InteractiveConcentricRings extends StatefulWidget {
  final List<ConcentricRingData> rings;
  final double size;
  final double ringWidth;
  final double ringSpacing;
  final String defaultCenterTitle;
  final String defaultCenterSubtitle;

  const InteractiveConcentricRings({
    super.key,
    required this.rings,
    this.size = 170,
    this.ringWidth = 10,
    this.ringSpacing = 5,
    this.defaultCenterTitle = 'Score',
    this.defaultCenterSubtitle = 'Global',
  });

  @override
  State<InteractiveConcentricRings> createState() =>
      _InteractiveConcentricRingsState();
}

class _InteractiveConcentricRingsState
    extends State<InteractiveConcentricRings> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    final activeRing =
        _hoveredIndex != null &&
            _hoveredIndex! >= 0 &&
            _hoveredIndex! < widget.rings.length
        ? widget.rings[_hoveredIndex!]
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Concentric rings painter
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, anim, _) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _ConcentricRingsPainter(
                      rings: widget.rings,
                      animProgress: anim,
                      ringWidth: widget.ringWidth,
                      ringSpacing: widget.ringSpacing,
                      trackColor: colors.muted.withValues(alpha: 0.25),
                      hoveredIndex: _hoveredIndex,
                    ),
                  );
                },
              ),

              // Interactive Center Info
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: activeRing != null
                    ? Column(
                        key: ValueKey('ring-${activeRing.id}'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            activeRing.icon,
                            size: 20,
                            color: activeRing.color,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            activeRing.valueDisplay,
                            style: typo.display.sm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.foreground,
                            ),
                          ),
                          Text(
                            activeRing.label,
                            style: typo.body.xs.copyWith(
                              color: colors.mutedForeground,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('default-center'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.defaultCenterTitle,
                            style: typo.display.sm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.foreground,
                            ),
                          ),
                          Text(
                            widget.defaultCenterSubtitle,
                            style: typo.body.xs.copyWith(
                              color: colors.mutedForeground,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Interactive interactive chips below
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: List.generate(widget.rings.length, (index) {
            final ring = widget.rings[index];
            final isSelected = _hoveredIndex == index;

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _hoveredIndex = _hoveredIndex == index ? null : index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ring.color.withValues(alpha: 0.16)
                        : colors.muted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? ring.color
                          : colors.border.withValues(alpha: 0.5),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ring.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${ring.label} (${ring.valueDisplay})',
                        style: typo.body.xs.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? colors.foreground
                              : colors.mutedForeground,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ConcentricRingsPainter extends CustomPainter {
  final List<ConcentricRingData> rings;
  final double animProgress;
  final double ringWidth;
  final double ringSpacing;
  final Color trackColor;
  final int? hoveredIndex;

  _ConcentricRingsPainter({
    required this.rings,
    required this.animProgress,
    required this.ringWidth,
    required this.ringSpacing,
    required this.trackColor,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width - ringWidth) / 2;

    for (int i = 0; i < rings.length; i++) {
      final ring = rings[i];
      final isHovered = hoveredIndex == i;
      final isDimmed = hoveredIndex != null && hoveredIndex != i;

      final currentWidth = isHovered ? ringWidth + 2 : ringWidth;
      final radius = maxRadius - i * (ringWidth + ringSpacing);

      if (radius <= 0) continue;

      // Draw background track
      final trackPaint = Paint()
        ..color = isDimmed ? trackColor.withValues(alpha: 0.1) : trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, trackPaint);

      // Draw progress arc
      final clamped = ring.progress.clamp(0.0, 1.0);
      final currentProgress = clamped * animProgress;
      if (currentProgress <= 0.0) continue;

      final sweepAngle = 2 * math.pi * currentProgress;

      // Optional ambient glow on hover
      if (isHovered) {
        final glowPaint = Paint()
          ..color = ring.color.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentWidth + 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          sweepAngle,
          false,
          glowPaint,
        );
      }

      final progressPaint = Paint()
        ..color = isDimmed ? ring.color.withValues(alpha: 0.3) : ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingsPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.rings != rings;
  }
}
