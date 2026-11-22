// @date 2026-11-21
// @file video_preview_view.dart
// @brief Video preview screen with confirmation prompt before sending to analysis.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/analysis/presentation/widgets/video_analysis_player.dart';

class VideoPreviewView extends StatelessWidget {
  const VideoPreviewView({
    super.key,
    required this.videoFile,
    this.videoSizeBytes,
    required this.onConfirm,
    required this.onCancel,
  });

  final File videoFile;
  final int? videoSizeBytes;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Constrain the video height so that video + slider + controls bar
        // end right above the bottom of the screen (the Android navigation bar).
        final maxVideoHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - 110).clamp(240.0, constraints.maxHeight)
            : 480.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Video preview player constrained in height
              VideoAnalysisPlayer(
                videoFile: videoFile,
                initialPlay: true,
                maxVideoHeight: maxVideoHeight,
              ),

              const SizedBox(height: 16),

              // Confirmation Prompt Card
              FCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.theme.colors.primary.withValues(
                                alpha: 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              FLucideIcons.sparkles,
                              size: 20,
                              color: context.theme.colors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.tr('analysis.confirmTitle'),
                              style: context.theme.typography.body.md.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('analysis.confirmPrompt'),
                        style: context.theme.typography.body.sm.copyWith(
                          color: context.theme.colors.foreground,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Confirm button
                      FButton(
                        onPress: onConfirm,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(FLucideIcons.uploadCloud, size: 18),
                            const SizedBox(width: 8),
                            Text(context.tr('analysis.confirmYes')),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Cancel / Re-record button
                      FButton(
                        variant: FButtonVariant.outline,
                        onPress: onCancel,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(FLucideIcons.rotateCcw, size: 16),
                            const SizedBox(width: 8),
                            Text(context.tr('analysis.confirmNo')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
