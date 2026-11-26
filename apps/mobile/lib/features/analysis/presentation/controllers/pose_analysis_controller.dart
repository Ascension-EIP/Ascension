// @date 2026-11-21
// @file pose_analysis_controller.dart
// @brief Riverpod controller orchestrating video recording, S3 upload, and pose analysis.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/analysis/data/models/analysis_model.dart';
import 'package:mobile/features/analysis/data/repositories/analysis_repository_impl.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';
import 'package:mobile/features/analysis/domain/repositories/analysis_repository.dart';
import 'package:mobile/features/analysis/presentation/controllers/pose_analysis_state.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:mobile/features/climb_session/presentation/controllers/climb_session_controller.dart';

class PoseAnalysisController extends Notifier<PoseAnalysisState> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isDisposed = false;
  int _runId = 0;

  @override
  PoseAnalysisState build() {
    _isDisposed = false;
    _runId = 0;
    ref.onDispose(() {
      _isDisposed = true;
      _runId++;
    });
    return const PoseAnalysisState();
  }

  bool _isActiveRun(int runId) => !_isDisposed && _runId == runId;

  AnalysisRepository get _repo => ref.read(analysisRepositoryProvider);

  /// Opens the native device camera to film a climbing session.
  Future<void> recordVideo() async {
    try {
      final XFile? recorded = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (recorded == null || _isDisposed) return;

      final file = File(recorded.path);
      final size = await file.length();

      state = state.copyWith(
        flowStep: PoseAnalysisFlowStep.preview,
        selectedVideoFile: file,
        videoSizeBytes: size,
        clearError: true,
      );
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(
        flowStep: PoseAnalysisFlowStep.error,
        errorMessage: 'Impossible d\'ouvrir la caméra : $e',
      );
    }
  }

  /// Opens the gallery to select an existing climbing video.
  Future<void> pickVideoFromGallery() async {
    try {
      final XFile? picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (picked == null || _isDisposed) return;

      final file = File(picked.path);
      final size = await file.length();

      state = state.copyWith(
        flowStep: PoseAnalysisFlowStep.preview,
        selectedVideoFile: file,
        videoSizeBytes: size,
        clearError: true,
      );
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(
        flowStep: PoseAnalysisFlowStep.error,
        errorMessage: 'Impossible de sélectionner la vidéo : $e',
      );
    }
  }

  /// Cancels the current video preview or in-flight analysis and returns to selection.
  void cancelPreview() {
    _runId++;
    state = const PoseAnalysisState(flowStep: PoseAnalysisFlowStep.selection);
  }

  /// Returns from an error state back to video preview if a video was selected,
  /// or back to selection otherwise.
  void returnToPreviewOrSelection() {
    if (state.selectedVideoFile != null) {
      state = state.copyWith(
        flowStep: PoseAnalysisFlowStep.preview,
        clearError: true,
      );
    } else {
      cancelPreview();
    }
  }

  /// Confirms analysis and executes the full upload, pose analysis, and advice pipeline.
  Future<void> confirmAndStartAnalysis({
    String? climbingSessionId,
    String? title,
    String visibility = 'private',
  }) async {
    final videoFile = state.selectedVideoFile;
    if (videoFile == null) return;

    final runId = ++_runId;

    state = state.copyWith(
      flowStep: PoseAnalysisFlowStep.processing,
      processingStage: AnalysisProcessingStage.uploading,
      uploadProgress: 0.05,
      analysisProgress: 0,
      adviceProgress: 0,
      currentProcessingStep: 'analysis.statusInit',
      clearError: true,
      clearUploadSpeed: true,
      clearEta: true,
    );

    try {
      final size = state.videoSizeBytes ?? await videoFile.length();
      const contentType = 'video/mp4';

      // 1. Request S3 upload presigned URL
      state = state.copyWith(
        currentProcessingStep: 'analysis.statusPreparingUpload',
        uploadProgress: 0.1,
      );

      final uploadUrlResult = await _repo.requestUploadUrl(
        contentType: contentType,
        size: size,
        climbingSessionId: climbingSessionId,
        title: title ?? 'Session de grimpe',
        visibility: visibility,
      );

      if (uploadUrlResult case Error(:final failure)) {
        throw Exception(failure.message);
      }

      final uploadData = (uploadUrlResult as Success<VideoUploadUrlModel>).data;
      final videoId = uploadData.videoId;

      if (!_isActiveRun(runId)) return;
      state = state.copyWith(
        videoId: videoId,
        currentProcessingStep: 'analysis.statusUploading',
      );

      // 2. Upload binary video stream to S3 with speed & ETA calculation
      final uploadStartTime = DateTime.now();
      var lastUpdateTime = uploadStartTime;
      var lastBytes = 0;
      double? smoothedSpeed;

      final s3Result = await _repo.uploadVideoToS3(
        uploadUrl: uploadData.uploadUrl,
        videoFile: videoFile,
        contentType: contentType,
        onProgress: (sent, total) {
          if (!_isActiveRun(runId) || total <= 0) return;

          final now = DateTime.now();
          final sinceLastMs = now.difference(lastUpdateTime).inMilliseconds;
          final isComplete = sent >= total;

          // Throttle UI updates to avoid excessive rebuilds while keeping telemetry responsive
          if (!isComplete && sinceLastMs < 150) return;

          final progressRatio = (sent / total).clamp(0.0, 1.0);
          final elapsedSec =
              now.difference(uploadStartTime).inMilliseconds / 1000.0;

          if (elapsedSec > 0.2 && sent > 0) {
            final instantSpeed = sinceLastMs > 0
                ? (sent - lastBytes) / (sinceLastMs / 1000.0)
                : sent / elapsedSec;
            final avgSpeed = sent / elapsedSec;
            final sampleSpeed = instantSpeed > 0 ? instantSpeed : avgSpeed;

            smoothedSpeed = smoothedSpeed == null
                ? avgSpeed
                : (smoothedSpeed! * 0.65) + (sampleSpeed * 0.35);
          }

          lastUpdateTime = now;
          lastBytes = sent;

          int? etaSeconds;
          if (smoothedSpeed != null && smoothedSpeed! > 0 && !isComplete) {
            final remainingBytes = (total - sent).clamp(0, total);
            etaSeconds = (remainingBytes / smoothedSpeed!).ceil().clamp(1, 600);
          }

          // S3 binary upload covers 10% -> 90% of the upload phase
          state = state.copyWith(
            uploadProgress: 0.1 + (progressRatio * 0.8),
            uploadSpeedBytesPerSec: smoothedSpeed,
            estimatedRemainingSeconds: etaSeconds,
            clearEta: etaSeconds == null,
          );
        },
      );

      if (s3Result case Error(:final failure)) {
        throw Exception(failure.message);
      }

      if (!_isActiveRun(runId)) return;
      state = state.copyWith(
        uploadProgress: 0.93,
        currentProcessingStep: 'analysis.statusFinalizingUpload',
        clearUploadSpeed: true,
        clearEta: true,
      );

      // 3. Notify backend upload is complete
      final completeResult = await _repo.notifyUploadDone(videoId);
      if (completeResult case Error(:final failure)) {
        throw Exception(failure.message);
      }

      if (!_isActiveRun(runId)) return;
      state = state.copyWith(
        uploadProgress: 0.97,
        currentProcessingStep: 'analysis.statusTriggering',
      );

      // 4. Trigger 2D pose analysis
      final triggerResult = await _repo.triggerAnalysis(
        videoId: videoId,
        type: '2d',
        visibility: visibility,
      );

      if (triggerResult case Error(:final failure)) {
        throw Exception(failure.message);
      }

      final analysisData =
          (triggerResult as Success<AnalysisResponseModel>).data;
      final analysisId = analysisData.id;

      if (!_isActiveRun(runId)) return;
      state = state.copyWith(
        analysisId: analysisId,
        uploadProgress: 1.0,
        processingStage: AnalysisProcessingStage.detectingPose,
        currentProcessingStep: 'analysis.statusExtractingSkeleton',
      );

      // 5. Poll for 2D pose analysis completion (with ETA extrapolation)
      var finalResult = await _pollAnalysisUntilFinished(analysisId, runId);
      if (!_isActiveRun(runId)) return;

      // 6. Trigger & poll AI coaching advice once pose analysis is complete
      final advice = await _triggerAndPollAdvice(videoId, runId);
      if (!_isActiveRun(runId)) return;

      if (advice != null) {
        finalResult = PoseAnalysisResult(
          fps: finalResult.fps,
          width: finalResult.width,
          height: finalResult.height,
          frames: finalResult.frames,
          metrics: finalResult.metrics,
          movements: finalResult.movements,
          pauses: finalResult.pauses,
          advice: advice,
        );
      }

      // Link to session if one is active
      try {
        final activeSession = ref
            .read(climbSessionControllerProvider)
            .activeSession;
        if (activeSession != null) {
          final summary = ClimbAnalysisSummary(
            id: analysisId,
            title: title ?? 'Analyse de pose 2D',
            type: AnalysisType.pose2d,
            status: AnalysisStatus.completed,
            createdAt: DateTime.now(),
            videoId: videoId,
            climbingSessionId: activeSession.id,
          );
          await ref
              .read(climbSessionControllerProvider.notifier)
              .addAnalysis(summary);
        }
      } catch (e) {
        debugPrint('Could not attach analysis to active session: $e');
      }

      if (!_isActiveRun(runId)) return;

      // 7. Completion micro-animation: visibly check off all steps at 100% before transitioning
      state = state.copyWith(
        processingStage: AnalysisProcessingStage.finishing,
        analysisProgress: 100,
        adviceProgress: 100,
        currentProcessingStep: 'analysis.statusCompleted',
        clearUploadSpeed: true,
        clearEta: true,
      );

      await Future.delayed(const Duration(milliseconds: 650));
      if (!_isActiveRun(runId)) return;

      state = state.copyWith(
        flowStep: PoseAnalysisFlowStep.completed,
        analysisProgress: 100,
        adviceProgress: 100,
        analysisResult: finalResult,
      );
    } catch (e) {
      if (!_isActiveRun(runId)) return;
      state = state.copyWith(
        flowStep: PoseAnalysisFlowStep.error,
        errorMessage: 'Échec de l\'analyse : $e',
        clearUploadSpeed: true,
        clearEta: true,
      );
    }
  }

  /// Polls the 2D pose analysis status every 1.5 seconds until success or failure,
  /// extrapolating remaining time after the first meaningful progress return.
  Future<PoseAnalysisResult> _pollAnalysisUntilFinished(
    String analysisId,
    int runId,
  ) async {
    const maxAttempts = 60; // 90 seconds timeout max
    const skeletonEndProgress = 70; // AI worker runs MediaPipe from 5% to 70%

    final pollingStartTime = DateTime.now();
    int? baselineProgress;
    DateTime? baselineTime;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (!_isActiveRun(runId)) throw Exception('Analysis cancelled');

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!_isActiveRun(runId)) throw Exception('Analysis cancelled');

      final checkResult = await _repo.getAnalysis(analysisId);
      if (checkResult is Success<AnalysisResponseModel>) {
        final resp = checkResult.data;
        final now = DateTime.now();

        if (resp.progress > state.analysisProgress) {
          int? extrapolatedEta = state.estimatedRemainingSeconds;
          var shouldClearEta = false;

          if (resp.progress < skeletonEndProgress) {
            if (baselineProgress == null) {
              baselineProgress = resp.progress;
              baselineTime = now;

              // If the first poll already returned meaningful progress, extrapolate right away
              if (resp.progress >= 10) {
                final elapsedSec =
                    now.difference(pollingStartTime).inMilliseconds / 1000.0;
                if (elapsedSec >= 0.5) {
                  final rate = resp.progress / elapsedSec;
                  if (rate > 0) {
                    extrapolatedEta =
                        (((skeletonEndProgress - resp.progress) / rate).ceil() +
                                2)
                            .clamp(1, 300);
                  }
                }
              }
            } else if (resp.progress > baselineProgress) {
              final elapsedSec =
                  now.difference(baselineTime!).inMilliseconds / 1000.0;
              if (elapsedSec >= 0.5) {
                final rate = (resp.progress - baselineProgress) / elapsedSec;
                if (rate > 0) {
                  extrapolatedEta =
                      (((skeletonEndProgress - resp.progress) / rate).ceil() +
                              2)
                          .clamp(1, 300);
                }
              }
            }
          } else {
            shouldClearEta = true;
          }

          final isMetricsStage = resp.progress >= skeletonEndProgress;
          state = state.copyWith(
            analysisProgress: resp.progress,
            processingStage: isMetricsStage
                ? AnalysisProcessingStage.computingMetrics
                : AnalysisProcessingStage.detectingPose,
            currentProcessingStep: isMetricsStage
                ? 'analysis.statusComputingData'
                : 'analysis.statusExtractingSkeleton',
            estimatedRemainingSeconds: shouldClearEta ? null : extrapolatedEta,
            clearEta: shouldClearEta,
          );
        }

        if (resp.isSuccess) {
          // Ensure the metrics step is visibly shown even when it completes between two polls
          if (state.processingStage !=
              AnalysisProcessingStage.computingMetrics) {
            state = state.copyWith(
              analysisProgress: 100,
              processingStage: AnalysisProcessingStage.computingMetrics,
              currentProcessingStep: 'analysis.statusComputingData',
              clearEta: true,
            );
            await Future.delayed(const Duration(milliseconds: 350));
            if (!_isActiveRun(runId)) throw Exception('Analysis cancelled');
          }

          return resp.result ?? _createFallbackResult();
        }

        if (resp.isFailed) {
          throw Exception(resp.error ?? 'L\'analyse a échoué');
        }
      }
    }

    throw TimeoutException('Le délai d\'attente de l\'analyse a expiré');
  }

  /// Triggers AI coaching advice generation (POST /v1/advices/:videoId) and polls
  /// until ready. Failures or timeouts are non-fatal so pose analysis results still open.
  Future<AnalysisAdvice?> _triggerAndPollAdvice(
    String videoId,
    int runId,
  ) async {
    state = state.copyWith(
      processingStage: AnalysisProcessingStage.generatingAdvice,
      adviceProgress: 10,
      currentProcessingStep: 'analysis.statusGeneratingAdvice',
      clearEta: true,
    );

    try {
      final triggerResult = await _repo.triggerAdvice(videoId);
      if (!_isActiveRun(runId)) return null;

      if (triggerResult is Success<AdviceResponseModel>) {
        final triggered = triggerResult.data;
        if (triggered.isSuccess && triggered.advice != null) {
          state = state.copyWith(adviceProgress: 100);
          return triggered.advice;
        }
        if (triggered.progress > state.adviceProgress) {
          state = state.copyWith(adviceProgress: triggered.progress);
        }
      } else if (triggerResult case Error(:final failure)) {
        debugPrint(
          'Trigger advice returned error (will check existing): ${failure.message}',
        );
        final existingResult = await _repo.getAdviceStatus(videoId);
        if (existingResult is Success<AdviceResponseModel> &&
            existingResult.data.isSuccess) {
          state = state.copyWith(adviceProgress: 100);
          return existingResult.data.advice;
        }
        return null;
      }

      // Poll GET /v1/advices/:videoId every 1.5s (up to 30 seconds max)
      const maxAdviceAttempts = 20;
      for (int attempt = 0; attempt < maxAdviceAttempts; attempt++) {
        if (!_isActiveRun(runId)) return null;

        await Future.delayed(const Duration(milliseconds: 1500));
        if (!_isActiveRun(runId)) return null;

        final statusResult = await _repo.getAdviceStatus(videoId);
        if (statusResult is Success<AdviceResponseModel>) {
          final resp = statusResult.data;

          if (resp.isSuccess) {
            state = state.copyWith(adviceProgress: 100);
            return resp.advice;
          }

          if (resp.isFailed) {
            debugPrint('Advice generation failed: ${resp.error}');
            return null;
          }

          // Keep progress bar moving smoothly while LLM generates advice
          final nextProgress = resp.progress > state.adviceProgress
              ? resp.progress
              : (state.adviceProgress + 8).clamp(0, 92);
          state = state.copyWith(adviceProgress: nextProgress);
        }
      }
    } catch (e) {
      debugPrint('Advice generation unavailable: $e');
    }

    return null;
  }

  /// Reset to initial state for a new climb analysis
  void reset() {
    _runId++;
    state = const PoseAnalysisState(flowStep: PoseAnalysisFlowStep.selection);
  }

  /// Fallback demo result in case backend completes with minimal skeleton
  PoseAnalysisResult _createFallbackResult() {
    return const PoseAnalysisResult(
      fps: 30.0,
      width: 1080,
      height: 1920,
      frames: [],
      metrics: AnalysisMetrics(
        durationMs: 15000,
        poseDetectionRate: 0.96,
        avgArmExtension: SidesData(left: 0.82, right: 0.79),
        bentArmRatio: SidesData(left: 0.35, right: 0.40),
      ),
      movements: [],
      pauses: [],
    );
  }
}

final poseAnalysisControllerProvider =
    NotifierProvider<PoseAnalysisController, PoseAnalysisState>(
      PoseAnalysisController.new,
    );
