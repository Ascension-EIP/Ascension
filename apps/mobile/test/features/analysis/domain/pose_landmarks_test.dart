// @date 2026-11-21
// @file pose_landmarks_test.dart
// @brief Unit tests for MediaPipe pose landmarks and analysis models.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analysis/data/models/analysis_model.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';

void main() {
  group('PoseLandmarkPoint and MediaPipe Skeleton Tests', () {
    test('PoseLandmarkPoint equality and props', () {
      const p1 = PoseLandmarkPoint(x: 0.5, y: 0.8, z: 0.1, visibility: 0.95);
      const p2 = PoseLandmarkPoint(x: 0.5, y: 0.8, z: 0.1, visibility: 0.95);
      const p3 = PoseLandmarkPoint(x: 0.2, y: 0.3, z: 0.0, visibility: 1.0);

      expect(p1, equals(p2));
      expect(p1 == p3, isFalse);
    });

    test('MediaPipeConnections contains standard limb connections', () {
      const connections = MediaPipeConnections.connections;
      expect(connections, isNotEmpty);
      expect(connections, contains(('left_shoulder', 'right_shoulder')));
      expect(connections, contains(('left_shoulder', 'left_elbow')));
      expect(connections, contains(('left_elbow', 'left_wrist')));
      expect(connections, contains(('left_hip', 'left_knee')));
    });

    test('PoseAnalysisResult getFrameAtTimestamp returns closest frame', () {
      const frame1 = FramePose(
        frame: 0,
        timestampMs: 0,
        poseDetected: true,
        landmarks: {'nose': PoseLandmarkPoint(x: 0.5, y: 0.2)},
      );
      const frame2 = FramePose(
        frame: 30,
        timestampMs: 1000,
        poseDetected: true,
        landmarks: {'nose': PoseLandmarkPoint(x: 0.52, y: 0.21)},
      );
      const frame3 = FramePose(
        frame: 60,
        timestampMs: 2000,
        poseDetected: true,
        landmarks: {'nose': PoseLandmarkPoint(x: 0.55, y: 0.25)},
      );

      const result = PoseAnalysisResult(
        fps: 30.0,
        width: 1080,
        height: 1920,
        frames: [frame1, frame2, frame3],
      );

      // Boundaries
      expect(result.getFrameAtTimestamp(-100), equals(frame1));
      expect(result.getFrameAtTimestamp(0), equals(frame1));
      expect(result.getFrameAtTimestamp(2500), equals(frame3));

      // Intermediate
      expect(result.getFrameAtTimestamp(400), equals(frame1));
      expect(result.getFrameAtTimestamp(600), equals(frame2));
      expect(result.getFrameAtTimestamp(1600), equals(frame3));
    });
  });

  group('AnalysisResponseModel JSON Deserialization Tests', () {
    test('parses full analysis response with metrics and movements', () {
      final json = {
        'id': 'analysis-uuid-123',
        'video_id': 'video-uuid-456',
        'type': '2d',
        'status': 'success',
        'progress': 100,
        'result': {
          'fps': 30.0,
          'width': 1080,
          'height': 1920,
          'frames': [
            {
              'frame': 0,
              'timestamp_ms': 0,
              'pose_detected': true,
              'landmarks': {
                'left_shoulder': {
                  'x': 0.45,
                  'y': 0.35,
                  'z': 0.05,
                  'visibility': 0.99,
                },
                'right_shoulder': {
                  'x': 0.55,
                  'y': 0.35,
                  'z': 0.05,
                  'visibility': 0.98,
                },
              },
              'angles': {'left_elbow': 135.0},
              'arm_extension': {'left': 0.85, 'right': 0.82},
              'speeds': {'left_wrist': 0.42},
            },
          ],
          'metrics': {
            'duration_ms': 12000,
            'pose_detection_rate': 0.98,
            'avg_arm_extension': {'left': 0.82, 'right': 0.79},
            'bent_arm_ratio': {'left': 0.35, 'right': 0.40},
            'avg_speed': {'left_wrist': 0.45, 'right_wrist': 0.50},
          },
          'movements': [
            {
              'limb': 'left_hand',
              'start_frame': 10,
              'end_frame': 40,
              'start_ms': 333,
              'end_ms': 1333,
            },
          ],
          'pauses': [
            {
              'start_frame': 45,
              'end_frame': 80,
              'start_ms': 1500,
              'end_ms': 2666,
            },
          ],
        },
      };

      final model = AnalysisResponseModel.fromJson(json);

      expect(model.id, equals('analysis-uuid-123'));
      expect(model.videoId, equals('video-uuid-456'));
      expect(model.isSuccess, isTrue);
      expect(model.progress, equals(100));

      final result = model.result;
      expect(result, isNotNull);
      expect(result!.fps, equals(30.0));
      expect(result.frames.length, equals(1));
      expect(result.frames.first.poseDetected, isTrue);
      expect(
        result.frames.first.landmarks['left_shoulder']?.x,
        closeTo(0.45, 0.001),
      );
      expect(result.metrics?.durationMs, equals(12000));
      expect(result.metrics?.poseDetectionRate, closeTo(0.98, 0.001));
      expect(result.movements.length, equals(1));
      expect(result.movements.first.limb, equals('left_hand'));
      expect(result.pauses.length, equals(1));
      expect(result.pauses.first.durationMs, equals(1166));
    });

    test('parses AdviceResponseModel JSON', () {
      final json = {
        'id': 'advice-uuid-789',
        'status': 'success',
        'progress': 100,
        'result': {
          'summary': 'Bonne coordination globale, attention au verrouillage.',
          'model': 'gemini-1.5-pro',
          'items': [
            {
              'title': 'Bras tendus',
              'description':
                  'Gardez les bras plus tendus pour économiser l\'énergie.',
              'category': 'technique',
              'priority': 1,
              'body_zones': ['left_elbow', 'right_elbow'],
              'frame_start': 10,
              'frame_end': 50,
            },
          ],
        },
      };

      final model = AdviceResponseModel.fromJson(json);
      expect(model.isSuccess, isTrue);
      expect(model.advice, isNotNull);
      expect(
        model.advice!.summary,
        equals('Bonne coordination globale, attention au verrouillage.'),
      );
      expect(model.advice!.items.length, equals(1));
      expect(model.advice!.items.first.title, equals('Bras tendus'));
      expect(model.advice!.items.first.category, equals('technique'));
      expect(model.advice!.items.first.priority, equals(1));
      expect(
        model.advice!.items.first.bodyZones,
        containsAll(['left_elbow', 'right_elbow']),
      );
    });
  });
}
