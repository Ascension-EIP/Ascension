// @date 2026-11-21
// @file analysis_repository_impl.dart
// @brief Repository implementation for analysis and video upload.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/analysis/data/datasources/analysis_remote_data_source.dart';
import 'package:mobile/features/analysis/data/models/analysis_model.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';
import 'package:mobile/features/analysis/domain/repositories/analysis_repository.dart';

class AnalysisRepositoryImpl implements AnalysisRepository {
  AnalysisRepositoryImpl(this._remoteDataSource);

  final AnalysisRemoteDataSource _remoteDataSource;

  @override
  Future<Result<VideoUploadUrlModel>> requestUploadUrl({
    required String contentType,
    required int size,
    String? climbingSessionId,
    String? title,
    required String visibility,
  }) {
    return _remoteDataSource.requestUploadUrl(
      contentType: contentType,
      size: size,
      climbingSessionId: climbingSessionId,
      title: title,
      visibility: visibility,
    );
  }

  @override
  Future<Result<void>> uploadVideoToS3({
    required String uploadUrl,
    required File videoFile,
    required String contentType,
    void Function(double progress)? onProgress,
  }) {
    return _remoteDataSource.uploadVideoToS3(
      uploadUrl: uploadUrl,
      videoFile: videoFile,
      contentType: contentType,
      onProgress: (sent, total) {
        if (total > 0 && onProgress != null) {
          onProgress(sent / total);
        }
      },
    );
  }

  @override
  Future<Result<void>> notifyUploadDone(String videoId) {
    return _remoteDataSource.notifyUploadDone(videoId);
  }

  @override
  Future<Result<AnalysisResponseModel>> triggerAnalysis({
    required String videoId,
    required String type,
    required String visibility,
  }) {
    return _remoteDataSource.triggerAnalysis(
      videoId: videoId,
      type: type,
      visibility: visibility,
    );
  }

  @override
  Future<Result<AnalysisResponseModel>> getAnalysis(String analysisId) {
    return _remoteDataSource.getAnalysis(analysisId);
  }

  @override
  Future<Result<AnalysisAdvice?>> getAdvice(String videoId) async {
    final result = await _remoteDataSource.getAdvice(videoId);
    return result.map((model) => model.advice);
  }

  @override
  Future<Result<String>> getVideoDownloadUrl(String videoId) {
    return _remoteDataSource.getVideoDownloadUrl(videoId);
  }
}

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  final remoteDataSource = ref.watch(analysisRemoteDataSourceProvider);
  return AnalysisRepositoryImpl(remoteDataSource);
});
