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

enum AnalysisProcessingStage {
  /// Step 1: Requesting URL, uploading video to S3, and triggering pose analysis (0% -> 25%)
  uploading,

  /// Step 2: MediaPipe frame-by-frame skeleton extraction (25% -> 75%)
  detectingPose,

  /// Step 3: Biomechanical metrics & movement computation (75% -> 85%)
  computingMetrics,

  /// Step 4: Triggering & polling AI coaching advice generation (85% -> 99%)
  generatingAdvice,

  /// Finalization micro-animation before transitioning to results (100%)
  finishing,
}

class PoseAnalysisState extends Equatable {
  const PoseAnalysisState({
    this.flowStep = PoseAnalysisFlowStep.selection,
    this.processingStage = AnalysisProcessingStage.uploading,
    this.selectedVideoFile,
    this.videoDuration,
    this.videoSizeBytes,
    this.uploadProgress = 0.0,
    this.analysisProgress = 0,
    this.adviceProgress = 0,
    this.uploadSpeedBytesPerSec,
    this.estimatedRemainingSeconds,
    this.currentProcessingStep = '',
    this.analysisResult,
    this.videoId,
    this.analysisId,
    this.errorMessage,
  });

  final PoseAnalysisFlowStep flowStep;
  final AnalysisProcessingStage processingStage;
  final File? selectedVideoFile;
  final Duration? videoDuration;
  final int? videoSizeBytes;
  final double uploadProgress;
  final int analysisProgress;
  final int adviceProgress;
  final double? uploadSpeedBytesPerSec;
  final int? estimatedRemainingSeconds;
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
    AnalysisProcessingStage? processingStage,
    File? selectedVideoFile,
    Duration? videoDuration,
    int? videoSizeBytes,
    double? uploadProgress,
    int? analysisProgress,
    int? adviceProgress,
    double? uploadSpeedBytesPerSec,
    int? estimatedRemainingSeconds,
    String? currentProcessingStep,
    PoseAnalysisResult? analysisResult,
    String? videoId,
    String? analysisId,
    String? errorMessage,
    bool clearError = false,
    bool clearUploadSpeed = false,
    bool clearEta = false,
  }) {
    return PoseAnalysisState(
      flowStep: flowStep ?? this.flowStep,
      processingStage: processingStage ?? this.processingStage,
      selectedVideoFile: selectedVideoFile ?? this.selectedVideoFile,
      videoDuration: videoDuration ?? this.videoDuration,
      videoSizeBytes: videoSizeBytes ?? this.videoSizeBytes,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      analysisProgress: analysisProgress ?? this.analysisProgress,
      adviceProgress: adviceProgress ?? this.adviceProgress,
      uploadSpeedBytesPerSec: clearUploadSpeed
          ? null
          : (uploadSpeedBytesPerSec ?? this.uploadSpeedBytesPerSec),
      estimatedRemainingSeconds: clearEta
          ? null
          : (estimatedRemainingSeconds ?? this.estimatedRemainingSeconds),
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
    processingStage,
    selectedVideoFile,
    videoDuration,
    videoSizeBytes,
    uploadProgress,
    analysisProgress,
    adviceProgress,
    uploadSpeedBytesPerSec,
    estimatedRemainingSeconds,
    currentProcessingStep,
    analysisResult,
    videoId,
    analysisId,
    errorMessage,
  ];
}
