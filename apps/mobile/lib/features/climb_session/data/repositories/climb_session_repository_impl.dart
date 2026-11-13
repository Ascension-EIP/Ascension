// @date 2026-11-13
// @file climb_session_repository_impl.dart
// @brief Production implementation of ClimbSessionRepository connected to backend with local caching.
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

/// Concrete repository handling climbing sessions via backend API with local cache.
class ClimbSessionRepositoryImpl implements ClimbSessionRepository {
  ClimbSessionRepositoryImpl({
    required ClimbSessionLocalDataSource localDataSource,
    required ClimbSessionRemoteDataSource remoteDataSource,
  }) : _local = localDataSource,
       _remote = remoteDataSource;

  final ClimbSessionLocalDataSource _local;
  final ClimbSessionRemoteDataSource _remote;

  ClimbSessionRemoteDataSource get remoteDataSource => _remote;
  ClimbSessionLocalDataSource get localDataSource => _local;

  @override
  Future<Result<ClimbSession?>> getActiveSession() async {
    final result = await _remote.getActiveSession();
    switch (result) {
      case Success(:final data):
        if (data != null &&
            !ClimbSessionLocalDataSourceImpl.isValidUuid(data.id)) {
          await _local.saveActiveSession(null);
          return const Success(null);
        }
        await _local.saveActiveSession(data);
        return Success(data?.toEntity());
      case Error(:final failure):
        // Network error fallback to local cache
        try {
          final cached = await _local.getActiveSession();
          if (cached != null) {
            if (!ClimbSessionLocalDataSourceImpl.isValidUuid(cached.id)) {
              await _local.saveActiveSession(null);
              return const Success(null);
            }
            return Success(cached.toEntity());
          }
        } catch (_) {}
        return Error(failure);
    }
  }

  @override
  Future<Result<List<ClimbSession>>> getPreviousSessions({
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await _remote.getSessions(limit: limit, offset: offset);
    switch (result) {
      case Success(:final data):
        final validData = data
            .where((s) => ClimbSessionLocalDataSourceImpl.isValidUuid(s.id))
            .toList();
        if (offset == 0) {
          await _local.savePreviousSessions(validData);
        }
        return Success(validData.map((m) => m.toEntity()).toList());
      case Error(:final failure):
        // Cache fallback on network failure
        try {
          final cached = await _local.getPreviousSessions();
          final validCached = cached
              .where((s) => ClimbSessionLocalDataSourceImpl.isValidUuid(s.id))
              .toList();
          if (validCached.isNotEmpty) {
            return Success(validCached.map((m) => m.toEntity()).toList());
          }
        } catch (_) {}
        return Error(failure);
    }
  }

  @override
  Future<Result<ClimbSession>> getSessionDetails(String sessionId) async {
    final result = await _remote.getSessionDetails(sessionId);
    return result.map((data) => data.toEntity());
  }

  @override
  Future<Result<List<ClimbAnalysisSummary>>> getPreviousAnalyses({
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await _remote.getAnalyses(limit: limit, offset: offset);
    switch (result) {
      case Success(:final data):
        final validData = data
            .where((a) => ClimbSessionLocalDataSourceImpl.isValidUuid(a.id))
            .toList();
        if (offset == 0) {
          await _local.savePreviousAnalyses(validData);
        }
        return Success(validData.map((m) => m.toEntity()).toList());
      case Error(:final failure):
        try {
          final cached = await _local.getPreviousAnalyses();
          final validCached = cached
              .where((a) => ClimbSessionLocalDataSourceImpl.isValidUuid(a.id))
              .toList();
          if (validCached.isNotEmpty) {
            return Success(validCached.map((m) => m.toEntity()).toList());
          }
        } catch (_) {}
        return Error(failure);
    }
  }

  @override
  Future<Result<ClimbSession>> startSession({
    required String name,
    String? location,
    String? notes,
    String? gymId,
    required ClimbSessionVisibility visibility,
    DateTime? startedAt,
  }) async {
    final result = await _remote.createSession(
      name: name,
      location: location,
      notes: notes,
      gymId: gymId,
      visibility: visibility,
      startedAt: startedAt,
    );

    switch (result) {
      case Success(:final data):
        await _local.saveActiveSession(data);
        return Success(data.toEntity());
      case Error(:final failure):
        return Error(failure);
    }
  }

  @override
  Future<Result<ClimbSession>> endSession(
    String sessionId, {
    DateTime? endedAt,
  }) async {
    if (!ClimbSessionLocalDataSourceImpl.isValidUuid(sessionId)) {
      await _local.saveActiveSession(null);
      try {
        final previous = await _local.getPreviousSessions();
        await _local.savePreviousSessions(
          previous
              .where((s) => ClimbSessionLocalDataSourceImpl.isValidUuid(s.id))
              .toList(),
        );
      } catch (_) {}
      return Success(
        ClimbSession(
          id: sessionId,
          name: 'Session',
          startedAt: DateTime.now(),
          endedAt: endedAt ?? DateTime.now(),
          visibility: ClimbSessionVisibility.private,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    final result = await _remote.endSession(sessionId, endedAt: endedAt);

    switch (result) {
      case Success(:final data):
        await _local.saveActiveSession(null);
        // Refresh local cache with the ended session
        try {
          final previous = await _local.getPreviousSessions();
          final updatedList = [data, ...previous.where((s) => s.id != data.id)];
          await _local.savePreviousSessions(updatedList);
        } catch (_) {}
        return Success(data.toEntity());
      case Error(:final failure):
        final isNotFound =
            failure.message.contains('404') ||
            failure.message.toLowerCase().contains('not found');
        if (isNotFound) {
          await _local.saveActiveSession(null);
          return Success(
            ClimbSession(
              id: sessionId,
              name: 'Session',
              startedAt: DateTime.now(),
              endedAt: endedAt ?? DateTime.now(),
              visibility: ClimbSessionVisibility.private,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
        return Error(failure);
    }
  }

  @override
  Future<Result<ClimbSession>> updateSession(
    String sessionId, {
    String? title,
    String? notes,
    DateTime? endedAt,
  }) async {
    final result = await _remote.updateSession(
      sessionId,
      title: title,
      notes: notes,
      endedAt: endedAt,
    );

    return result.map((data) => data.toEntity());
  }

  @override
  Future<Result<void>> addAnalysisToActiveSession(
    ClimbAnalysisSummary analysis,
  ) async {
    final activeResult = await getActiveSession();
    if (activeResult is! Success<ClimbSession?> || activeResult.data == null) {
      return const Error(
        UnexpectedFailure(
          'Aucune session active à laquelle rattacher l\'analyse.',
        ),
      );
    }

    final active = activeResult.data!;
    final linkResult = await _remote.addAnalysis(active.id, analysis.id);

    switch (linkResult) {
      case Success():
        // Refresh active session cache with updated analyses
        final detailsResult = await _remote.getSessionDetails(active.id);
        if (detailsResult is Success<ClimbSessionModel>) {
          await _local.saveActiveSession(detailsResult.data);
        }
        return const Success(null);
      case Error(:final failure):
        return Error(failure);
    }
  }

  @override
  Future<Result<void>> linkAnalysisToSession({
    required String sessionId,
    required String analysisId,
  }) async {
    return _remote.addAnalysis(sessionId, analysisId);
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    if (!ClimbSessionLocalDataSourceImpl.isValidUuid(sessionId)) {
      try {
        final active = await _local.getActiveSession();
        if (active?.id == sessionId) {
          await _local.saveActiveSession(null);
        }
        final previous = await _local.getPreviousSessions();
        await _local.savePreviousSessions(
          previous
              .where(
                (s) =>
                    s.id != sessionId &&
                    ClimbSessionLocalDataSourceImpl.isValidUuid(s.id),
              )
              .toList(),
        );
      } catch (_) {}
      return const Success(null);
    }

    final result = await _remote.deleteSession(sessionId);

    final isNotFound =
        result is Error &&
        (result.failure.message.contains('404') ||
            result.failure.message.toLowerCase().contains('not found'));

    if (result is Success || isNotFound) {
      try {
        final active = await _local.getActiveSession();
        if (active?.id == sessionId) {
          await _local.saveActiveSession(null);
        }
        final previous = await _local.getPreviousSessions();
        await _local.savePreviousSessions(
          previous.where((s) => s.id != sessionId).toList(),
        );
      } catch (_) {}
      return const Success(null);
    }

    return result;
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
