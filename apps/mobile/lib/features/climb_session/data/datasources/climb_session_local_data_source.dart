// @date 2026-11-06
// @file climb_session_local_data_source.dart
// @brief Local persistence for active session and session history.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/features/climb_session/data/models/climb_session_model.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';

abstract class ClimbSessionLocalDataSource {
  Future<ClimbSessionModel?> getActiveSession();
  Future<void> saveActiveSession(ClimbSessionModel? session);
  Future<List<ClimbSessionModel>> getPreviousSessions();
  Future<void> savePreviousSessions(List<ClimbSessionModel> sessions);
  Future<List<ClimbAnalysisSummaryModel>> getPreviousAnalyses();
  Future<void> savePreviousAnalyses(List<ClimbAnalysisSummaryModel> analyses);
}

class ClimbSessionLocalDataSourceImpl implements ClimbSessionLocalDataSource {
  ClimbSessionLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;

  static const _activeSessionKey = 'ascension_active_session_v1';
  static const _previousSessionsKey = 'ascension_previous_sessions_v1';
  static const _previousAnalysesKey = 'ascension_previous_analyses_v1';

  @override
  Future<ClimbSessionModel?> getActiveSession() async {
    final raw = _storage.getString(_activeSessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ClimbSessionModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveActiveSession(ClimbSessionModel? session) async {
    if (session == null) {
      await _storage.remove(_activeSessionKey);
    } else {
      await _storage.setString(_activeSessionKey, jsonEncode(session.toJson()));
    }
  }

  @override
  Future<List<ClimbSessionModel>> getPreviousSessions() async {
    final raw = _storage.getString(_previousSessionsKey);
    if (raw == null || raw.isEmpty) {
      // Seed default sample sessions aligned with Excalidraw design
      final seed = _defaultSampleSessions();
      await savePreviousSessions(seed);
      return seed;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (item) => ClimbSessionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return _defaultSampleSessions();
    }
  }

  @override
  Future<void> savePreviousSessions(List<ClimbSessionModel> sessions) async {
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await _storage.setString(_previousSessionsKey, jsonEncode(jsonList));
  }

  @override
  Future<List<ClimbAnalysisSummaryModel>> getPreviousAnalyses() async {
    final raw = _storage.getString(_previousAnalysesKey);
    if (raw == null || raw.isEmpty) {
      final seed = _defaultSampleAnalyses();
      await savePreviousAnalyses(seed);
      return seed;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (item) => ClimbAnalysisSummaryModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (_) {
      return _defaultSampleAnalyses();
    }
  }

  @override
  Future<void> savePreviousAnalyses(
    List<ClimbAnalysisSummaryModel> analyses,
  ) async {
    final jsonList = analyses.map((a) => a.toJson()).toList();
    await _storage.setString(_previousAnalysesKey, jsonEncode(jsonList));
  }

  List<ClimbSessionModel> _defaultSampleSessions() {
    final now = DateTime.now();
    return [
      ClimbSessionModel(
        id: 'seed-session-1',
        name: 'Session du matin',
        location: 'Arkose Nation',
        visibility: ClimbSessionVisibility.friends,
        startedAt: now.subtract(const Duration(days: 2, hours: 3)),
        endedAt: now.subtract(const Duration(days: 2, hours: 1)),
        authorName: 'Nicolas',
        analyses: [
          ClimbAnalysisSummaryModel(
            id: 'sample-analysis-1',
            title: 'Analyse 1',
            type: AnalysisType.pose2d,
            status: AnalysisStatus.completed,
            createdAt: now.subtract(
              const Duration(days: 2, hours: 2, minutes: 40),
            ),
          ),
          ClimbAnalysisSummaryModel(
            id: 'sample-analysis-2',
            title: 'Analyse 2',
            type: AnalysisType.ghostMode,
            status: AnalysisStatus.completed,
            createdAt: now.subtract(
              const Duration(days: 2, hours: 2, minutes: 15),
            ),
          ),
        ],
      ),
      ClimbSessionModel(
        id: 'seed-session-2',
        name: 'Session du soir',
        location: 'Climb Up Paris',
        visibility: ClimbSessionVisibility.public,
        startedAt: now.subtract(const Duration(days: 5, hours: 6)),
        endedAt: now.subtract(const Duration(days: 5, hours: 4)),
        authorName: 'Christophe',
        analyses: [
          ClimbAnalysisSummaryModel(
            id: 'sample-analysis-3',
            title: 'Analyse 1',
            type: AnalysisType.pose2d,
            status: AnalysisStatus.completed,
            createdAt: now.subtract(const Duration(days: 5, hours: 5)),
          ),
        ],
      ),
    ];
  }

  List<ClimbAnalysisSummaryModel> _defaultSampleAnalyses() {
    final now = DateTime.now();
    return [
      ClimbAnalysisSummaryModel(
        id: 'standalone-analysis-1',
        title: 'Analyse de pose 2D',
        type: AnalysisType.pose2d,
        status: AnalysisStatus.completed,
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
      ),
      ClimbAnalysisSummaryModel(
        id: 'standalone-analysis-2',
        title: 'Mode fantôme',
        type: AnalysisType.ghostMode,
        status: AnalysisStatus.completed,
        createdAt: now.subtract(const Duration(days: 3, hours: 8)),
      ),
    ];
  }
}

final climbSessionLocalDataSourceProvider =
    Provider<ClimbSessionLocalDataSource>((ref) {
      final storage = ref.watch(localStorageServiceProvider);
      return ClimbSessionLocalDataSourceImpl(storage);
    });
