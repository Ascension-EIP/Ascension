// @date 2026-11-21
// @file media_pipe_skeleton_painter.dart
// @brief Custom painter rendering MediaPipe 33-point skeleton overlaid on climb video.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';

class MediaPipeSkeletonPainter extends CustomPainter {
  MediaPipeSkeletonPainter({
    required this.framePose,
    required this.videoOriginalSize,
    this.showSkeleton = true,
    this.showJoints = true,
    this.showAngles = false,
  });

  final FramePose? framePose;
  final Size videoOriginalSize;
  final bool showSkeleton;
  final bool showJoints;
  final bool showAngles;

  static const double _minVisibility = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    if (!showSkeleton || framePose == null || !framePose!.poseDetected) {
      return;
    }

    final landmarks = framePose!.landmarks;
    if (landmarks.isEmpty) return;

    // Compute the actual video destination rect inside the painter bounds
    final effectiveVideoSize =
        videoOriginalSize.width > 0 && videoOriginalSize.height > 0
        ? videoOriginalSize
        : size;

    final fittedSizes = applyBoxFit(BoxFit.contain, effectiveVideoSize, size);
    final videoRect = Alignment.center.inscribe(
      fittedSizes.destination,
      Offset.zero & size,
    );

    Offset? getPixel(String key) {
      final lm = landmarks[key.toLowerCase()];
      if (lm == null || lm.visibility < _minVisibility) return null;
      return Offset(
        videoRect.left + (lm.x * videoRect.width),
        videoRect.top + (lm.y * videoRect.height),
      );
    }

    // Paints
    final leftSidePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    final rightSidePaint = Paint()
      ..color = const Color(0xFF8C52FF)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    final centralPaint = Paint()
      ..color = const Color(0xFFFFD600)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    final jointFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final jointStrokePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    // 1. Draw Skeleton Connections
    for (final (fromKey, toKey) in MediaPipeConnections.connections) {
      final p1 = getPixel(fromKey);
      final p2 = getPixel(toKey);

      if (p1 != null && p2 != null) {
        Paint bonePaint = centralPaint;
        if (fromKey.startsWith('left_') && toKey.startsWith('left_')) {
          bonePaint = leftSidePaint;
        } else if (fromKey.startsWith('right_') && toKey.startsWith('right_')) {
          bonePaint = rightSidePaint;
        }
        canvas.drawLine(p1, p2, bonePaint);
      }
    }

    // 2. Draw Landmark Joints
    if (showJoints) {
      for (final entry in landmarks.entries) {
        final lm = entry.value;
        if (lm.visibility < _minVisibility) continue;

        final offset = Offset(
          videoRect.left + (lm.x * videoRect.width),
          videoRect.top + (lm.y * videoRect.height),
        );

        final isLeft = entry.key.startsWith('left_');
        final isRight = entry.key.startsWith('right_');
        final jointRadius =
            (entry.key.contains('wrist') ||
                entry.key.contains('ankle') ||
                entry.key.contains('knee') ||
                entry.key.contains('elbow'))
            ? 5.0
            : 3.5;

        // Outer glow
        final glowColor = isLeft
            ? const Color(0xFF00E5FF)
            : (isRight ? const Color(0xFF8C52FF) : const Color(0xFFFFD600));

        canvas.drawCircle(
          offset,
          jointRadius + 1.5,
          Paint()..color = glowColor.withValues(alpha: 0.6),
        );

        // Core joint node
        canvas.drawCircle(offset, jointRadius, jointFillPaint);
        canvas.drawCircle(offset, jointRadius, jointStrokePaint);
      }
    }

    // 3. Draw Angles if enabled
    if (showAngles && framePose!.angles.isNotEmpty) {
      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black.withValues(alpha: 0.7),
      );

      framePose!.angles.forEach((joint, angle) {
        final pt = getPixel(joint);
        if (pt != null) {
          final tp = TextPainter(
            text: TextSpan(
              text: ' ${angle.toStringAsFixed(0)}° ',
              style: textStyle,
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(pt.dx + 6, pt.dy - 6));
        }
      });
    }
  }

  @override
  bool shouldRepaint(covariant MediaPipeSkeletonPainter oldDelegate) {
    return oldDelegate.framePose != framePose ||
        oldDelegate.showSkeleton != showSkeleton ||
        oldDelegate.showJoints != showJoints ||
        oldDelegate.showAngles != showAngles ||
        oldDelegate.videoOriginalSize != videoOriginalSize;
  }
}
