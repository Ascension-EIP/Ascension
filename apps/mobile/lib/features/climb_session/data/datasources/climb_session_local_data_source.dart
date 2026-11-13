// @date 2026-11-13
// @file climb_session_local_data_source.dart
// @brief Local persistence for active session and cached session history.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/features/climb_session/data/models/climb_session_model.dart';

abstract class ClimbSessionLocalDataSource {
  Future<ClimbSessionModel?> getActiveSession();
  Future<void> saveActiveSession(ClimbSessionModel? session);
  Future<List<ClimbSessionModel>> getPreviousSessions();
  Future<void> savePreviousSessions(List<ClimbSessionModel> sessions);
  Future<List<ClimbAnalysisSummaryModel>> getPreviousAnalyses();
  Future<void> savePreviousAnalyses(List<ClimbAnalysisSummaryModel> analyses);
  Future<void> clear();
}

class ClimbSessionLocalDataSourceImpl implements ClimbSessionLocalDataSource {
  ClimbSessionLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;

  static const _activeSessionKey = 'ascension_active_session_v2';
  static const _previousSessionsKey = 'ascension_previous_sessions_v2';
  static const _previousAnalysesKey = 'ascension_previous_analyses_v2';

  static const _legacyKeys = [
    'ascension_active_session_v1',
    'ascension_previous_sessions_v1',
    'ascension_previous_analyses_v1',
    'climb_sessions_active',
    'climb_sessions_list',
    'climb_sessions_analyses',
  ];

  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isValidUuid(String id) => _uuidRegex.hasMatch(id);

  void _purgeLegacyData() {
    for (final key in _legacyKeys) {
      _storage.remove(key);
    }
  }

  @override
  Future<ClimbSessionModel?> getActiveSession() async {
    _purgeLegacyData();
    final raw = _storage.getString(_activeSessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final model = ClimbSessionModel.fromJson(json);
      if (!isValidUuid(model.id)) {
        await _storage.remove(_activeSessionKey);
        return null;
      }
      return model;
    } catch (_) {
      await _storage.remove(_activeSessionKey);
      return null;
    }
  }

  @override
  Future<void> saveActiveSession(ClimbSessionModel? session) async {
    _purgeLegacyData();
    if (session == null || !isValidUuid(session.id)) {
      await _storage.remove(_activeSessionKey);
    } else {
      await _storage.setString(_activeSessionKey, jsonEncode(session.toJson()));
    }
  }

  @override
  Future<List<ClimbSessionModel>> getPreviousSessions() async {
    _purgeLegacyData();
    final raw = _storage.getString(_previousSessionsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final valid = <ClimbSessionModel>[];
      for (final item in list) {
        try {
          final m = ClimbSessionModel.fromJson(item as Map<String, dynamic>);
          if (isValidUuid(m.id)) {
            valid.add(m);
          }
        } catch (_) {}
      }
      if (valid.length != list.length) {
        await savePreviousSessions(valid);
      }
      return valid;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> savePreviousSessions(List<ClimbSessionModel> sessions) async {
    _purgeLegacyData();
    final validSessions = sessions.where((s) => isValidUuid(s.id)).toList();
    final jsonList = validSessions.map((s) => s.toJson()).toList();
    await _storage.setString(_previousSessionsKey, jsonEncode(jsonList));
  }

  @override
  Future<List<ClimbAnalysisSummaryModel>> getPreviousAnalyses() async {
    _purgeLegacyData();
    final raw = _storage.getString(_previousAnalysesKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final valid = <ClimbAnalysisSummaryModel>[];
      for (final item in list) {
        try {
          final m = ClimbAnalysisSummaryModel.fromJson(
            item as Map<String, dynamic>,
          );
          if (isValidUuid(m.id)) {
            valid.add(m);
          }
        } catch (_) {}
      }
      if (valid.length != list.length) {
        await savePreviousAnalyses(valid);
      }
      return valid;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> savePreviousAnalyses(
    List<ClimbAnalysisSummaryModel> analyses,
  ) async {
    _purgeLegacyData();
    final validAnalyses = analyses.where((a) => isValidUuid(a.id)).toList();
    final jsonList = validAnalyses.map((a) => a.toJson()).toList();
    await _storage.setString(_previousAnalysesKey, jsonEncode(jsonList));
  }

  @override
  Future<void> clear() async {
    _purgeLegacyData();
    await _storage.remove(_activeSessionKey);
    await _storage.remove(_previousSessionsKey);
    await _storage.remove(_previousAnalysesKey);
  }
}

final climbSessionLocalDataSourceProvider =
    Provider<ClimbSessionLocalDataSource>((ref) {
      final storage = ref.watch(localStorageServiceProvider);
      return ClimbSessionLocalDataSourceImpl(storage);
    });
