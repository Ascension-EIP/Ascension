// @date 2026-11-06
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
  Future<Result<List<ClimbSession>>> getPreviousSessions();

  /// Retrieves recent previous analyses.
  Future<Result<List<ClimbAnalysisSummary>>> getPreviousAnalyses();

  /// Starts a new climbing session.
  Future<Result<ClimbSession>> startSession({
    required String name,
    String? location,
    required ClimbSessionVisibility visibility,
  });

  /// Ends the specified ongoing climbing session.
  Future<Result<ClimbSession>> endSession(String sessionId);

  /// Records an analysis summary into the active session.
  Future<Result<void>> addAnalysisToActiveSession(
    ClimbAnalysisSummary analysis,
  );
}
