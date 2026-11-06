// @date 2026-11-06
// @file climb_session_repository_impl.dart
// @brief Concrete implementation of ClimbSessionRepository with local fallback.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/climb_session/data/datasources/climb_session_local_data_source.dart';
import 'package:mobile/features/climb_session/data/datasources/climb_session_remote_data_source.dart';
import 'package:mobile/features/climb_session/data/models/climb_session_model.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:mobile/features/climb_session/domain/repositories/climb_session_repository.dart';

/// Concrete repository handling climbing sessions.
///
/// NOTE: Because the Go backend does not yet provide session endpoints,
/// this implementation uses [ClimbSessionLocalDataSource] for immediate mobile state
/// and offline-friendly persistence.
/// Once backend session routes are live, switch the calls below to use [remoteDataSource].
class ClimbSessionRepositoryImpl implements ClimbSessionRepository {
  ClimbSessionRepositoryImpl({
    required ClimbSessionLocalDataSource localDataSource,
    required ClimbSessionRemoteDataSource remoteDataSource,
  }) : _local = localDataSource,
       // ignore: unused_field
       _remote = remoteDataSource;

  final ClimbSessionLocalDataSource _local;
  final ClimbSessionRemoteDataSource _remote;

  /// Exposed for testing and future server switching.
  ClimbSessionRemoteDataSource get remoteDataSource => _remote;
  ClimbSessionLocalDataSource get localDataSource => _local;

  @override
  Future<Result<ClimbSession?>> getActiveSession() async {
    try {
      final model = await _local.getActiveSession();
      return Success(model?.toEntity());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ClimbSession>>> getPreviousSessions() async {
    try {
      final models = await _local.getPreviousSessions();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ClimbAnalysisSummary>>> getPreviousAnalyses() async {
    try {
      final models = await _local.getPreviousAnalyses();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<ClimbSession>> startSession({
    required String name,
    String? location,
    required ClimbSessionVisibility visibility,
  }) async {
    try {
      final newSession = ClimbSessionModel(
        id: 'session-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        location: location,
        visibility: visibility,
        startedAt: DateTime.now(),
        endedAt: null,
        analyses: const [],
        authorName: 'Moi',
      );
      await _local.saveActiveSession(newSession);
      return Success(newSession.toEntity());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<ClimbSession>> endSession(String sessionId) async {
    try {
      final current = await _local.getActiveSession();
      if (current == null) {
        return const Error(CacheFailure('Aucune session active à terminer.'));
      }

      final endedSession = ClimbSessionModel(
        id: current.id,
        name: current.name,
        location: current.location,
        visibility: current.visibility,
        startedAt: current.startedAt,
        endedAt: DateTime.now(),
        analyses: current.analyses,
        authorName: current.authorName,
      );

      // Remove from active
      await _local.saveActiveSession(null);

      // Append to previous sessions
      final previous = await _local.getPreviousSessions();
      await _local.savePreviousSessions([endedSession, ...previous]);

      return Success(endedSession.toEntity());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> addAnalysisToActiveSession(
    ClimbAnalysisSummary analysis,
  ) async {
    try {
      final current = await _local.getActiveSession();
      if (current != null) {
        final analysisModel = ClimbAnalysisSummaryModel.fromEntity(analysis);
        final updated = ClimbSessionModel(
          id: current.id,
          name: current.name,
          location: current.location,
          visibility: current.visibility,
          startedAt: current.startedAt,
          endedAt: current.endedAt,
          analyses: [...current.analyses, analysisModel],
          authorName: current.authorName,
        );
        await _local.saveActiveSession(updated);
      }

      // Also append to previous general analyses
      final prevAnalyses = await _local.getPreviousAnalyses();
      await _local.savePreviousAnalyses([
        ClimbAnalysisSummaryModel.fromEntity(analysis),
        ...prevAnalyses,
      ]);

      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }
}

final climbSessionRepositoryProvider = Provider<ClimbSessionRepository>((ref) {
  final local = ref.watch(climbSessionLocalDataSourceProvider);
  final remote = ref.watch(climbSessionRemoteDataSourceProvider);
  return ClimbSessionRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
  );
});
