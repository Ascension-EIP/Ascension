// @date 2026-11-21
// @file video_analysis_player.dart
// @brief Interactive video player with synchronized MediaPipe skeleton overlay and analysis controls.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
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
    this.maxVideoHeight,
  }) : assert(
         videoFile != null || videoUrl != null,
         'Must provide either videoFile or videoUrl',
       );

  final File? videoFile;
  final String? videoUrl;
  final PoseAnalysisResult? analysisResult;
  final bool initialPlay;
  final double? maxVideoHeight;

  @override
  State<VideoAnalysisPlayer> createState() => _VideoAnalysisPlayerState();
}

class _VideoAnalysisPlayerState extends State<VideoAnalysisPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showSkeleton = true;
  final bool _showAngles = true;
  double _playbackSpeed = 1.0;
  FramePose? _currentFramePose;
  double? _dragPositionMs;

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
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final currentMs = _controller.value.position.inMilliseconds;
    final newPose = widget.analysisResult?.getFrameAtTimestamp(currentMs);

    setState(() {
      _currentFramePose = newPose;
    });
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.removeListener(_onControllerUpdate);
    }
    try {
      _controller.dispose();
    } catch (_) {}
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
    if (_hasError) {
      return FCard(
        child: SizedBox(
          height: 240,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.theme.colors.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FLucideIcons.videoOff,
                      size: 28,
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.tr('analysis.videoPlaybackErrorTitle'),
                    textAlign: TextAlign.center,
                    style: context.theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('analysis.videoPlaybackErrorDesc'),
                    textAlign: TextAlign.center,
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.03);
    }

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
    final displayPosition = _dragPositionMs != null
        ? Duration(milliseconds: _dragPositionMs!.toInt())
        : position;

    Widget videoContent = ClipRRect(
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

              // Edge Rendering Skeleton Overlay (only when analysis result is present)
              if (widget.analysisResult != null)
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

              // Overlay Badge: pose detection indicator (only when analysis result is present)
              if (widget.analysisResult != null)
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
                              ? context.tr('analysis.poseActive')
                              : context.tr('analysis.outOfFrame'),
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
    );

    if (widget.maxVideoHeight != null) {
      videoContent = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxVideoHeight!),
          child: videoContent,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Video viewport
        videoContent,

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
            value: (_dragPositionMs ?? position.inMilliseconds.toDouble())
                .clamp(
                  0,
                  duration.inMilliseconds.toDouble() > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1.0,
                ),
            onChangeStart: (val) {
              setState(() {
                _dragPositionMs = val;
              });
            },
            onChanged: (val) {
              setState(() {
                _dragPositionMs = val;
              });
              _controller.seekTo(Duration(milliseconds: val.toInt()));
            },
            onChangeEnd: (val) {
              _controller.seekTo(Duration(milliseconds: val.toInt()));
              setState(() {
                _dragPositionMs = null;
              });
            },
          ),
        ),

        // Controls bar: Play/Pause, timestamps, speed, Skeleton toggle (if analyzed)
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
                '${_formatDuration(displayPosition)} / ${_formatDuration(duration)}',
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

              // Skeleton toggle button (only shown when analysisResult is present)
              if (widget.analysisResult != null) ...[
                const SizedBox(width: 8),
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
                          context.tr('analysis.skeletonToggle'),
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
            ],
          ),
        ),
      ],
    );
  }
}
