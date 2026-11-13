// @date 2026-11-13
// @file climb_session.dart
// @brief Domain entities for climbing sessions and analysis summaries.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:equatable/equatable.dart';

/// Visibility scope for a climbing session.
enum ClimbSessionVisibility {
  public,
  friends,
  private;

  String get translationKey {
    switch (this) {
      case ClimbSessionVisibility.public:
        return 'sessions.visibility.public';
      case ClimbSessionVisibility.friends:
        return 'sessions.visibility.friends';
      case ClimbSessionVisibility.private:
        return 'sessions.visibility.private';
    }
  }

  String get label {
    switch (this) {
      case ClimbSessionVisibility.public:
        return 'Publique';
      case ClimbSessionVisibility.friends:
        return 'Amis';
      case ClimbSessionVisibility.private:
        return 'Privée';
    }
  }

  static ClimbSessionVisibility fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'public':
        return ClimbSessionVisibility.public;
      case 'friends':
        return ClimbSessionVisibility.friends;
      case 'private':
      default:
        return ClimbSessionVisibility.private;
    }
  }
}

/// Analysis type categorized in Ascension.
enum AnalysisType {
  pose2d,
  pose3d,
  ghostMode,
  assistedClimbing;

  String get translationKey {
    switch (this) {
      case AnalysisType.pose2d:
        return 'sessions.analysisPose2dTitle';
      case AnalysisType.pose3d:
        return 'sessions.analysisPose3dTitle';
      case AnalysisType.ghostMode:
        return 'sessions.analysisGhostTitle';
      case AnalysisType.assistedClimbing:
        return 'sessions.analysisAssistedTitle';
    }
  }

  String get displayName {
    switch (this) {
      case AnalysisType.pose2d:
        return 'Analyse de pose 2D';
      case AnalysisType.pose3d:
        return 'Analyse de pose 3D';
      case AnalysisType.ghostMode:
        return 'Mode fantôme';
      case AnalysisType.assistedClimbing:
        return 'Grimpe assistée';
    }
  }

  String get apiValue {
    switch (this) {
      case AnalysisType.pose2d:
        return '2d';
      case AnalysisType.pose3d:
        return '3d';
      case AnalysisType.ghostMode:
        return 'ghost';
      case AnalysisType.assistedClimbing:
        return 'assisted';
    }
  }

  static AnalysisType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case '2d':
      case 'pose2d':
        return AnalysisType.pose2d;
      case '3d':
      case 'pose3d':
        return AnalysisType.pose3d;
      case 'ghost':
      case 'ghostmode':
        return AnalysisType.ghostMode;
      case 'assisted':
      case 'assistedclimbing':
        return AnalysisType.assistedClimbing;
      default:
        return AnalysisType.pose2d;
    }
  }
}

/// Status of an analysis within a session or standalone.
enum AnalysisStatus {
  inProgress,
  completed,
  failed;

  String get translationKey {
    switch (this) {
      case AnalysisStatus.inProgress:
        return 'sessions.status.inProgress';
      case AnalysisStatus.completed:
        return 'sessions.status.completed';
      case AnalysisStatus.failed:
        return 'sessions.status.failed';
    }
  }

  String get label {
    switch (this) {
      case AnalysisStatus.inProgress:
        return 'En cours';
      case AnalysisStatus.completed:
        return 'Terminée';
      case AnalysisStatus.failed:
        return 'Échouée';
    }
  }

  String get apiValue {
    switch (this) {
      case AnalysisStatus.inProgress:
        return 'running';
      case AnalysisStatus.completed:
        return 'success';
      case AnalysisStatus.failed:
        return 'failed';
    }
  }

  static AnalysisStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
      case 'started':
      case 'running':
      case 'inprogress':
        return AnalysisStatus.inProgress;
      case 'success':
      case 'completed':
        return AnalysisStatus.completed;
      case 'failed':
        return AnalysisStatus.failed;
      default:
        return AnalysisStatus.completed;
    }
  }
}

/// Summary representation of an analysis run.
class ClimbAnalysisSummary extends Equatable {
  const ClimbAnalysisSummary({
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

  final String id;
  final String title;
  final AnalysisType type;
  final AnalysisStatus status;
  final DateTime createdAt;
  final String? videoId;
  final String? climbingSessionId;
  final int? progressPercentage;
  final int? remainingSeconds;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? authorName;

  bool get isInProgress => status == AnalysisStatus.inProgress;
  bool get isCompleted => status == AnalysisStatus.completed;

  ClimbAnalysisSummary copyWith({
    String? id,
    String? title,
    AnalysisType? type,
    AnalysisStatus? status,
    DateTime? createdAt,
    String? videoId,
    String? climbingSessionId,
    int? progressPercentage,
    int? remainingSeconds,
    DateTime? startedAt,
    DateTime? completedAt,
    String? authorName,
  }) {
    return ClimbAnalysisSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      videoId: videoId ?? this.videoId,
      climbingSessionId: climbingSessionId ?? this.climbingSessionId,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      authorName: authorName ?? this.authorName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    type,
    status,
    createdAt,
    videoId,
    climbingSessionId,
    progressPercentage,
    remainingSeconds,
    startedAt,
    completedAt,
    authorName,
  ];
}

/// Domain entity representing a climbing session.
class ClimbSession extends Equatable {
  const ClimbSession({
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

  final String id;
  final String name;
  final String? gymId;
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
  final List<ClimbAnalysisSummary> analyses;
  final String? authorName;

  /// Whether the session is currently ongoing.
  bool get isActive => endedAt == null;

  /// Total duration elapsed (live if active, static if ended).
  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  ClimbSession copyWith({
    String? id,
    String? name,
    String? gymId,
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
    List<ClimbAnalysisSummary>? analyses,
    String? authorName,
  }) {
    return ClimbSession(
      id: id ?? this.id,
      name: name ?? this.name,
      gymId: gymId ?? this.gymId,
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

  @override
  List<Object?> get props => [
    id,
    name,
    gymId,
    location,
    notes,
    visibility,
    startedAt,
    endedAt,
    overallScore,
    techniqueScore,
    powerScore,
    enduranceScore,
    scoredAt,
    createdAt,
    updatedAt,
    analyses,
    authorName,
  ];
}
