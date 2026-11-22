// @date 2026-11-21
// @file analysis_model.dart
// @brief Data models for video upload and pose analysis responses.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';

class VideoUploadUrlModel {
  const VideoUploadUrlModel({
    required this.videoId,
    required this.uploadUrl,
    required this.expiresAt,
  });

  final String videoId;
  final String uploadUrl;
  final DateTime expiresAt;

  factory VideoUploadUrlModel.fromJson(Map<String, dynamic> json) {
    return VideoUploadUrlModel(
      videoId: json['video_id'] as String? ?? json['id'] as String? ?? '',
      uploadUrl: json['upload_url'] as String? ?? '',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AnalysisResponseModel {
  const AnalysisResponseModel({
    required this.id,
    required this.videoId,
    required this.type,
    required this.status,
    required this.progress,
    this.result,
    this.error,
    this.processingTimeMs,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String videoId;
  final String type;
  final String status;
  final int progress;
  final PoseAnalysisResult? result;
  final String? error;
  final int? processingTimeMs;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isSuccess => status.toLowerCase() == 'success';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isInProgress => !isSuccess && !isFailed;

  factory AnalysisResponseModel.fromJson(Map<String, dynamic> json) {
    PoseAnalysisResult? parsedResult;
    if (json['result'] is Map<String, dynamic>) {
      parsedResult = _parseAnalysisResult(
        json['result'] as Map<String, dynamic>,
      );
    }

    return AnalysisResponseModel(
      id: json['id'] as String? ?? '',
      videoId: json['video_id'] as String? ?? '',
      type: json['type'] as String? ?? '2d',
      status: json['status'] as String? ?? 'pending',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      result: parsedResult,
      error: json['error'] as String?,
      processingTimeMs: (json['processing_time_ms'] as num?)?.toInt(),
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }

  static PoseAnalysisResult _parseAnalysisResult(Map<String, dynamic> map) {
    final fps = (map['fps'] as num?)?.toDouble() ?? 30.0;
    final width = (map['width'] as num?)?.toInt() ?? 1080;
    final height = (map['height'] as num?)?.toInt() ?? 1920;

    final framesList = <FramePose>[];
    if (map['frames'] is List) {
      for (final item in map['frames'] as List) {
        if (item is Map<String, dynamic>) {
          final frameNum = (item['frame'] as num?)?.toInt() ?? 0;
          final timestamp = (item['timestamp_ms'] as num?)?.toInt() ?? 0;
          final poseDetected = item['pose_detected'] as bool? ?? false;

          final landmarksMap = <String, PoseLandmarkPoint>{};
          if (item['landmarks'] is Map) {
            final rawLm = item['landmarks'] as Map<String, dynamic>;
            rawLm.forEach((key, val) {
              if (val is Map<String, dynamic>) {
                landmarksMap[key.toLowerCase()] = PoseLandmarkPoint(
                  x: (val['x'] as num?)?.toDouble() ?? 0.0,
                  y: (val['y'] as num?)?.toDouble() ?? 0.0,
                  z: (val['z'] as num?)?.toDouble() ?? 0.0,
                  visibility: (val['visibility'] as num?)?.toDouble() ?? 1.0,
                );
              }
            });
          }

          final anglesMap = <String, double>{};
          if (item['angles'] is Map) {
            (item['angles'] as Map).forEach((k, v) {
              if (v is num) anglesMap[k.toString()] = v.toDouble();
            });
          }

          SidesData? armExt;
          if (item['arm_extension'] is Map<String, dynamic>) {
            final m = item['arm_extension'] as Map<String, dynamic>;
            armExt = SidesData(
              left: (m['left'] as num?)?.toDouble(),
              right: (m['right'] as num?)?.toDouble(),
            );
          }

          Map<String, double>? speeds;
          if (item['speeds'] is Map) {
            speeds = {};
            (item['speeds'] as Map).forEach((k, v) {
              if (v is num) speeds![k.toString()] = v.toDouble();
            });
          }

          framesList.add(
            FramePose(
              frame: frameNum,
              timestampMs: timestamp,
              poseDetected: poseDetected,
              landmarks: landmarksMap,
              angles: anglesMap,
              armExtension: armExt,
              speeds: speeds,
            ),
          );
        }
      }
    }

    AnalysisMetrics? metrics;
    if (map['metrics'] is Map<String, dynamic>) {
      final m = map['metrics'] as Map<String, dynamic>;
      SidesData? armExt;
      if (m['avg_arm_extension'] is Map<String, dynamic>) {
        final a = m['avg_arm_extension'] as Map<String, dynamic>;
        armExt = SidesData(
          left: (a['left'] as num?)?.toDouble(),
          right: (a['right'] as num?)?.toDouble(),
        );
      }
      SidesData? bentRatio;
      if (m['bent_arm_ratio'] is Map<String, dynamic>) {
        final b = m['bent_arm_ratio'] as Map<String, dynamic>;
        bentRatio = SidesData(
          left: (b['left'] as num?)?.toDouble(),
          right: (b['right'] as num?)?.toDouble(),
        );
      }
      Map<String, double>? avgSpeed;
      if (m['avg_speed'] is Map) {
        avgSpeed = {};
        (m['avg_speed'] as Map).forEach((k, v) {
          if (v is num) avgSpeed![k.toString()] = v.toDouble();
        });
      }

      metrics = AnalysisMetrics(
        durationMs: (m['duration_ms'] as num?)?.toInt() ?? 0,
        poseDetectionRate:
            (m['pose_detection_rate'] as num?)?.toDouble() ?? 1.0,
        avgArmExtension: armExt,
        bentArmRatio: bentRatio,
        avgSpeed: avgSpeed,
      );
    }

    final movements = <AnalysisMovement>[];
    if (map['movements'] is List) {
      for (final mv in map['movements'] as List) {
        if (mv is Map<String, dynamic>) {
          movements.add(
            AnalysisMovement(
              limb: mv['limb'] as String? ?? '',
              startFrame: (mv['start_frame'] as num?)?.toInt() ?? 0,
              endFrame: (mv['end_frame'] as num?)?.toInt() ?? 0,
              startMs: (mv['start_ms'] as num?)?.toInt() ?? 0,
              endMs: (mv['end_ms'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      }
    }

    final pauses = <AnalysisPause>[];
    if (map['pauses'] is List) {
      for (final p in map['pauses'] as List) {
        if (p is Map<String, dynamic>) {
          pauses.add(
            AnalysisPause(
              startFrame: (p['start_frame'] as num?)?.toInt() ?? 0,
              endFrame: (p['end_frame'] as num?)?.toInt() ?? 0,
              startMs: (p['start_ms'] as num?)?.toInt() ?? 0,
              endMs: (p['end_ms'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      }
    }

    return PoseAnalysisResult(
      fps: fps,
      width: width,
      height: height,
      frames: framesList,
      metrics: metrics,
      movements: movements,
      pauses: pauses,
    );
  }
}

class AdviceResponseModel {
  const AdviceResponseModel({
    required this.id,
    required this.status,
    required this.progress,
    this.advice,
    this.error,
  });

  final String id;
  final String status;
  final int progress;
  final AnalysisAdvice? advice;
  final String? error;

  bool get isSuccess => status.toLowerCase() == 'success';

  factory AdviceResponseModel.fromJson(Map<String, dynamic> json) {
    AnalysisAdvice? parsedAdvice;
    if (json['result'] is Map<String, dynamic>) {
      final res = json['result'] as Map<String, dynamic>;
      final summary = res['summary'] as String? ?? '';
      final model = res['model'] as String? ?? 'gemini';
      final generatedAt = res['generated_at'] != null
          ? DateTime.tryParse(res['generated_at'] as String)
          : null;

      final items = <AdviceItem>[];
      if (res['items'] is List) {
        for (final it in res['items'] as List) {
          if (it is Map<String, dynamic>) {
            final zones = <String>[];
            if (it['body_zones'] is List) {
              for (final z in it['body_zones'] as List) {
                zones.add(z.toString());
              }
            }
            items.add(
              AdviceItem(
                title: it['title'] as String? ?? '',
                description: it['description'] as String? ?? '',
                category: it['category'] as String? ?? 'technique',
                priority: (it['priority'] as num?)?.toInt() ?? 1,
                bodyZones: zones,
                frameStart: (it['frame_start'] as num?)?.toInt(),
                frameEnd: (it['frame_end'] as num?)?.toInt(),
              ),
            );
          }
        }
      }

      parsedAdvice = AnalysisAdvice(
        id: json['id'] as String? ?? '',
        summary: summary,
        items: items,
        model: model,
        generatedAt: generatedAt,
      );
    }

    return AdviceResponseModel(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      advice: parsedAdvice,
      error: json['error'] as String?,
    );
  }
}
