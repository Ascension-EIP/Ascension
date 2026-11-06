// @date 2026-11-06
// @file climb_session_model.dart
// @brief Data transfer models for climbing sessions and analyses.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';

/// Data model for [ClimbAnalysisSummary] with JSON serialization.
class ClimbAnalysisSummaryModel {
  const ClimbAnalysisSummaryModel({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.createdAt,
    this.progressPercentage,
    this.remainingSeconds,
    this.authorName,
  });

  factory ClimbAnalysisSummaryModel.fromJson(Map<String, dynamic> json) {
    return ClimbAnalysisSummaryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: AnalysisType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnalysisType.pose2d,
      ),
      status: AnalysisStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AnalysisStatus.completed,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      progressPercentage: json['progress_percentage'] as int?,
      remainingSeconds: json['remaining_seconds'] as int?,
      authorName: json['author_name'] as String?,
    );
  }

  factory ClimbAnalysisSummaryModel.fromEntity(ClimbAnalysisSummary entity) {
    return ClimbAnalysisSummaryModel(
      id: entity.id,
      title: entity.title,
      type: entity.type,
      status: entity.status,
      createdAt: entity.createdAt,
      progressPercentage: entity.progressPercentage,
      remainingSeconds: entity.remainingSeconds,
      authorName: entity.authorName,
    );
  }

  final String id;
  final String title;
  final AnalysisType type;
  final AnalysisStatus status;
  final DateTime createdAt;
  final int? progressPercentage;
  final int? remainingSeconds;
  final String? authorName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'progress_percentage': progressPercentage,
      'remaining_seconds': remainingSeconds,
      'author_name': authorName,
    };
  }

  ClimbAnalysisSummary toEntity() {
    return ClimbAnalysisSummary(
      id: id,
      title: title,
      type: type,
      status: status,
      createdAt: createdAt,
      progressPercentage: progressPercentage,
      remainingSeconds: remainingSeconds,
      authorName: authorName,
    );
  }
}

/// Data model for [ClimbSession] with JSON serialization.
class ClimbSessionModel {
  const ClimbSessionModel({
    required this.id,
    required this.name,
    required this.visibility,
    required this.startedAt,
    this.location,
    this.endedAt,
    this.analyses = const [],
    this.authorName,
  });

  factory ClimbSessionModel.fromJson(Map<String, dynamic> json) {
    return ClimbSessionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      visibility: ClimbSessionVisibility.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => ClimbSessionVisibility.private,
      ),
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      analyses:
          (json['analyses'] as List<dynamic>?)
              ?.map(
                (item) => ClimbAnalysisSummaryModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      authorName: json['author_name'] as String?,
    );
  }

  factory ClimbSessionModel.fromEntity(ClimbSession entity) {
    return ClimbSessionModel(
      id: entity.id,
      name: entity.name,
      location: entity.location,
      visibility: entity.visibility,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      analyses: entity.analyses
          .map((a) => ClimbAnalysisSummaryModel.fromEntity(a))
          .toList(),
      authorName: entity.authorName,
    );
  }

  final String id;
  final String name;
  final String? location;
  final ClimbSessionVisibility visibility;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<ClimbAnalysisSummaryModel> analyses;
  final String? authorName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'visibility': visibility.name,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'analyses': analyses.map((a) => a.toJson()).toList(),
      'author_name': authorName,
    };
  }

  ClimbSession toEntity() {
    return ClimbSession(
      id: id,
      name: name,
      location: location,
      visibility: visibility,
      startedAt: startedAt,
      endedAt: endedAt,
      analyses: analyses.map((a) => a.toEntity()).toList(),
      authorName: authorName,
    );
  }
}
