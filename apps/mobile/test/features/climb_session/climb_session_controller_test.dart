// @date 2026-11-13
// @file climb_session_controller_test.dart
// @brief Unit tests for ClimbSessionController.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/features/climb_session/data/repositories/climb_session_repository_impl.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:mobile/features/climb_session/presentation/controllers/climb_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helper.dart';

void main() {
  late ProviderContainer container;
  late TestClimbSessionRepository fakeRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeRepo = TestClimbSessionRepository();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        climbSessionRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'loads sessions and initially has no active session and empty history',
    () async {
      final notifier = container.read(climbSessionControllerProvider.notifier);
      await notifier.loadSessions();

      final state = container.read(climbSessionControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.hasActiveSession, isFalse);
      expect(state.previousSessions.isEmpty, isTrue);
    },
  );

  test('loads pre-existing sessions from repository', () async {
    final existingSession = ClimbSession(
      id: 'prev-1',
      name: 'Past Arkose Climb',
      startedAt: DateTime.now().subtract(const Duration(hours: 3)),
      endedAt: DateTime.now().subtract(const Duration(hours: 1)),
      visibility: ClimbSessionVisibility.public,
      analyses: const [],
    );
    fakeRepo.previousSessions.add(existingSession);

    final notifier = container.read(climbSessionControllerProvider.notifier);
    await notifier.loadSessions();

    final state = container.read(climbSessionControllerProvider);
    expect(state.previousSessions.length, 1);
    expect(state.previousSessions.first.name, 'Past Arkose Climb');
  });

  test('startSession activates session and updates state', () async {
    final notifier = container.read(climbSessionControllerProvider.notifier);
    final success = await notifier.startSession(
      name: 'Evening Climb',
      location: null,
      visibility: ClimbSessionVisibility.friends,
    );

    expect(success, isTrue);
    final state = container.read(climbSessionControllerProvider);
    expect(state.hasActiveSession, isTrue);
    expect(state.activeSession?.name, 'Evening Climb');
  });

  test('endSession clears active session and stops timer', () async {
    final notifier = container.read(climbSessionControllerProvider.notifier);
    await notifier.startSession(
      name: 'To End',
      location: null,
      visibility: ClimbSessionVisibility.public,
    );

    final endSuccess = await notifier.endSession();
    expect(endSuccess, isTrue);

    final state = container.read(climbSessionControllerProvider);
    expect(state.hasActiveSession, isFalse);
    expect(state.activeSession, isNull);
    expect(state.previousSessions.first.name, 'To End');
  });

  test('addAnalysis appends analysis to active session', () async {
    final notifier = container.read(climbSessionControllerProvider.notifier);
    await notifier.startSession(
      name: 'Session with analysis',
      location: null,
      visibility: ClimbSessionVisibility.friends,
    );

    final analysis = ClimbAnalysisSummary(
      id: 'test-analysis-1',
      title: 'Analyse de pose 2D',
      type: AnalysisType.pose2d,
      status: AnalysisStatus.completed,
      createdAt: DateTime.now(),
    );

    await notifier.addAnalysis(analysis);

    final state = container.read(climbSessionControllerProvider);
    expect(state.activeSession?.analyses.length, 1);
    expect(state.previousAnalyses.first.id, 'test-analysis-1');
  });

  test('deleteSession removes session from previous sessions', () async {
    final existingSession = ClimbSession(
      id: 'to-delete-1',
      name: 'Session to Delete',
      startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      endedAt: DateTime.now().subtract(const Duration(hours: 1)),
      visibility: ClimbSessionVisibility.private,
      analyses: const [],
    );
    fakeRepo.previousSessions.add(existingSession);

    final notifier = container.read(climbSessionControllerProvider.notifier);
    await notifier.loadSessions();

    final beforeState = container.read(climbSessionControllerProvider);
    expect(beforeState.previousSessions.length, 1);

    final deleted = await notifier.deleteSession('to-delete-1');
    expect(deleted, isTrue);

    final afterState = container.read(climbSessionControllerProvider);
    expect(afterState.previousSessions.isEmpty, isTrue);
  });
}
