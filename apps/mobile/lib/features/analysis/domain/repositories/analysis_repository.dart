// @date 2026-11-21
// @file analysis_repository.dart
// @brief Domain contract for pose analysis operations.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:io';

import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/analysis/data/models/analysis_model.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';

abstract class AnalysisRepository {
  Future<Result<VideoUploadUrlModel>> requestUploadUrl({
    required String contentType,
    required int size,
    String? climbingSessionId,
    String? title,
    required String visibility,
  });

  Future<Result<void>> uploadVideoToS3({
    required String uploadUrl,
    required File videoFile,
    required String contentType,
    void Function(double progress)? onProgress,
  });

  Future<Result<void>> notifyUploadDone(String videoId);

  Future<Result<AnalysisResponseModel>> triggerAnalysis({
    required String videoId,
    required String type,
    required String visibility,
  });

  Future<Result<AnalysisResponseModel>> getAnalysis(String analysisId);

  Future<Result<AnalysisAdvice?>> getAdvice(String videoId);

  Future<Result<String>> getVideoDownloadUrl(String videoId);
}
