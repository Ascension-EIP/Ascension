// @date 2026-11-21
// @file analysis_remote_data_source.dart
// @brief Remote data source for uploading videos to S3 and interacting with analysis API.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/analysis/data/models/analysis_model.dart';

abstract class AnalysisRemoteDataSource {
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
    void Function(int sent, int total)? onProgress,
  });

  Future<Result<void>> notifyUploadDone(String videoId);

  Future<Result<AnalysisResponseModel>> triggerAnalysis({
    required String videoId,
    required String type,
    required String visibility,
  });

  Future<Result<AnalysisResponseModel>> getAnalysis(String analysisId);

  Future<Result<AdviceResponseModel>> triggerAdvice(String videoId);

  Future<Result<AdviceResponseModel>> getAdvice(String videoId);

  Future<Result<String>> getVideoDownloadUrl(String videoId);
}

class AnalysisRemoteDataSourceImpl implements AnalysisRemoteDataSource {
  AnalysisRemoteDataSourceImpl(this._apiClient, this._rawDio);

  final ApiClient _apiClient;
  final Dio _rawDio;

  @override
  Future<Result<VideoUploadUrlModel>> requestUploadUrl({
    required String contentType,
    required int size,
    String? climbingSessionId,
    String? title,
    required String visibility,
  }) async {
    final payload = <String, dynamic>{
      'content_type': contentType,
      'size': size,
      'visibility': visibility,
      'retained': false,
    };
    if (climbingSessionId != null && climbingSessionId.isNotEmpty) {
      payload['climbing_session_id'] = climbingSessionId;
    }
    if (title != null && title.isNotEmpty) {
      payload['title'] = title;
    }

    final result = await _apiClient.post<dynamic>(
      ApiEndpoints.requestUploadUrl,
      data: payload,
    );

    return result.map((data) {
      if (data is Map<String, dynamic>) {
        return VideoUploadUrlModel.fromJson(data);
      }
      throw const FormatException('Invalid upload URL response');
    });
  }

  @override
  Future<Result<void>> uploadVideoToS3({
    required String uploadUrl,
    required File videoFile,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final fileLength = await videoFile.length();
      final stream = videoFile.openRead();

      final response = await _rawDio.put<dynamic>(
        uploadUrl,
        data: stream,
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileLength,
            Headers.contentTypeHeader: contentType,
          },
        ),
        onSendProgress: onProgress,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return const Success(null);
      }

      return Error(
        ServerFailure(
          'Failed to upload video to S3: status ${response.statusCode}',
        ),
      );
    } on DioException catch (e) {
      return Error(
        ServerFailure('S3 upload network error: ${e.message ?? e.toString()}'),
      );
    } catch (e) {
      return Error(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> notifyUploadDone(String videoId) async {
    final result = await _apiClient.put<dynamic>(
      ApiEndpoints.uploadCompleteWithId(videoId),
    );

    return result.map((_) {});
  }

  @override
  Future<Result<AnalysisResponseModel>> triggerAnalysis({
    required String videoId,
    required String type,
    required String visibility,
  }) async {
    final result = await _apiClient.post<dynamic>(
      ApiEndpoints.analyses,
      data: {'video_id': videoId, 'type': type, 'visibility': visibility},
    );

    return result.map((data) {
      if (data is Map<String, dynamic>) {
        return AnalysisResponseModel.fromJson(data);
      }
      throw const FormatException('Invalid analysis response');
    });
  }

  @override
  Future<Result<AnalysisResponseModel>> getAnalysis(String analysisId) async {
    final result = await _apiClient.get<dynamic>(
      ApiEndpoints.analysisDetails(analysisId),
    );

    return result.map((data) {
      if (data is Map<String, dynamic>) {
        return AnalysisResponseModel.fromJson(data);
      }
      throw const FormatException('Invalid analysis details response');
    });
  }

  @override
  Future<Result<AdviceResponseModel>> triggerAdvice(String videoId) async {
    final result = await _apiClient.post<dynamic>(
      ApiEndpoints.adviceDetails(videoId),
    );

    return result.map((data) {
      if (data is Map<String, dynamic>) {
        return AdviceResponseModel.fromJson(data);
      }
      throw const FormatException('Invalid advice trigger response');
    });
  }

  @override
  Future<Result<AdviceResponseModel>> getAdvice(String videoId) async {
    final result = await _apiClient.get<dynamic>(
      ApiEndpoints.adviceDetails(videoId),
    );

    return result.map((data) {
      if (data is Map<String, dynamic>) {
        return AdviceResponseModel.fromJson(data);
      }
      throw const FormatException('Invalid advice response');
    });
  }

  @override
  Future<Result<String>> getVideoDownloadUrl(String videoId) async {
    final result = await _apiClient.get<dynamic>(
      ApiEndpoints.videoDownloadUrl(videoId),
    );

    return result.map((data) {
      if (data is Map<String, dynamic> && data['download_url'] != null) {
        return data['download_url'] as String;
      }
      throw const FormatException('Invalid download URL response');
    });
  }
}

/// Provider for raw Dio without app auth interceptors (for S3 uploads).
final s3DioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );
});

/// Provider for [AnalysisRemoteDataSource].
final analysisRemoteDataSourceProvider = Provider<AnalysisRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  final s3Dio = ref.watch(s3DioProvider);
  return AnalysisRemoteDataSourceImpl(apiClient, s3Dio);
});
