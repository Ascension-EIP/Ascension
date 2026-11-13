// @date 2026-11-13
// @file climb_session_state.dart
// @brief State object for climb sessions, timer, and analyses.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:equatable/equatable.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';

class ClimbSessionState extends Equatable {
  const ClimbSessionState({
    this.activeSession,
    this.previousSessions = const [],
    this.previousAnalyses = const [],
    this.activeDuration = Duration.zero,
    this.isLoading = false,
    this.errorMessage,
  });

  final ClimbSession? activeSession;
  final List<ClimbSession> previousSessions;
  final List<ClimbAnalysisSummary> previousAnalyses;
  final Duration activeDuration;
  final bool isLoading;
  final String? errorMessage;

  bool get hasActiveSession => activeSession != null;

  /// Formatted duration for Excalidraw display: "32min 26s" or "1h 15min 26s"
  String get formattedActiveDuration {
    final hours = activeDuration.inHours;
    final minutes = activeDuration.inMinutes.remainder(60);
    final seconds = activeDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min ${seconds}s';
    } else {
      return '${minutes}min ${seconds}s';
    }
  }

  ClimbSessionState copyWith({
    ClimbSession? activeSession,
    bool clearActiveSession = false,
    List<ClimbSession>? previousSessions,
    List<ClimbAnalysisSummary>? previousAnalyses,
    Duration? activeDuration,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ClimbSessionState(
      activeSession: clearActiveSession
          ? null
          : (activeSession ?? this.activeSession),
      previousSessions: previousSessions ?? this.previousSessions,
      previousAnalyses: previousAnalyses ?? this.previousAnalyses,
      activeDuration: activeDuration ?? this.activeDuration,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    activeSession,
    previousSessions,
    previousAnalyses,
    activeDuration,
    isLoading,
    errorMessage,
  ];
}
