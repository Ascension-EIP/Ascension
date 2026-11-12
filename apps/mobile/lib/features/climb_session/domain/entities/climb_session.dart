// @date 2026-11-07
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
}

/// Summary representation of an analysis run.
class ClimbAnalysisSummary extends Equatable {
  const ClimbAnalysisSummary({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.createdAt,
    this.progressPercentage,
    this.remainingSeconds,
    this.authorName,
  });

  final String id;
  final String title;
  final AnalysisType type;
  final AnalysisStatus status;
  final DateTime createdAt;
  final int? progressPercentage;
  final int? remainingSeconds;
  final String? authorName;

  bool get isInProgress => status == AnalysisStatus.inProgress;
  bool get isCompleted => status == AnalysisStatus.completed;

  ClimbAnalysisSummary copyWith({
    String? id,
    String? title,
    AnalysisType? type,
    AnalysisStatus? status,
    DateTime? createdAt,
    int? progressPercentage,
    int? remainingSeconds,
    String? authorName,
  }) {
    return ClimbAnalysisSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
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
    progressPercentage,
    remainingSeconds,
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
    this.location,
    this.endedAt,
    this.analyses = const [],
    this.authorName,
  });

  final String id;
  final String name;
  final String? location;
  final ClimbSessionVisibility visibility;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<ClimbAnalysisSummary> analyses;
  final String? authorName;

  /// Whether the session is currently ongoing.
  bool get isActive => endedAt == null;

  /// Total duration elapsed (live if active, static if ended).
  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  ClimbSession copyWith({
    String? id,
    String? name,
    String? location,
    ClimbSessionVisibility? visibility,
    DateTime? startedAt,
    DateTime? endedAt,
    List<ClimbAnalysisSummary>? analyses,
    String? authorName,
  }) {
    return ClimbSession(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      visibility: visibility ?? this.visibility,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      analyses: analyses ?? this.analyses,
      authorName: authorName ?? this.authorName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    location,
    visibility,
    startedAt,
    endedAt,
    analyses,
    authorName,
  ];
}
