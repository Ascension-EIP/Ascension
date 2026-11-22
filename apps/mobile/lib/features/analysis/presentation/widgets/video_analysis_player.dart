// @date 2026-11-21
// @file video_analysis_player.dart
// @brief Interactive video player with synchronized MediaPipe skeleton overlay and analysis controls.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mobile/features/analysis/domain/entities/pose_landmarks.dart';
import 'package:mobile/features/analysis/presentation/widgets/media_pipe_skeleton_painter.dart';
import 'package:video_player/video_player.dart';

class VideoAnalysisPlayer extends StatefulWidget {
  const VideoAnalysisPlayer({
    super.key,
    this.videoFile,
    this.videoUrl,
    this.analysisResult,
    this.initialPlay = true,
  }) : assert(
         videoFile != null || videoUrl != null,
         'Must provide either videoFile or videoUrl',
       );

  final File? videoFile;
  final String? videoUrl;
  final PoseAnalysisResult? analysisResult;
  final bool initialPlay;

  @override
  State<VideoAnalysisPlayer> createState() => _VideoAnalysisPlayerState();
}

class _VideoAnalysisPlayerState extends State<VideoAnalysisPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showSkeleton = true;
  final bool _showAngles = true;
  double _playbackSpeed = 1.0;
  FramePose? _currentFramePose;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.videoFile != null) {
      _controller = VideoPlayerController.file(widget.videoFile!);
    } else {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl!),
      );
    }

    try {
      await _controller.initialize();
      _controller.addListener(_onControllerUpdate);
      if (widget.initialPlay) {
        await _controller.play();
      }
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final currentMs = _controller.value.position.inMilliseconds;
    final newPose = widget.analysisResult?.getFrameAtTimestamp(currentMs);

    if (newPose != _currentFramePose || _controller.value.isPlaying) {
      setState(() {
        _currentFramePose = newPose;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        if (_controller.value.position >= _controller.value.duration) {
          _controller.seekTo(Duration.zero);
        }
        _controller.play();
      }
    });
  }

  void _cycleSpeed() {
    final speeds = [0.5, 1.0, 1.5];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    setState(() {
      _playbackSpeed = speeds[nextIndex];
      _controller.setPlaybackSpeed(_playbackSpeed);
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final videoSize = _controller.value.size;
    final isPlaying = _controller.value.isPlaying;
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Video viewport with skeleton overlay
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio > 0
                  ? _controller.value.aspectRatio
                  : 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video stream
                  VideoPlayer(_controller),

                  // Edge Rendering Skeleton Overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: MediaPipeSkeletonPainter(
                        framePose: _currentFramePose,
                        videoOriginalSize: videoSize,
                        showSkeleton: _showSkeleton,
                        showJoints: true,
                        showAngles: _showAngles,
                      ),
                    ),
                  ),

                  // Overlay Badge: pose detection indicator
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _currentFramePose?.poseDetected == true
                              ? const Color(0xFF00E5FF)
                              : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentFramePose?.poseDetected == true
                                ? FLucideIcons.activity
                                : FLucideIcons.userX,
                            size: 14,
                            color: _currentFramePose?.poseDetected == true
                                ? const Color(0xFF00E5FF)
                                : Colors.white60,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentFramePose?.poseDetected == true
                                ? 'Pose active'
                                : 'Hors cadre',
                            style: context.theme.typography.body.xs.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tap to toggle play/pause directly on video
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _togglePlayPause,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Timeline Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: context.theme.colors.primary,
            inactiveTrackColor: context.theme.colors.muted,
            thumbColor: context.theme.colors.primary,
          ),
          child: Slider(
            min: 0,
            max: duration.inMilliseconds.toDouble() > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0,
            value: position.inMilliseconds.toDouble().clamp(
              0,
              duration.inMilliseconds.toDouble(),
            ),
            onChanged: (val) {
              _controller.seekTo(Duration(milliseconds: val.toInt()));
            },
          ),
        ),

        // Controls bar: Play/Pause, timestamps, Skeleton toggle, angles toggle, speed
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              // Play / Pause button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.theme.colors.muted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? FLucideIcons.pause : FLucideIcons.play,
                    size: 18,
                    color: context.theme.colors.primary,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Time indicator
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: context.theme.typography.body.xs.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.theme.colors.mutedForeground,
                ),
              ),

              const Spacer(),

              // Speed selector
              GestureDetector(
                onTap: _cycleSpeed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.theme.colors.muted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_playbackSpeed}x',
                    style: context.theme.typography.body.xs.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Skeleton toggle button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showSkeleton = !_showSkeleton;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _showSkeleton
                        ? context.theme.colors.primary.withValues(alpha: 0.15)
                        : context.theme.colors.muted,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _showSkeleton
                          ? context.theme.colors.primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FLucideIcons.personStanding,
                        size: 14,
                        color: _showSkeleton
                            ? context.theme.colors.primary
                            : context.theme.colors.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Squelette',
                        style: context.theme.typography.body.xs.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _showSkeleton
                              ? context.theme.colors.primary
                              : context.theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
