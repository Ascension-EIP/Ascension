// @date 2026-11-13
// @file climb_session_remote_data_source_test.dart
// @brief Unit tests for ClimbSessionRemoteDataSourceImpl.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/climb_session/data/datasources/climb_session_remote_data_source.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(Dio());

  dynamic responseData;
  Failure? failureToReturn;
  String? lastPath;
  dynamic lastData;
  Map<String, dynamic>? lastQueryParams;

  @override
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastQueryParams = queryParameters;
    if (failureToReturn != null) {
      return Error(failureToReturn!);
    }
    return Success(responseData as T);
  }

  @override
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    if (failureToReturn != null) {
      return Error(failureToReturn!);
    }
    return Success(responseData as T);
  }

  @override
  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    if (failureToReturn != null) {
      return Error(failureToReturn!);
    }
    return Success(responseData as T);
  }

  @override
  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    if (failureToReturn != null) {
      return Error(failureToReturn!);
    }
    return Success(responseData as T);
  }
}

void main() {
  late FakeApiClient fakeApiClient;
  late ClimbSessionRemoteDataSourceImpl remoteDataSource;

  setUp(() {
    fakeApiClient = FakeApiClient();
    remoteDataSource = ClimbSessionRemoteDataSourceImpl(fakeApiClient);
  });

  group('ClimbSessionRemoteDataSourceImpl Tests', () {
    test('getActiveSession returns null on 204 / empty response', () async {
      fakeApiClient.responseData = null;

      final result = await remoteDataSource.getActiveSession();

      expect(fakeApiClient.lastPath, ApiEndpoints.activeClimbSession);
      expect(result, isA<Success<dynamic>>());
      expect((result as Success).data, isNull);
    });

    test('getActiveSession parses active session with analyses', () async {
      fakeApiClient.responseData = {
        'id': 'session-uuid-1',
        'title': 'Active Session Arkose',
        'visibility': 'friends',
        'started_at': '2026-11-13T10:00:00Z',
        'analyses': [
          {
            'id': 'analysis-uuid-1',
            'video_id': 'video-uuid-1',
            'type': '2d',
            'status': 'running',
            'progress': 45,
            'created_at': '2026-11-13T10:05:00Z',
          },
        ],
      };

      final result = await remoteDataSource.getActiveSession();

      expect(result, isA<Success<dynamic>>());
      final session = (result as Success).data;
      expect(session?.id, 'session-uuid-1');
      expect(session?.name, 'Active Session Arkose');
      expect(session?.visibility, ClimbSessionVisibility.friends);
      expect(session?.analyses.length, 1);
      expect(session?.analyses.first.id, 'analysis-uuid-1');
      expect(session?.analyses.first.type, AnalysisType.pose2d);
      expect(session?.analyses.first.status, AnalysisStatus.inProgress);
      expect(session?.analyses.first.progressPercentage, 45);
    });

    test('getSessions returns paginated list of sessions', () async {
      fakeApiClient.responseData = {
        'sessions': [
          {
            'id': 'session-uuid-2',
            'title': 'Completed climb',
            'visibility': 'public',
            'started_at': '2026-11-12T14:00:00Z',
            'ended_at': '2026-11-12T16:00:00Z',
          },
        ],
        'total': 1,
        'limit': 50,
        'offset': 0,
      };

      final result = await remoteDataSource.getSessions();

      expect(fakeApiClient.lastPath, ApiEndpoints.climbSessions);
      expect(fakeApiClient.lastQueryParams?['limit'], 50);
      expect(result, isA<Success<dynamic>>());
      final sessions = (result as Success).data;
      expect(sessions.length, 1);
      expect(sessions.first.id, 'session-uuid-2');
      expect(sessions.first.name, 'Completed climb');
      expect(sessions.first.visibility, ClimbSessionVisibility.public);
    });

    test('getAnalyses returns paginated list of analyses', () async {
      fakeApiClient.responseData = {
        'analyses': [
          {
            'id': 'analysis-uuid-3',
            'type': '3d',
            'status': 'success',
            'progress': 100,
            'created_at': '2026-11-13T09:00:00Z',
          },
        ],
        'total': 1,
        'limit': 20,
        'offset': 0,
      };

      final result = await remoteDataSource.getAnalyses(limit: 20);

      expect(fakeApiClient.lastPath, ApiEndpoints.analyses);
      expect(fakeApiClient.lastQueryParams?['limit'], 20);
      expect(result, isA<Success<dynamic>>());
      final analyses = (result as Success).data;
      expect(analyses.length, 1);
      expect(analyses.first.type, AnalysisType.pose3d);
      expect(analyses.first.status, AnalysisStatus.completed);
    });

    test(
      'createSession posts to /v1/sessions and returns created model',
      () async {
        fakeApiClient.responseData = {
          'id': 'session-created-1',
          'title': 'New Session',
          'visibility': 'private',
          'started_at': '2026-11-13T12:00:00Z',
        };

        final result = await remoteDataSource.createSession(
          name: 'New Session',
          visibility: ClimbSessionVisibility.private,
        );

        expect(fakeApiClient.lastPath, ApiEndpoints.climbSessions);
        expect(fakeApiClient.lastData['title'], 'New Session');
        expect(fakeApiClient.lastData['visibility'], 'private');
        expect(result, isA<Success<dynamic>>());
        final session = (result as Success).data;
        expect(session.id, 'session-created-1');
        expect(session.name, 'New Session');
      },
    );

    test('endSession puts ended_at to /v1/sessions/:id', () async {
      fakeApiClient.responseData = {
        'id': 'session-uuid-1',
        'title': 'Ended Session',
        'visibility': 'public',
        'started_at': '2026-11-13T10:00:00Z',
        'ended_at': '2026-11-13T12:00:00Z',
      };

      final result = await remoteDataSource.endSession('session-uuid-1');

      expect(
        fakeApiClient.lastPath,
        ApiEndpoints.climbSessionDetails('session-uuid-1'),
      );
      expect(fakeApiClient.lastData['ended_at'], isNotNull);
      expect(result, isA<Success<dynamic>>());
      final session = (result as Success).data;
      expect(session.endedAt, isNotNull);
    });

    test('addAnalysis posts to /v1/sessions/:id/analyses', () async {
      fakeApiClient.responseData = null;

      final result = await remoteDataSource.addAnalysis(
        'session-1',
        'analysis-1',
      );

      expect(
        fakeApiClient.lastPath,
        ApiEndpoints.climbSessionAnalyses('session-1'),
      );
      expect(fakeApiClient.lastData['analysis_id'], 'analysis-1');
      expect(result, isA<Success<dynamic>>());
    });

    test('deleteSession deletes /v1/sessions/:id', () async {
      fakeApiClient.responseData = null;

      final result = await remoteDataSource.deleteSession('session-1');

      expect(
        fakeApiClient.lastPath,
        ApiEndpoints.climbSessionDetails('session-1'),
      );
      expect(result, isA<Success<dynamic>>());
    });
  });
}
