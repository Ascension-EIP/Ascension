// @date 2026-11-13
// @file climb_session_remote_data_source.dart
// @brief Remote data source performing real network calls to the Go climbing session API.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/climb_session/data/models/climb_session_model.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';

/// Contract for server-side climbing session endpoints (/v1/sessions).
abstract class ClimbSessionRemoteDataSource {
  /// Fetches the user's ongoing session (GET /v1/sessions/active).
  /// Returns null if status is 204 No Content (no active session).
  Future<Result<ClimbSessionModel?>> getActiveSession();

  /// Lists previous climbing sessions (GET /v1/sessions?limit=&offset=).
  Future<Result<List<ClimbSessionModel>>> getSessions({
    int limit = 50,
    int offset = 0,
  });

  /// Reads one climbing session with its analyses (GET /v1/sessions/:id).
  Future<Result<ClimbSessionModel>> getSessionDetails(String sessionId);

  /// Lists user's analyses (GET /v1/analysis?limit=&offset=).
  Future<Result<List<ClimbAnalysisSummaryModel>>> getAnalyses({
    int limit = 50,
    int offset = 0,
  });

  /// Starts a new climbing session (POST /v1/sessions).
  Future<Result<ClimbSessionModel>> createSession({
    required String name,
    String? location,
    String? notes,
    String? gymId,
    required ClimbSessionVisibility visibility,
    DateTime? startedAt,
  });

  /// Ends an ongoing climbing session (PUT /v1/sessions/:id with ended_at).
  Future<Result<ClimbSessionModel>> endSession(
    String sessionId, {
    DateTime? endedAt,
  });

  /// Updates session title, notes, or end time (PUT /v1/sessions/:id).
  Future<Result<ClimbSessionModel>> updateSession(
    String sessionId, {
    String? title,
    String? notes,
    DateTime? endedAt,
  });

  /// Links an existing analysis to a climbing session (POST /v1/sessions/:id/analyses).
  Future<Result<void>> addAnalysis(String sessionId, String analysisId);

  /// Deletes a climbing session (DELETE /v1/sessions/:id).
  Future<Result<void>> deleteSession(String sessionId);
}

/// Implementation of [ClimbSessionRemoteDataSource] using [ApiClient].
class ClimbSessionRemoteDataSourceImpl implements ClimbSessionRemoteDataSource {
  const ClimbSessionRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Result<ClimbSessionModel?>> getActiveSession() async {
    final result = await _apiClient.get<Map<String, dynamic>?>(
      ApiEndpoints.activeClimbSession,
    );

    return result.map((data) {
      if (data == null) return null;
      return ClimbSessionModel.fromJson(data);
    });
  }

  @override
  Future<Result<List<ClimbSessionModel>>> getSessions({
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.climbSessions,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return result.map(
      (data) => ClimbingSessionListResponseModel.fromJson(data).sessions,
    );
  }

  @override
  Future<Result<ClimbSessionModel>> getSessionDetails(String sessionId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.climbSessionDetails(sessionId),
    );

    return result.map((data) => ClimbSessionModel.fromJson(data));
  }

  @override
  Future<Result<List<ClimbAnalysisSummaryModel>>> getAnalyses({
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.analyses,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return result.map(
      (data) => AnalysisListResponseModel.fromJson(data).analyses,
    );
  }

  @override
  Future<Result<ClimbSessionModel>> createSession({
    required String name,
    String? location,
    String? notes,
    String? gymId,
    required ClimbSessionVisibility visibility,
    DateTime? startedAt,
  }) async {
    final payload = <String, dynamic>{
      'title': name,
      'visibility': visibility.name,
      'gym_id': ?gymId,
      if (notes != null || location != null) 'notes': notes ?? location,
      'started_at': ?startedAt?.toIso8601String(),
    };

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.climbSessions,
      data: payload,
    );

    return result.map((data) => ClimbSessionModel.fromJson(data));
  }

  @override
  Future<Result<ClimbSessionModel>> endSession(
    String sessionId, {
    DateTime? endedAt,
  }) async {
    final endTimestamp = (endedAt ?? DateTime.now()).toUtc().toIso8601String();
    final result = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.climbSessionDetails(sessionId),
      data: {'ended_at': endTimestamp},
    );

    return result.map((data) => ClimbSessionModel.fromJson(data));
  }

  @override
  Future<Result<ClimbSessionModel>> updateSession(
    String sessionId, {
    String? title,
    String? notes,
    DateTime? endedAt,
  }) async {
    final payload = <String, dynamic>{
      'title': ?title,
      'notes': ?notes,
      'ended_at': ?endedAt?.toUtc().toIso8601String(),
    };

    final result = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.climbSessionDetails(sessionId),
      data: payload,
    );

    return result.map((data) => ClimbSessionModel.fromJson(data));
  }

  @override
  Future<Result<void>> addAnalysis(String sessionId, String analysisId) async {
    final result = await _apiClient.post<dynamic>(
      ApiEndpoints.climbSessionAnalyses(sessionId),
      data: {'analysis_id': analysisId},
    );

    return result.map((_) {});
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    final result = await _apiClient.delete<dynamic>(
      ApiEndpoints.climbSessionDetails(sessionId),
    );

    return result.map((_) {});
  }
}

final climbSessionRemoteDataSourceProvider =
    Provider<ClimbSessionRemoteDataSource>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return ClimbSessionRemoteDataSourceImpl(apiClient);
    });
