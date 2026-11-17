// @date 2026-11-13
// @file climb_session_repository_test.dart
// @brief Unit tests for ClimbSessionLocalDataSource and ClimbSessionRepositoryImpl.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/climb_session/data/datasources/climb_session_local_data_source.dart';
import 'package:mobile/features/climb_session/data/datasources/climb_session_remote_data_source.dart';
import 'package:mobile/features/climb_session/data/models/climb_session_model.dart';
import 'package:mobile/features/climb_session/data/repositories/climb_session_repository_impl.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRemoteDataSource implements ClimbSessionRemoteDataSource {
  ClimbSessionModel? activeSession;
  final List<ClimbSessionModel> remoteSessions = [];
  final List<ClimbAnalysisSummaryModel> remoteAnalyses = [];
  bool simulateError = false;

  @override
  Future<Result<ClimbSessionModel?>> getActiveSession() async {
    if (simulateError) return const Error(ServerFailure('Simulated failure'));
    return Success(activeSession);
  }

  @override
  Future<Result<List<ClimbSessionModel>>> getSessions({
    int limit = 50,
    int offset = 0,
  }) async {
    if (simulateError) return const Error(ServerFailure('Simulated failure'));
    return Success(remoteSessions);
  }

  @override
  Future<Result<ClimbSessionModel>> getSessionDetails(String sessionId) async {
    if (simulateError) return const Error(ServerFailure('Simulated failure'));
    final found = remoteSessions.firstWhere((s) => s.id == sessionId);
    return Success(found);
  }

  @override
  Future<Result<List<ClimbAnalysisSummaryModel>>> getAnalyses({
    int limit = 50,
    int offset = 0,
  }) async {
    if (simulateError) return const Error(ServerFailure('Simulated failure'));
    return Success(remoteAnalyses);
  }

  @override
  Future<Result<ClimbSessionModel>> createSession({
    required String name,
    String? location,
    String? gymId,
    DateTime? startedAt,
    required ClimbSessionVisibility visibility,
    String? notes,
  }) async {
    if (simulateError) return const Error(ServerFailure('Simulated failure'));
    final id =
        '00000000-0000-4000-8000-${(remoteSessions.length + 1).toString().padLeft(12, '0')}';
    final created = ClimbSessionModel(
      id: id,
      name: name,
      location: location,
      gymId: gymId,
      notes: notes,
      startedAt: startedAt ?? DateTime.now(),
      visibility: visibility,
      analyses: const [],
    );
    activeSession = created;
    remoteSessions.insert(0, created);
    return Success(created);
  }

  @override
  Future<Result<ClimbSessionModel>> endSession(
    String sessionId, {
    DateTime? endedAt,
    String? name,
    String? notes,
  }) async {
    if (simulateError) return const Error(ServerFailure('Simulated failure'));
    final session =
        (activeSession?.id == sessionId ? activeSession : null) ??
        remoteSessions.firstWhere((s) => s.id == sessionId);
    final ended = session.copyWith(
      endedAt: endedAt ?? DateTime.now(),
      name: name ?? session.name,
      notes: notes ?? session.notes,
    );
    if (activeSession?.id == sessionId) {
      activeSession = null;
    }
    final index = remoteSessions.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      remoteSessions[index] = ended;
    }
    return Success(ended);
  }

  @override
  Future<Result<ClimbSessionModel>> updateSession(
    String sessionId, {
    String? title,
    String? name,
    String? notes,
    ClimbSessionVisibility? visibility,
    DateTime? endedAt,
  }) async {
    if (simulateError) return const Error(ServerFailure('Simulated failure'));
    final index = remoteSessions.indexWhere((s) => s.id == sessionId);
    if (index < 0) return const Error(ServerFailure('Not found'));
    final sessionName = title ?? name ?? remoteSessions[index].name;
    final updated = remoteSessions[index].copyWith(
      name: sessionName,
      notes: notes ?? remoteSessions[index].notes,
      visibility: visibility ?? remoteSessions[index].visibility,
      endedAt: endedAt ?? remoteSessions[index].endedAt,
    );
    remoteSessions[index] = updated;
    if (activeSession?.id == sessionId) {
      activeSession = updated;
    }
    return Success(updated);
  }

  @override
  Future<Result<void>> addAnalysis(String sessionId, String analysisId) async {
    if (simulateError) return const Error(ServerFailure('Simulated failure'));
    final analysisModel = ClimbAnalysisSummaryModel(
      id: analysisId,
      title: 'Pose 2D',
      type: AnalysisType.pose2d,
      status: AnalysisStatus.completed,
      createdAt: DateTime.now(),
    );
    if (activeSession?.id == sessionId) {
      activeSession = activeSession!.copyWith(
        analyses: [...activeSession!.analyses, analysisModel],
      );
    }
    final index = remoteSessions.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      remoteSessions[index] = remoteSessions[index].copyWith(
        analyses: [...remoteSessions[index].analyses, analysisModel],
      );
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    if (simulateError) return const Error(ServerFailure('Simulated failure'));
    remoteSessions.removeWhere((s) => s.id == sessionId);
    if (activeSession?.id == sessionId) {
      activeSession = null;
    }
    return const Success(null);
  }
}

void main() {
  late SharedPreferences prefs;
  late LocalStorageService storage;
  late ClimbSessionLocalDataSource localDataSource;
  late FakeRemoteDataSource fakeRemote;
  late ClimbSessionRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = LocalStorageService(prefs);
    localDataSource = ClimbSessionLocalDataSourceImpl(storage);
    fakeRemote = FakeRemoteDataSource();
    repository = ClimbSessionRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: fakeRemote,
    );
  });

  group('ClimbSessionRepository Tests', () {
    test('initially returns null active session and empty history when no sessions exist', () async {
      final active = await repository.getActiveSession();
      expect(active, isA<Success<ClimbSession?>>());
      expect((active as Success<ClimbSession?>).data, isNull);

      final previous = await repository.getPreviousSessions();
      expect(previous, isA<Success<List<ClimbSession>>>());
      expect((previous as Success<List<ClimbSession>>).data, isEmpty);

      final analyses = await repository.getPreviousAnalyses();
      expect(analyses, isA<Success<List<ClimbAnalysisSummary>>>());
      expect((analyses as Success<List<ClimbAnalysisSummary>>).data, isEmpty);
    });

    test(
      'startSession creates on remote and persists an active session',
      () async {
        final result = await repository.startSession(
          name: 'Morning Session Arkose',
          location: null,
          visibility: ClimbSessionVisibility.public,
        );

        expect(result, isA<Success<ClimbSession>>());
        final session = (result as Success<ClimbSession>).data;
        expect(session.name, 'Morning Session Arkose');
        expect(session.visibility, ClimbSessionVisibility.public);
        expect(session.isActive, isTrue);

        final activeCheck = await repository.getActiveSession();
        expect(activeCheck, isA<Success<ClimbSession?>>());
        final savedActive = (activeCheck as Success<ClimbSession?>).data;
        expect(savedActive?.id, session.id);
        expect(savedActive?.name, 'Morning Session Arkose');
      },
    );

    test(
      'endSession ends current active session and appends to previous sessions',
      () async {
        final startResult = await repository.startSession(
          name: 'Test Session',
          location: null,
          visibility: ClimbSessionVisibility.private,
        );
        final activeId = (startResult as Success<ClimbSession>).data.id;

        final endResult = await repository.endSession(activeId);
        expect(endResult, isA<Success<ClimbSession>>());
        final ended = (endResult as Success<ClimbSession>).data;
        expect(ended.isActive, isFalse);
        expect(ended.endedAt, isNotNull);

        final activeAfter = await repository.getActiveSession();
        expect((activeAfter as Success<ClimbSession?>).data, isNull);

        final previousList = await repository.getPreviousSessions();
        final previous = (previousList as Success<List<ClimbSession>>).data;
        expect(previous.first.id, ended.id);
      },
    );

    test(
      'addAnalysisToActiveSession attaches analysis to current session',
      () async {
        await repository.startSession(
          name: 'Analysis Test Session',
          location: null,
          visibility: ClimbSessionVisibility.friends,
        );

        const testAnalysisId = '00000000-0000-4000-8000-000000000099';
        final analysis = ClimbAnalysisSummary(
          id: testAnalysisId,
          title: 'Pose 2D',
          type: AnalysisType.pose2d,
          status: AnalysisStatus.completed,
          createdAt: DateTime.now(),
        );

        final addResult = await repository.addAnalysisToActiveSession(analysis);
        expect(addResult, isA<Success<void>>());

        final active = await repository.getActiveSession();
        final current = (active as Success<ClimbSession?>).data;
        expect(current!.analyses.length, 1);
        expect(current.analyses.first.id, testAnalysisId);
      },
    );

    test('deleteSession removes session from remote and local cache', () async {
      final startResult = await repository.startSession(
        name: 'Session to Delete',
        visibility: ClimbSessionVisibility.private,
      );
      final id = (startResult as Success<ClimbSession>).data.id;

      final deleteResult = await repository.deleteSession(id);
      expect(deleteResult, isA<Success<void>>());

      final activeCheck = await repository.getActiveSession();
      expect((activeCheck as Success<ClimbSession?>).data, isNull);
    });

    test(
      'getActiveSession falls back to local cache when remote fails',
      () async {
        final startResult = await repository.startSession(
          name: 'Cached Session',
          visibility: ClimbSessionVisibility.public,
        );
        final created = (startResult as Success<ClimbSession>).data;

        // Now simulate remote failure
        fakeRemote.simulateError = true;

        final fallbackResult = await repository.getActiveSession();
        expect(fallbackResult, isA<Success<ClimbSession?>>());
        expect((fallbackResult as Success<ClimbSession?>).data?.id, created.id);
      },
    );
  });
}
