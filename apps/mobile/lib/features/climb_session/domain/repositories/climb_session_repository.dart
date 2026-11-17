// @date 2026-11-13
// @file climb_session_repository.dart
// @brief Abstract repository contract for climbing sessions and analyses.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';

/// Abstract repository defining climbing session business operations.
abstract class ClimbSessionRepository {
  /// Retrieves the currently active session, or null if no session is running.
  Future<Result<ClimbSession?>> getActiveSession();

  /// Retrieves previous completed sessions.
  Future<Result<List<ClimbSession>>> getPreviousSessions({
    int limit = 50,
    int offset = 0,
  });

  /// Reads one climbing session with its analyses by ID.
  Future<Result<ClimbSession>> getSessionDetails(String sessionId);

  /// Retrieves recent previous analyses.
  Future<Result<List<ClimbAnalysisSummary>>> getPreviousAnalyses({
    int limit = 50,
    int offset = 0,
  });

  /// Starts a new climbing session.
  Future<Result<ClimbSession>> startSession({
    required String name,
    String? location,
    String? notes,
    String? gymId,
    required ClimbSessionVisibility visibility,
    DateTime? startedAt,
  });

  /// Ends the specified ongoing climbing session.
  Future<Result<ClimbSession>> endSession(
    String sessionId, {
    DateTime? endedAt,
  });

  /// Updates title, notes or end time of a session.
  Future<Result<ClimbSession>> updateSession(
    String sessionId, {
    String? title,
    String? notes,
    DateTime? endedAt,
  });

  /// Records an analysis summary into the active session.
  Future<Result<void>> addAnalysisToActiveSession(
    ClimbAnalysisSummary analysis,
  );

  /// Links an existing analysis ID to a climbing session.
  Future<Result<void>> linkAnalysisToSession({
    required String sessionId,
    required String analysisId,
  });

  /// Deletes a climbing session.
  Future<Result<void>> deleteSession(String sessionId);
}
