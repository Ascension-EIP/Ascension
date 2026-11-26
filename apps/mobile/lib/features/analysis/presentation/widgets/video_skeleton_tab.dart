// @date 2026-11-21
// @file video_skeleton_tab.dart
// @brief Tab displaying video playback with synchronized MediaPipe skeleton edge rendering.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';
import 'package:mobile/features/analysis/presentation/widgets/video_analysis_player.dart';

class VideoSkeletonTab extends StatelessWidget {
  const VideoSkeletonTab({
    super.key,
    this.videoFile,
    this.videoUrl,
    required this.analysisResult,
  });

  final File? videoFile;
  final String? videoUrl;
  final PoseAnalysisResult analysisResult;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Video Player with MediaPipe Overlay
          VideoAnalysisPlayer(
            videoFile: videoFile,
            videoUrl: videoUrl,
            analysisResult: analysisResult,
          ),

          const SizedBox(height: 16),

          // Overview Quick Stats Card
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FLucideIcons.sparkles,
                        size: 18,
                        color: context.theme.colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rendu biomécanique local',
                        style: context.theme.typography.body.md.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      FBadge(
                        variant: FBadgeVariant.secondary,
                        child: Text(
                          '${analysisResult.fps.toStringAsFixed(0)} FPS',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Le squelette 2D est calculé à partir des 33 points d\'articulation MediaPipe Pose. Vous pouvez ralentir la vidéo à 0.5x ou masquer le tracé via les boutons de contrôle ci-dessus.',
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        context,
                        label: 'Résolution',
                        value:
                            '${analysisResult.width} × ${analysisResult.height}',
                      ),
                      _buildInfoItem(
                        context,
                        label: 'Images analysées',
                        value: '${analysisResult.frames.length}',
                      ),
                      _buildInfoItem(
                        context,
                        label: 'Détection globale',
                        value:
                            '${((analysisResult.metrics?.poseDetectionRate ?? 1.0) * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: context.theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
