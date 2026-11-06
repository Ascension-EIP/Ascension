// @date 2026-11-06
// @file climb_session_remote_data_source.dart
// @brief Remote data source contract and prepared endpoints for sessions.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/climb_session/data/models/climb_session_model.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';

/// Contract for future server-side session endpoints.
///
/// Note: The backend Go API does not yet implement the session endpoints.
/// This remote data source defines the expected contract and will be seamlessly
/// activated once the backend is ready.
abstract class ClimbSessionRemoteDataSource {
  Future<ClimbSessionModel?> getActiveSession();
  Future<List<ClimbSessionModel>> getSessions();
  Future<List<ClimbAnalysisSummaryModel>> getAnalyses();
  Future<ClimbSessionModel> createSession({
    required String name,
    String? location,
    required ClimbSessionVisibility visibility,
  });
  Future<ClimbSessionModel> endSession(String sessionId);
  Future<void> addAnalysis(
    String sessionId,
    ClimbAnalysisSummaryModel analysis,
  );
}

/// Implementation ready to connect with [ApiClient] when backend is ready.
class ClimbSessionRemoteDataSourceImpl implements ClimbSessionRemoteDataSource {
  const ClimbSessionRemoteDataSourceImpl(this._apiClient);

  // ignore: unused_field
  final ApiClient _apiClient;

  @override
  Future<ClimbSessionModel?> getActiveSession() async {
    // When server endpoint is ready:
    // final response = await _apiClient.get<Map<String, dynamic>>('/sessions/active');
    // if (response.data == null) return null;
    // return ClimbSessionModel.fromJson(response.data!);
    return null;
  }

  @override
  Future<List<ClimbSessionModel>> getSessions() async {
    // When server endpoint is ready:
    // final response = await _apiClient.get<List<dynamic>>('/sessions');
    // return (response.data ?? []).map((json) => ClimbSessionModel.fromJson(json as Map<String, dynamic>)).toList();
    return const [];
  }

  @override
  Future<List<ClimbAnalysisSummaryModel>> getAnalyses() async {
    // When server endpoint is ready:
    // final response = await _apiClient.get<List<dynamic>>('/analyses');
    // return (response.data ?? []).map((json) => ClimbAnalysisSummaryModel.fromJson(json as Map<String, dynamic>)).toList();
    return const [];
  }

  @override
  Future<ClimbSessionModel> createSession({
    required String name,
    String? location,
    required ClimbSessionVisibility visibility,
  }) async {
    // When server endpoint is ready:
    // final response = await _apiClient.post<Map<String, dynamic>>('/sessions', data: {
    //   'name': name,
    //   'location': location,
    //   'visibility': visibility.name,
    // });
    // return ClimbSessionModel.fromJson(response.data!);
    throw UnimplementedError('Server session endpoint is not implemented yet.');
  }

  @override
  Future<ClimbSessionModel> endSession(String sessionId) async {
    // When server endpoint is ready:
    // final response = await _apiClient.post<Map<String, dynamic>>('/sessions/$sessionId/end');
    // return ClimbSessionModel.fromJson(response.data!);
    throw UnimplementedError('Server session endpoint is not implemented yet.');
  }

  @override
  Future<void> addAnalysis(
    String sessionId,
    ClimbAnalysisSummaryModel analysis,
  ) async {
    // When server endpoint is ready:
    // await _apiClient.post<void>('/sessions/$sessionId/analyses', data: analysis.toJson());
  }
}

final climbSessionRemoteDataSourceProvider =
    Provider<ClimbSessionRemoteDataSource>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return ClimbSessionRemoteDataSourceImpl(apiClient);
    });
