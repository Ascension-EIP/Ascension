// @date 2026-11-21
// @file pose_analysis_state.dart
// @brief State definitions for the pose analysis and recording workflow.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';

enum PoseAnalysisFlowStep {
  /// Initial step: user chooses between filming or picking a video from gallery
  selection,

  /// User previews the captured video and confirms whether to analyze it
  preview,

  /// Video is being uploaded to S3 and processed by the AI worker
  processing,

  /// Analysis completed; user can view the 3 tabs (Video, Advice, Statistics)
  completed,

  /// Failure occurred during upload or analysis
  error,
}

class PoseAnalysisState extends Equatable {
  const PoseAnalysisState({
    this.flowStep = PoseAnalysisFlowStep.selection,
    this.selectedVideoFile,
    this.videoDuration,
    this.videoSizeBytes,
    this.uploadProgress = 0.0,
    this.analysisProgress = 0,
    this.currentProcessingStep = '',
    this.analysisResult,
    this.videoId,
    this.analysisId,
    this.errorMessage,
  });

  final PoseAnalysisFlowStep flowStep;
  final File? selectedVideoFile;
  final Duration? videoDuration;
  final int? videoSizeBytes;
  final double uploadProgress;
  final int analysisProgress;
  final String currentProcessingStep;
  final PoseAnalysisResult? analysisResult;
  final String? videoId;
  final String? analysisId;
  final String? errorMessage;

  bool get isSelection => flowStep == PoseAnalysisFlowStep.selection;
  bool get isPreview => flowStep == PoseAnalysisFlowStep.preview;
  bool get isProcessing => flowStep == PoseAnalysisFlowStep.processing;
  bool get isCompleted => flowStep == PoseAnalysisFlowStep.completed;
  bool get isError => flowStep == PoseAnalysisFlowStep.error;

  PoseAnalysisState copyWith({
    PoseAnalysisFlowStep? flowStep,
    File? selectedVideoFile,
    Duration? videoDuration,
    int? videoSizeBytes,
    double? uploadProgress,
    int? analysisProgress,
    String? currentProcessingStep,
    PoseAnalysisResult? analysisResult,
    String? videoId,
    String? analysisId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PoseAnalysisState(
      flowStep: flowStep ?? this.flowStep,
      selectedVideoFile: selectedVideoFile ?? this.selectedVideoFile,
      videoDuration: videoDuration ?? this.videoDuration,
      videoSizeBytes: videoSizeBytes ?? this.videoSizeBytes,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      analysisProgress: analysisProgress ?? this.analysisProgress,
      currentProcessingStep:
          currentProcessingStep ?? this.currentProcessingStep,
      analysisResult: analysisResult ?? this.analysisResult,
      videoId: videoId ?? this.videoId,
      analysisId: analysisId ?? this.analysisId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    flowStep,
    selectedVideoFile,
    videoDuration,
    videoSizeBytes,
    uploadProgress,
    analysisProgress,
    currentProcessingStep,
    analysisResult,
    videoId,
    analysisId,
    errorMessage,
  ];
}
