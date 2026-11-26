// @date 2026-11-21
// @file analysis_results_view.dart
// @brief Screen presenting complete analysis results across 3 tabs (Video, Advice, Statistics).
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';
import 'package:mobile/features/analysis/presentation/widgets/analysis_advice_tab.dart';
import 'package:mobile/features/analysis/presentation/widgets/analysis_statistics_tab.dart';
import 'package:mobile/features/analysis/presentation/widgets/video_skeleton_tab.dart';

class AnalysisResultsView extends StatelessWidget {
  const AnalysisResultsView({
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
    return SafeArea(
      child: FTabs(
        expands: true,
        children: [
          FTabEntry(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FLucideIcons.video, size: 14),
                const SizedBox(width: 6),
                Text(context.tr('analysis.tabVideo')),
              ],
            ),
            child: VideoSkeletonTab(
              videoFile: videoFile,
              videoUrl: videoUrl,
              analysisResult: analysisResult,
            ),
          ),
          FTabEntry(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FLucideIcons.sparkles, size: 14),
                const SizedBox(width: 6),
                Text(context.tr('analysis.tabAdvice')),
              ],
            ),
            child: AnalysisAdviceTab(advice: analysisResult.advice),
          ),
          FTabEntry(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FLucideIcons.barChart3, size: 14),
                const SizedBox(width: 6),
                Text(context.tr('analysis.tabStats')),
              ],
            ),
            child: AnalysisStatisticsTab(analysisResult: analysisResult),
          ),
        ],
      ),
    );
  }
}
