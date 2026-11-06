// @date 2026-11-06
// @file climb_session_controller_test.dart
// @brief Unit tests for ClimbSessionController.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:mobile/features/climb_session/presentation/controllers/climb_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('loads sessions and initially has no active session', () async {
    final notifier = container.read(climbSessionControllerProvider.notifier);
    await notifier.loadSessions();

    final state = container.read(climbSessionControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.hasActiveSession, isFalse);
    expect(state.previousSessions.isNotEmpty, isTrue);
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
}
