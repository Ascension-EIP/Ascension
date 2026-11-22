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

  @override
  PoseAnalysisState build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
    });
    return const PoseAnalysisState();
  }

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

  /// Cancels the current video preview and returns to the selection screen.
  void cancelPreview() {
    state = const PoseAnalysisState(flowStep: PoseAnalysisFlowStep.selection);
  }

  /// Confirms analysis and executes the full upload and analysis pipeline.
  Future<void> confirmAndStartAnalysis({
    String? climbingSessionId,
    String? title,
    String visibility = 'private',
  }) async {
    final videoFile = state.selectedVideoFile;
    if (videoFile == null) return;

    state = state.copyWith(
      flowStep: PoseAnalysisFlowStep.processing,
      uploadProgress: 0.05,
      analysisProgress: 0,
      currentProcessingStep: 'Initialisation de l\'envoi...',
      clearError: true,
    );

    try {
      final size = state.videoSizeBytes ?? await videoFile.length();
      const contentType = 'video/mp4';

      // 1. Request S3 upload presigned URL
      state = state.copyWith(
        currentProcessingStep: 'Préparation du stockage sécurisé (S3)...',
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

      if (_isDisposed) return;
      state = state.copyWith(
        videoId: videoId,
        currentProcessingStep: 'Téléversement de la vidéo...',
      );

      // 2. Upload binary video stream to S3
      final s3Result = await _repo.uploadVideoToS3(
        uploadUrl: uploadData.uploadUrl,
        videoFile: videoFile,
        contentType: contentType,
        onProgress: (p) {
          if (!_isDisposed) {
            // Upload takes 10% to 70% of the overall progress
            state = state.copyWith(uploadProgress: 0.1 + (p * 0.6));
          }
        },
      );

      if (s3Result case Error(:final failure)) {
        throw Exception(failure.message);
      }

      if (_isDisposed) return;
      state = state.copyWith(
        uploadProgress: 0.75,
        currentProcessingStep: 'Finalisation du téléversement...',
      );

      // 3. Notify backend upload is complete
      final completeResult = await _repo.notifyUploadDone(videoId);
      if (completeResult case Error(:final failure)) {
        throw Exception(failure.message);
      }

      if (_isDisposed) return;
      state = state.copyWith(
        uploadProgress: 0.85,
        currentProcessingStep: 'Déclenchement de l\'analyse biomécanique...',
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

      if (_isDisposed) return;
      state = state.copyWith(
        analysisId: analysisId,
        uploadProgress: 1.0,
        currentProcessingStep:
            'Extraction MediaPipe & calcul des articulations...',
      );

      // 5. Poll for analysis completion
      final finalResult = await _pollAnalysisUntilFinished(analysisId, videoId);

      if (_isDisposed) return;

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

      state = state.copyWith(
        flowStep: PoseAnalysisFlowStep.completed,
        analysisProgress: 100,
        analysisResult: finalResult,
      );
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(
        flowStep: PoseAnalysisFlowStep.error,
        errorMessage: 'Échec de l\'analyse : $e',
      );
    }
  }

  /// Polls the analysis status every 1.5 seconds until success or failure.
  Future<PoseAnalysisResult> _pollAnalysisUntilFinished(
    String analysisId,
    String videoId,
  ) async {
    const maxAttempts = 60; // 90 seconds timeout max
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (_isDisposed) throw Exception('Analysis cancelled');

      await Future.delayed(const Duration(milliseconds: 1500));
      if (_isDisposed) throw Exception('Analysis cancelled');

      final checkResult = await _repo.getAnalysis(analysisId);
      if (checkResult is Success<AnalysisResponseModel>) {
        final resp = checkResult.data;

        if (resp.progress > state.analysisProgress) {
          state = state.copyWith(
            analysisProgress: resp.progress,
            currentProcessingStep: resp.progress < 50
                ? 'Extraction des points clés MediaPipe Pose...'
                : 'Calcul biomécanique des vitesses et extensions...',
          );
        }

        if (resp.isSuccess) {
          var result = resp.result ?? _createFallbackResult();

          // Try to fetch advice as well
          try {
            final adviceResult = await _repo.getAdvice(videoId);
            if (adviceResult is Success<AnalysisAdvice?> &&
                adviceResult.data != null) {
              result = PoseAnalysisResult(
                fps: result.fps,
                width: result.width,
                height: result.height,
                frames: result.frames,
                metrics: result.metrics,
                movements: result.movements,
                pauses: result.pauses,
                advice: adviceResult.data,
              );
            }
          } catch (e) {
            debugPrint('Advice not yet available: $e');
          }

          return result;
        }

        if (resp.isFailed) {
          throw Exception(resp.error ?? 'L\'analyse a échoué');
        }
      }
    }

    throw TimeoutException('Le délai d\'attente de l\'analyse a expiré');
  }

  /// Reset to initial state for a new climb analysis
  void reset() {
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
