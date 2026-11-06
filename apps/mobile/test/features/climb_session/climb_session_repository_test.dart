// @date 2026-11-06
// @file climb_session_repository_test.dart
// @brief Unit tests for ClimbSessionLocalDataSource and ClimbSessionRepositoryImpl.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/climb_session/data/datasources/climb_session_local_data_source.dart';
import 'package:mobile/features/climb_session/data/datasources/climb_session_remote_data_source.dart';
import 'package:mobile/features/climb_session/data/models/climb_session_model.dart';
import 'package:mobile/features/climb_session/data/repositories/climb_session_repository_impl.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRemoteDataSource implements ClimbSessionRemoteDataSource {
  @override
  Future<ClimbSessionModel?> getActiveSession() async => null;

  @override
  Future<List<ClimbSessionModel>> getSessions() async => const [];

  @override
  Future<List<ClimbAnalysisSummaryModel>> getAnalyses() async => const [];

  @override
  Future<ClimbSessionModel> createSession({
    required String name,
    String? location,
    required ClimbSessionVisibility visibility,
  }) async => throw UnimplementedError();

  @override
  Future<ClimbSessionModel> endSession(String sessionId) async =>
      throw UnimplementedError();

  @override
  Future<void> addAnalysis(
    String sessionId,
    ClimbAnalysisSummaryModel analysis,
  ) async {}
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
    test(
      'initially returns null active session and default seed history',
      () async {
        final active = await repository.getActiveSession();
        expect(active, isA<Success<ClimbSession?>>());
        expect((active as Success<ClimbSession?>).data, isNull);

        final previous = await repository.getPreviousSessions();
        expect(previous, isA<Success<List<ClimbSession>>>());
        expect(
          (previous as Success<List<ClimbSession>>).data.length,
          greaterThanOrEqualTo(2),
        );

        final analyses = await repository.getPreviousAnalyses();
        expect(analyses, isA<Success<List<ClimbAnalysisSummary>>>());
        expect(
          (analyses as Success<List<ClimbAnalysisSummary>>).data.length,
          greaterThanOrEqualTo(1),
        );
      },
    );

    test('startSession creates and persists an active session', () async {
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
    });

    test(
      'endSession ends current active session and appends to previous sessions',
      () async {
        await repository.startSession(
          name: 'Test Session',
          location: null,
          visibility: ClimbSessionVisibility.private,
        );

        final active = await repository.getActiveSession();
        final activeId = (active as Success<ClimbSession?>).data!.id;

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

        final analysis = ClimbAnalysisSummary(
          id: 'ana-1',
          title: 'Pose 2D',
          type: AnalysisType.pose2d,
          status: AnalysisStatus.completed,
          createdAt: DateTime.now(),
        );

        await repository.addAnalysisToActiveSession(analysis);

        final active = await repository.getActiveSession();
        final current = (active as Success<ClimbSession?>).data;
        expect(current!.analyses.length, 1);
        expect(current.analyses.first.id, 'ana-1');
      },
    );
  });
}
