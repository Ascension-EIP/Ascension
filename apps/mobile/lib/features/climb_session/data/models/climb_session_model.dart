// @date 2026-11-13
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
    this.videoId,
    this.climbingSessionId,
    this.progressPercentage,
    this.remainingSeconds,
    this.startedAt,
    this.completedAt,
    this.authorName,
  });

  factory ClimbAnalysisSummaryModel.fromJson(Map<String, dynamic> json) {
    final type = AnalysisType.fromString(json['type'] as String?);
    final status = AnalysisStatus.fromString(json['status'] as String?);
    final title = (json['title'] as String?)?.isNotEmpty == true
        ? json['title'] as String
        : type.displayName;

    return ClimbAnalysisSummaryModel(
      id: json['id'] as String,
      videoId: json['video_id'] as String?,
      climbingSessionId: json['climbing_session_id'] as String?,
      title: title,
      type: type,
      status: status,
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      progressPercentage:
          (json['progress'] as num?)?.toInt() ??
          (json['progress_percentage'] as num?)?.toInt(),
      remainingSeconds: (json['remaining_seconds'] as num?)?.toInt(),
      authorName: json['author_name'] as String?,
    );
  }

  factory ClimbAnalysisSummaryModel.fromEntity(ClimbAnalysisSummary entity) {
    return ClimbAnalysisSummaryModel(
      id: entity.id,
      videoId: entity.videoId,
      climbingSessionId: entity.climbingSessionId,
      title: entity.title,
      type: entity.type,
      status: entity.status,
      createdAt: entity.createdAt,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      progressPercentage: entity.progressPercentage,
      remainingSeconds: entity.remainingSeconds,
      authorName: entity.authorName,
    );
  }

  final String id;
  final String? videoId;
  final String? climbingSessionId;
  final String title;
  final AnalysisType type;
  final AnalysisStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? progressPercentage;
  final int? remainingSeconds;
  final String? authorName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (videoId != null) 'video_id': videoId,
      if (climbingSessionId != null) 'climbing_session_id': climbingSessionId,
      'title': title,
      'type': type.apiValue,
      'status': status.apiValue,
      'created_at': createdAt.toIso8601String(),
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (progressPercentage != null) 'progress': progressPercentage,
      if (remainingSeconds != null) 'remaining_seconds': remainingSeconds,
      if (authorName != null) 'author_name': authorName,
    };
  }

  ClimbAnalysisSummary toEntity() {
    return ClimbAnalysisSummary(
      id: id,
      videoId: videoId,
      climbingSessionId: climbingSessionId,
      title: title,
      type: type,
      status: status,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
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
    this.gymId,
    this.location,
    this.notes,
    this.endedAt,
    this.overallScore,
    this.techniqueScore,
    this.powerScore,
    this.enduranceScore,
    this.scoredAt,
    this.createdAt,
    this.updatedAt,
    this.analyses = const [],
    this.authorName,
  });

  factory ClimbSessionModel.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?)?.trim();
    final name = (title != null && title.isNotEmpty)
        ? title
        : (json['name'] as String?) ?? 'Session';
    final notes = json['notes'] as String?;
    final location = (json['location'] as String?) ?? notes;

    return ClimbSessionModel(
      id: json['id'] as String,
      gymId: json['gym_id'] as String?,
      name: name,
      location: location,
      notes: notes,
      visibility: ClimbSessionVisibility.fromString(
        json['visibility'] as String?,
      ),
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      overallScore: (json['overall_score'] as num?)?.toDouble(),
      techniqueScore: (json['technique_score'] as num?)?.toDouble(),
      powerScore: (json['power_score'] as num?)?.toDouble(),
      enduranceScore: (json['endurance_score'] as num?)?.toDouble(),
      scoredAt: json['scored_at'] != null
          ? DateTime.parse(json['scored_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
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
      gymId: entity.gymId,
      name: entity.name,
      location: entity.location,
      notes: entity.notes,
      visibility: entity.visibility,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      overallScore: entity.overallScore,
      techniqueScore: entity.techniqueScore,
      powerScore: entity.powerScore,
      enduranceScore: entity.enduranceScore,
      scoredAt: entity.scoredAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      analyses: entity.analyses
          .map((a) => ClimbAnalysisSummaryModel.fromEntity(a))
          .toList(),
      authorName: entity.authorName,
    );
  }

  final String id;
  final String? gymId;
  final String name;
  final String? location;
  final String? notes;
  final ClimbSessionVisibility visibility;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? overallScore;
  final double? techniqueScore;
  final double? powerScore;
  final double? enduranceScore;
  final DateTime? scoredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ClimbAnalysisSummaryModel> analyses;
  final String? authorName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (gymId != null) 'gym_id': gymId,
      'title': name,
      'name': name,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      'visibility': visibility.name,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      if (overallScore != null) 'overall_score': overallScore,
      if (techniqueScore != null) 'technique_score': techniqueScore,
      if (powerScore != null) 'power_score': powerScore,
      if (enduranceScore != null) 'endurance_score': enduranceScore,
      if (scoredAt != null) 'scored_at': scoredAt?.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
      'analyses': analyses.map((a) => a.toJson()).toList(),
      if (authorName != null) 'author_name': authorName,
    };
  }

  ClimbSessionModel copyWith({
    String? id,
    String? gymId,
    String? name,
    String? location,
    String? notes,
    ClimbSessionVisibility? visibility,
    DateTime? startedAt,
    DateTime? endedAt,
    double? overallScore,
    double? techniqueScore,
    double? powerScore,
    double? enduranceScore,
    DateTime? scoredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ClimbAnalysisSummaryModel>? analyses,
    String? authorName,
  }) {
    return ClimbSessionModel(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      name: name ?? this.name,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      visibility: visibility ?? this.visibility,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      overallScore: overallScore ?? this.overallScore,
      techniqueScore: techniqueScore ?? this.techniqueScore,
      powerScore: powerScore ?? this.powerScore,
      enduranceScore: enduranceScore ?? this.enduranceScore,
      scoredAt: scoredAt ?? this.scoredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      analyses: analyses ?? this.analyses,
      authorName: authorName ?? this.authorName,
    );
  }

  ClimbSession toEntity() {
    return ClimbSession(
      id: id,
      gymId: gymId,
      name: name,
      location: location,
      notes: notes,
      visibility: visibility,
      startedAt: startedAt,
      endedAt: endedAt,
      overallScore: overallScore,
      techniqueScore: techniqueScore,
      powerScore: powerScore,
      enduranceScore: enduranceScore,
      scoredAt: scoredAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      analyses: analyses.map((a) => a.toEntity()).toList(),
      authorName: authorName,
    );
  }
}

/// Paginated climbing sessions response.
class ClimbingSessionListResponseModel {
  const ClimbingSessionListResponseModel({
    required this.sessions,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ClimbingSessionListResponseModel.fromJson(Map<String, dynamic> json) {
    return ClimbingSessionListResponseModel(
      sessions:
          (json['sessions'] as List<dynamic>?)
              ?.map(
                (item) =>
                    ClimbSessionModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }

  final List<ClimbSessionModel> sessions;
  final int total;
  final int limit;
  final int offset;
}

/// Paginated analysis summaries response.
class AnalysisListResponseModel {
  const AnalysisListResponseModel({
    required this.analyses,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory AnalysisListResponseModel.fromJson(Map<String, dynamic> json) {
    return AnalysisListResponseModel(
      analyses:
          (json['analyses'] as List<dynamic>?)
              ?.map(
                (item) => ClimbAnalysisSummaryModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }

  final List<ClimbAnalysisSummaryModel> analyses;
  final int total;
  final int limit;
  final int offset;
}
