// @date 2026-11-13
// @file climb_session_controller.dart
// @brief Riverpod controller managing climbing sessions and live timer.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/climb_session/data/repositories/climb_session_repository_impl.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:mobile/features/climb_session/presentation/controllers/climb_session_state.dart';

class ClimbSessionController extends Notifier<ClimbSessionState> {
  Timer? _ticker;
  bool _isDisposed = false;

  @override
  ClimbSessionState build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      _ticker?.cancel();
    });

    // Asynchronously load initial sessions
    Future.microtask(loadSessions);

    return const ClimbSessionState(isLoading: true);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      final active = state.activeSession;
      if (active != null) {
        state = state.copyWith(activeDuration: active.duration);
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> loadSessions() async {
    if (_isDisposed) return;
    final repo = ref.read(climbSessionRepositoryProvider);

    final activeResult = await repo.getActiveSession();
    final prevSessionsResult = await repo.getPreviousSessions();
    final prevAnalysesResult = await repo.getPreviousAnalyses();

    if (_isDisposed) return;

    ClimbSession? activeSession;
    if (activeResult is Success<ClimbSession?>) {
      activeSession = activeResult.data;
    }

    List<ClimbSession> prevSessions = [];
    if (prevSessionsResult is Success<List<ClimbSession>>) {
      prevSessions = prevSessionsResult.data;
    }

    List<ClimbAnalysisSummary> prevAnalyses = [];
    if (prevAnalysesResult is Success<List<ClimbAnalysisSummary>>) {
      prevAnalyses = prevAnalysesResult.data;
    }

    final duration = activeSession?.duration ?? Duration.zero;

    state = state.copyWith(
      activeSession: activeSession,
      clearActiveSession: activeSession == null,
      previousSessions: prevSessions,
      previousAnalyses: prevAnalyses,
      activeDuration: duration,
      isLoading: false,
      clearError: true,
    );

    if (activeSession != null) {
      _startTicker();
    } else {
      _stopTicker();
    }
  }

  Future<bool> startSession({
    required String name,
    String? location,
    String? notes,
    String? gymId,
    required ClimbSessionVisibility visibility,
    DateTime? startedAt,
  }) async {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(climbSessionRepositoryProvider);

    final result = await repo.startSession(
      name: name,
      location: location,
      notes: notes,
      gymId: gymId,
      visibility: visibility,
      startedAt: startedAt,
    );

    if (_isDisposed) return false;

    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          activeSession: data,
          activeDuration: Duration.zero,
          isLoading: false,
          clearError: true,
        );
        _startTicker();
        return true;
      case Error(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
    }
  }

  Future<bool> endSession() async {
    final current = state.activeSession;
    if (current == null) return false;

    state = state.copyWith(isLoading: true);
    final repo = ref.read(climbSessionRepositoryProvider);

    final result = await repo.endSession(current.id);

    if (_isDisposed) return false;

    switch (result) {
      case Success(:final data):
        _stopTicker();
        final previous = [
          data,
          ...state.previousSessions.where((s) => s.id != data.id),
        ];
        state = state.copyWith(
          clearActiveSession: true,
          previousSessions: previous,
          activeDuration: Duration.zero,
          isLoading: false,
          clearError: true,
        );
        return true;
      case Error(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
    }
  }

  Future<bool> deleteSession(String sessionId) async {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(climbSessionRepositoryProvider);

    final result = await repo.deleteSession(sessionId);

    if (_isDisposed) return false;

    switch (result) {
      case Success():
        final updatedPrev = state.previousSessions
            .where((s) => s.id != sessionId)
            .toList();
        final wasActive = state.activeSession?.id == sessionId;
        if (wasActive) {
          _stopTicker();
        }
        state = state.copyWith(
          clearActiveSession: wasActive,
          previousSessions: updatedPrev,
          isLoading: false,
          clearError: true,
        );
        return true;
      case Error(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
    }
  }

  Future<void> addAnalysis(ClimbAnalysisSummary analysis) async {
    final repo = ref.read(climbSessionRepositoryProvider);
    await repo.addAnalysisToActiveSession(analysis);

    if (_isDisposed) return;

    // Refresh active session from server/cache
    final activeResult = await repo.getActiveSession();
    ClimbSession? updatedActive;
    if (activeResult is Success<ClimbSession?>) {
      updatedActive = activeResult.data;
    }

    state = state.copyWith(
      activeSession: updatedActive,
      previousAnalyses: [
        analysis,
        ...state.previousAnalyses.where((a) => a.id != analysis.id),
      ],
    );
  }
}

final climbSessionControllerProvider =
    NotifierProvider<ClimbSessionController, ClimbSessionState>(
      ClimbSessionController.new,
    );
