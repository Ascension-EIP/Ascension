// @date 2026-09-07
// @file interactive_circular_gauge.dart
// @brief Jauge circulaire interactive avec support de survol (hover) et animations.
// @project Ascension
// @author Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class InteractiveCircularGauge extends StatefulWidget {
  final double value; // Between 0.0 and 1.0
  final String displayValue;
  final String label;
  final IconData? icon;
  final Color color;
  final String? tooltipText;
  final double size;
  final double strokeWidth;
  final VoidCallback? onTap;

  const InteractiveCircularGauge({
    super.key,
    required this.value,
    required this.displayValue,
    required this.label,
    this.icon,
    required this.color,
    this.tooltipText,
    this.size = 100,
    this.strokeWidth = 7,
    this.onTap,
  });

  @override
  State<InteractiveCircularGauge> createState() =>
      _InteractiveCircularGaugeState();
}

class _InteractiveCircularGaugeState extends State<InteractiveCircularGauge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final clampedValue = widget.value.clamp(0.0, 1.0);

    final gaugeWidget = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          widget.onTap?.call();
          setState(() => _isHovered = !_isHovered);
        },
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Ambient glow on hover
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: widget.size * 0.9,
                    height: widget.size * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.28),
                                blurRadius: 18,
                                spreadRadius: 3,
                              ),
                            ]
                          : [],
                    ),
                  ),

                  // Custom circular progress arc
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: clampedValue),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return CustomPaint(
                          painter: _CircularGaugePainter(
                            progress: val,
                            color: widget.color,
                            trackColor: colors.muted.withValues(alpha: 0.35),
                            strokeWidth: _isHovered
                                ? widget.strokeWidth + 1.5
                                : widget.strokeWidth,
                            isHovered: _isHovered,
                          ),
                        );
                      },
                    ),
                  ),

                  // Center content
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: 14,
                            color: _isHovered
                                ? widget.color
                                : colors.mutedForeground,
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          widget.displayValue,
                          style: TextStyle(
                            fontSize: widget.size > 90 ? 17 : 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: colors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: typo.body.xs.copyWith(
                    fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                    color: _isHovered
                        ? colors.foreground
                        : colors.mutedForeground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltipText != null && widget.tooltipText!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltipText!,
        waitDuration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.foreground,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: gaugeWidget,
      );
    }

    return gaugeWidget;
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final bool isHovered;

  _CircularGaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    // Foreground progress arc
    final sweepAngle = 2 * math.pi * progress;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from top (-pi / 2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isHovered != isHovered;
  }
}
