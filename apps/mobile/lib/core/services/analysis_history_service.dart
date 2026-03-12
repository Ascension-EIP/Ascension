import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AnalysisHistoryEntry {
  final String analysisId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? processingTimeMs;
  final String? resultJson;
  final String status;

  const AnalysisHistoryEntry({
    required this.analysisId,
    required this.createdAt,
    this.completedAt,
    this.processingTimeMs,
    this.resultJson,
    required this.status,
  });

  bool get isCompleted => status == 'completed';

  int get frameCount {
    if (resultJson == null) return 0;
    try {
      final data = jsonDecode(resultJson!) as Map<String, dynamic>;
      return (data['frames'] as List?)?.length ?? 0;
    } catch (_) {
      return 0;
    }
  }

  double get detectionRate {
    if (resultJson == null) return 0;
    try {
      final data = jsonDecode(resultJson!) as Map<String, dynamic>;
      final frames = (data['frames'] as List?) ?? [];
      if (frames.isEmpty) return 0;
      final detected = frames.where((f) => f['pose_detected'] == true).length;
      return detected / frames.length * 100;
    } catch (_) {
      return 0;
    }
  }

  Map<String, dynamic> toJson() => {
    'analysisId': analysisId,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'processingTimeMs': processingTimeMs,
    'resultJson': resultJson,
    'status': status,
  };

  factory AnalysisHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AnalysisHistoryEntry(
      analysisId: json['analysisId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      processingTimeMs: json['processingTimeMs'] as int?,
      resultJson: json['resultJson'] as String?,
      status: json['status'] as String,
    );
  }
}

class AnalysisHistoryService {
  static final AnalysisHistoryService _instance =
      AnalysisHistoryService._internal();
  factory AnalysisHistoryService() => _instance;
  AnalysisHistoryService._internal();

  static const String _keyPrefix = 'analysis_history_';

  String _key(String userId) => '$_keyPrefix$userId';

  Future<List<AnalysisHistoryEntry>> getHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => AnalysisHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEntry(String userId, AnalysisHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getHistory(userId);
    final updated = existing
        .where((e) => e.analysisId != entry.analysisId)
        .toList();
    updated.add(entry);
    await prefs.setString(
      _key(userId),
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }
}
