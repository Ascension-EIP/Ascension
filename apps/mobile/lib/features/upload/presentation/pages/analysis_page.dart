import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// ─── Landmark indices (mirrors pose_analysis.py LM class) ──────
class _LM {
  static const lShoulder = 11;
  static const rShoulder = 12;
  static const lElbow = 13;
  static const rElbow = 14;
  static const lWrist = 15;
  static const rWrist = 16;
  static const lHip = 23;
  static const rHip = 24;
  static const lKnee = 25;
  static const rKnee = 26;
  static const lAnkle = 27;
  static const rAnkle = 28;

  static const names = {
    11: 'Épaule G',
    12: 'Épaule D',
    13: 'Coude G',
    14: 'Coude D',
    15: 'Poignet G',
    16: 'Poignet D',
    23: 'Hanche G',
    24: 'Hanche D',
    25: 'Genou G',
    26: 'Genou D',
    27: 'Cheville G',
    28: 'Cheville D',
  };

  static const connections = [
    (_LM.lShoulder, _LM.rShoulder),
    (_LM.lShoulder, _LM.lElbow),
    (_LM.lElbow, _LM.lWrist),
    (_LM.rShoulder, _LM.rElbow),
    (_LM.rElbow, _LM.rWrist),
    (_LM.lShoulder, _LM.lHip),
    (_LM.rShoulder, _LM.rHip),
    (_LM.lHip, _LM.rHip),
    (_LM.lHip, _LM.lKnee),
    (_LM.lKnee, _LM.lAnkle),
    (_LM.rHip, _LM.rKnee),
    (_LM.rKnee, _LM.rAnkle),
  ];
}

// ─── Data model ─────────────────────────────────────────────────
class _FrameData {
  final int frameIndex;
  final int timestampMs;
  final bool poseDetected;
  final Map<int, Offset> landmarks; // key = LM id, value = (x, y) normalised
  final Map<int, double> angles; // key = LM id of joint

  const _FrameData({
    required this.frameIndex,
    required this.timestampMs,
    required this.poseDetected,
    required this.landmarks,
    required this.angles,
  });

  static _FrameData fromJson(Map<String, dynamic> json) {
    final landmarks = <int, Offset>{};
    final rawLm = json['landmarks'] as Map<String, dynamic>? ?? {};
    for (final e in rawLm.entries) {
      final id = int.tryParse(e.key);
      if (id == null) continue;
      final v = e.value as Map<String, dynamic>;
      landmarks[id] = Offset(
        (v['x'] as num).toDouble(),
        (v['y'] as num).toDouble(),
      );
    }

    final angles = <int, double>{};
    final rawAng = json['angles'] as Map<String, dynamic>? ?? {};
    for (final e in rawAng.entries) {
      final id = int.tryParse(e.key);
      if (id == null) continue;
      angles[id] = (e.value as num).toDouble();
    }

    return _FrameData(
      frameIndex: (json['frame'] as int?) ?? 0,
      timestampMs: (json['timestamp_ms'] as int?) ?? 0,
      poseDetected: (json['pose_detected'] as bool?) ?? false,
      landmarks: landmarks,
      angles: angles,
    );
  }
}

// ─── Page ────────────────────────────────────────────────────────
class AnalysisViewPage extends StatefulWidget {
  /// The raw `result_json` string returned by the server.
  final String resultJson;

  /// Optional processing time for the header.
  final int? processingMs;

  /// The local video file to show under the skeleton overlay.
  final File? videoFile;

  const AnalysisViewPage({
    super.key,
    required this.resultJson,
    this.processingMs,
    this.videoFile,
  });

  @override
  State<AnalysisViewPage> createState() => _AnalysisViewPageState();
}

class _AnalysisViewPageState extends State<AnalysisViewPage>
    with SingleTickerProviderStateMixin {
  late final List<_FrameData> _frames;
  late final TabController _tabCtrl;

  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  int _currentFrame = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);

    final parsed = jsonDecode(widget.resultJson) as Map<String, dynamic>;
    _frames = ((parsed['frames'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(_FrameData.fromJson)
        .toList();

    if (widget.videoFile != null) {
      _videoCtrl = VideoPlayerController.file(widget.videoFile!)
        ..initialize().then((_) {
          if (mounted) setState(() => _videoReady = true);
        });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  /// Seek the video to the timestamp of [frameIndex] without playing.
  void _seekVideoToFrame(int frameIndex) {
    if (_videoCtrl == null || !_videoReady) return;
    if (frameIndex < 0 || frameIndex >= _frames.length) return;
    final ms = _frames[frameIndex].timestampMs;
    _videoCtrl!.seekTo(Duration(milliseconds: ms));
  }

  void _play() {
    if (_frames.isEmpty) return;
    _videoCtrl?.play();
    setState(() => _isPlaying = true);
    _advanceFrame();
  }

  void _advanceFrame() async {
    while (_isPlaying && _currentFrame < _frames.length - 1) {
      await Future.delayed(const Duration(milliseconds: 66)); // ~15 fps
      if (!mounted) return;
      setState(() => _currentFrame++);
    }
    _videoCtrl?.pause();
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Text(
          'Visualisation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: accent,
          labelColor: accent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Squelette'),
            Tab(icon: Icon(Icons.show_chart), text: 'Angles'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Stats'),
          ],
        ),
      ),
      body: _frames.isEmpty
          ? const Center(
              child: Text(
                'Aucune donnée disponible',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _SkeletonTab(
                  frames: _frames,
                  currentIndex: _currentFrame,
                  isPlaying: _isPlaying,
                  accent: accent,
                  videoCtrl: _videoCtrl,
                  videoReady: _videoReady,
                  onFrameChanged: (i) {
                    setState(() => _currentFrame = i);
                    _seekVideoToFrame(i);
                  },
                  onPlay: _play,
                  onPause: () {
                    _videoCtrl?.pause();
                    setState(() => _isPlaying = false);
                  },
                  onReset: () {
                    _videoCtrl?.pause();
                    _seekVideoToFrame(0);
                    setState(() {
                      _isPlaying = false;
                      _currentFrame = 0;
                    });
                  },
                ),
                _AngleChartTab(frames: _frames, accent: accent),
                _StatsTab(
                  frames: _frames,
                  processingMs: widget.processingMs,
                  accent: accent,
                ),
              ],
            ),
    );
  }
}

// ─── Tab 1 — Skeleton viewer ────────────────────────────────────
class _SkeletonTab extends StatelessWidget {
  final List<_FrameData> frames;
  final int currentIndex;
  final bool isPlaying;
  final Color accent;
  final VideoPlayerController? videoCtrl;
  final bool videoReady;
  final ValueChanged<int> onFrameChanged;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReset;

  const _SkeletonTab({
    required this.frames,
    required this.currentIndex,
    required this.isPlaying,
    required this.accent,
    required this.onFrameChanged,
    required this.onPlay,
    required this.onPause,
    required this.onReset,
    this.videoCtrl,
    this.videoReady = false,
  });

  @override
  Widget build(BuildContext context) {
    final frame = frames[currentIndex];
    final hasVideo = videoCtrl != null && videoReady;

    return Column(
      children: [
        // ── Video + skeleton overlay ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFF0D1B2A),
                child: hasVideo
                    ? _VideoWithOverlay(
                        ctrl: videoCtrl!,
                        frame: frame,
                        accent: accent,
                      )
                    // No video file: show skeleton on plain background
                    : CustomPaint(
                        painter: _SkeletonPainter(
                          frame: frame,
                          accent: accent,
                          fullFrame: false,
                        ),
                        child: const SizedBox.expand(),
                      ),
              ),
            ),
          ),
        ),

        // ── Frame info ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Frame ${frame.frameIndex}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                _fmtMs(frame.timestampMs),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                frame.poseDetected ? '✅ Pose détectée' : '❌ Aucune pose',
                style: TextStyle(
                  color: frame.poseDetected ? accent : Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Scrubber ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              thumbColor: accent,
              inactiveTrackColor: Colors.white12,
              overlayColor: accent.withValues(alpha: 0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              min: 0,
              max: (frames.length - 1).toDouble(),
              value: currentIndex.toDouble(),
              onChanged: (v) => onFrameChanged(v.round()),
            ),
          ),
        ),

        // ── Controls ──
        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onReset,
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white70,
                ),
                iconSize: 32,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: currentIndex > 0
                    ? () => onFrameChanged(currentIndex - 1)
                    : null,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white70,
                ),
                iconSize: 36,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isPlaying ? onPause : onPlay,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: currentIndex < frames.length - 1
                    ? () => onFrameChanged(currentIndex + 1)
                    : null,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white70,
                ),
                iconSize: 36,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onFrameChanged(frames.length - 1),
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white70,
                ),
                iconSize: 32,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmtMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

// ─── Video + skeleton overlay widget ────────────────────────────
class _VideoWithOverlay extends StatelessWidget {
  final VideoPlayerController ctrl;
  final _FrameData frame;
  final Color accent;

  const _VideoWithOverlay({
    required this.ctrl,
    required this.frame,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final aspectRatio = ctrl.value.aspectRatio;
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Video layer ──
            VideoPlayer(ctrl),

            // ── Semi-transparent dark veil to make skeleton visible ──
            Container(color: Colors.black.withValues(alpha: 0.25)),

            // ── Skeleton overlay — ignores pointer so video gestures work ──
            IgnorePointer(
              child: CustomPaint(
                painter: _SkeletonPainter(
                  frame: frame,
                  accent: accent,
                  fullFrame: true, // use direct normalized → pixel mapping
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton CustomPainter ──────────────────────────────────────
class _SkeletonPainter extends CustomPainter {
  final _FrameData frame;
  final Color accent;

  /// When true, landmarks (already normalised 0-1 by MediaPipe) are mapped
  /// directly to pixel coordinates: x*width, y*height.  This is the correct
  /// mode when painting over a video that fills the full canvas.
  /// When false (no video), use auto-fit bounding-box centering.
  final bool fullFrame;

  const _SkeletonPainter({
    required this.frame,
    required this.accent,
    this.fullFrame = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!frame.poseDetected || frame.landmarks.isEmpty) {
      if (!fullFrame) {
        final tp = TextPainter(
          text: const TextSpan(
            text: 'Aucune pose détectée',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            size.width / 2 - tp.width / 2,
            size.height / 2 - tp.height / 2,
          ),
        );
      }
      return;
    }

    // Build the mapping function depending on mode
    final Offset Function(Offset) toCanvas;

    if (fullFrame) {
      // Direct mapping: MediaPipe normalized coords → pixel on the video rect
      toCanvas = (norm) => Offset(norm.dx * size.width, norm.dy * size.height);
    } else {
      // Auto-fit bounding box so skeleton is centered on a blank canvas
      final xs = frame.landmarks.values.map((o) => o.dx).toList();
      final ys = frame.landmarks.values.map((o) => o.dy).toList();
      final minX = xs.reduce(math.min);
      final maxX = xs.reduce(math.max);
      final minY = ys.reduce(math.min);
      final maxY = ys.reduce(math.max);
      final rangeX = (maxX - minX).clamp(0.01, 1.0);
      final rangeY = (maxY - minY).clamp(0.01, 1.0);
      const padding = 48.0;
      final drawW = size.width - padding * 2;
      final drawH = size.height - padding * 2;
      final scale = math.min(drawW / rangeX, drawH / rangeY);
      final offsetX = padding + (drawW - rangeX * scale) / 2;
      final offsetY = padding + (drawH - rangeY * scale) / 2;
      toCanvas = (norm) => Offset(
        offsetX + (norm.dx - minX) * scale,
        offsetY + (norm.dy - minY) * scale,
      );
    }

    // ── Connections ──
    final bonePaint = Paint()
      ..color = accent.withValues(alpha: 0.85)
      ..strokeWidth = fullFrame ? 3.5 : 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final (a, b) in _LM.connections) {
      final pA = frame.landmarks[a];
      final pB = frame.landmarks[b];
      if (pA == null || pB == null) continue;
      canvas.drawLine(toCanvas(pA), toCanvas(pB), bonePaint);
    }

    // ── Joints ──
    final jointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final jointOutline = Paint()
      ..color = accent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final entry in frame.landmarks.entries) {
      final pt = toCanvas(entry.value);
      canvas.drawCircle(pt, 5, jointPaint);
      canvas.drawCircle(pt, 5, jointOutline);
    }

    // ── Angle label at left elbow ──
    final elbowAngle = frame.angles[_LM.lElbow];
    final elbowPos = frame.landmarks[_LM.lElbow];
    if (elbowAngle != null && elbowPos != null) {
      final pt = toCanvas(elbowPos);
      final label = '${elbowAngle.toStringAsFixed(0)}°';

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Background pill
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pt.dx + 8, pt.dy - 10, tp.width + 8, tp.height + 4),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = const Color(0xFF162032).withValues(alpha: 0.85),
      );
      tp.paint(canvas, Offset(pt.dx + 12, pt.dy - 8));
    }
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) => old.frame != frame;
}

// ─── Tab 2 — Angle chart ────────────────────────────────────────
class _AngleChartTab extends StatefulWidget {
  final List<_FrameData> frames;
  final Color accent;
  const _AngleChartTab({required this.frames, required this.accent});

  @override
  State<_AngleChartTab> createState() => _AngleChartTabState();
}

class _AngleChartTabState extends State<_AngleChartTab> {
  // Build angle time-series for a given LM joint id
  List<FlSpot> _spots(int jointId) {
    final spots = <FlSpot>[];
    for (final f in widget.frames) {
      final angle = f.angles[jointId];
      if (angle != null) {
        spots.add(FlSpot(f.timestampMs / 1000.0, angle));
      }
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final lElbowSpots = _spots(_LM.lElbow);
    final rElbowSpots = _spots(_LM.rElbow);
    final hasData = lElbowSpots.isNotEmpty || rElbowSpots.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            'Angle des coudes dans le temps',
            accent: widget.accent,
          ),
          const SizedBox(height: 12),
          if (!hasData)
            _EmptyCard('Aucune donnée d\'angle disponible')
          else
            _ChartCard(
              child: LineChart(
                LineChartData(
                  backgroundColor: const Color(0xFF162032),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: Colors.white10, strokeWidth: 1),
                    getDrawingVerticalLine: (_) =>
                        FlLine(color: Colors.white10, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Angle (°)',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}°',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Temps (s)',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toStringAsFixed(0)}s',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    if (lElbowSpots.isNotEmpty)
                      LineChartBarData(
                        spots: lElbowSpots,
                        isCurved: true,
                        color: widget.accent,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: widget.accent.withValues(alpha: 0.08),
                        ),
                      ),
                    if (rElbowSpots.isNotEmpty)
                      LineChartBarData(
                        spots: rElbowSpots,
                        isCurved: true,
                        color: Colors.orangeAccent,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.orangeAccent.withValues(alpha: 0.08),
                        ),
                      ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1E3050),
                      getTooltipItems: (spots) => spots.map((s) {
                        return LineTooltipItem(
                          '${s.y.toStringAsFixed(1)}°',
                          TextStyle(
                            color: s.bar.color ?? Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Legend
          if (lElbowSpots.isNotEmpty || rElbowSpots.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (lElbowSpots.isNotEmpty)
                  _Legend(color: widget.accent, label: 'Coude gauche'),
                if (lElbowSpots.isNotEmpty && rElbowSpots.isNotEmpty)
                  const SizedBox(width: 24),
                if (rElbowSpots.isNotEmpty)
                  const _Legend(
                    color: Colors.orangeAccent,
                    label: 'Coude droit',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tab 3 — Stats ───────────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  final List<_FrameData> frames;
  final int? processingMs;
  final Color accent;

  const _StatsTab({
    required this.frames,
    required this.processingMs,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final detected = frames.where((f) => f.poseDetected).toList();
    final detRate = frames.isEmpty
        ? 0.0
        : detected.length / frames.length * 100;

    // Elbow angle stats
    final lAngles = frames
        .expand((f) => f.angles.entries)
        .where((e) => e.key == _LM.lElbow)
        .map((e) => e.value)
        .toList();

    double? lMin, lMax, lAvg;
    if (lAngles.isNotEmpty) {
      lMin = lAngles.reduce(math.min);
      lMax = lAngles.reduce(math.max);
      lAvg = lAngles.reduce((a, b) => a + b) / lAngles.length;
    }

    // Duration
    final durationMs = frames.isNotEmpty ? frames.last.timestampMs : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Résumé de la session', accent: accent),
          const SizedBox(height: 12),
          _StatCard(
            accent: accent,
            children: [
              _StatRow(
                'Durée analysée',
                _fmtMs(durationMs),
                icon: Icons.timer_outlined,
                accent: accent,
              ),
              _StatRow(
                'Frames analysées',
                '${frames.length}',
                icon: Icons.video_library_outlined,
                accent: accent,
              ),
              if (processingMs != null)
                _StatRow(
                  'Temps de traitement IA',
                  '${(processingMs! / 1000).toStringAsFixed(1)} s',
                  icon: Icons.memory_outlined,
                  accent: accent,
                ),
              _StatRow(
                'Taux de détection',
                '${detRate.toStringAsFixed(1)} %',
                icon: Icons.person_search_outlined,
                accent: accent,
                valueColor: detRate > 80
                    ? Colors.greenAccent
                    : detRate > 50
                    ? Colors.orangeAccent
                    : Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (lAngles.isNotEmpty) ...[
            _SectionTitle('Coude gauche', accent: accent),
            const SizedBox(height: 12),
            _StatCard(
              accent: accent,
              children: [
                _StatRow(
                  'Angle minimum',
                  '${lMin!.toStringAsFixed(1)}°',
                  icon: Icons.arrow_downward_rounded,
                  accent: accent,
                  valueColor: Colors.lightBlueAccent,
                ),
                _StatRow(
                  'Angle maximum',
                  '${lMax!.toStringAsFixed(1)}°',
                  icon: Icons.arrow_upward_rounded,
                  accent: accent,
                  valueColor: Colors.orangeAccent,
                ),
                _StatRow(
                  'Angle moyen',
                  '${lAvg!.toStringAsFixed(1)}°',
                  icon: Icons.show_chart,
                  accent: accent,
                ),
                _StatRow(
                  'Amplitude',
                  '${(lMax - lMin).toStringAsFixed(1)}°',
                  icon: Icons.swap_vert_rounded,
                  accent: accent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mini angle range bar
            _AngleRangeBar(min: lMin, max: lMax, avg: lAvg, accent: accent),
          ],
          const SizedBox(height: 20),
          _SectionTitle('Landmarks détectés', accent: accent),
          const SizedBox(height: 12),
          _LandmarkHeatmap(frames: frames, accent: accent),
        ],
      ),
    );
  }

  String _fmtMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

// ─── Shared widgets ──────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color accent;
  const _SectionTitle(this.text, {required this.accent});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: accent,
        fontWeight: FontWeight.bold,
        fontSize: 15,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final List<Widget> children;
  final Color accent;
  const _StatCard({required this.children, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color? valueColor;

  const _StatRow(
    this.label,
    this.value, {
    required this.icon,
    required this.accent,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white38, fontSize: 13),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}

class _AngleRangeBar extends StatelessWidget {
  final double min;
  final double max;
  final double avg;
  final Color accent;

  const _AngleRangeBar({
    required this.min,
    required this.max,
    required this.avg,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amplitude angulaire',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${min.toStringAsFixed(0)}°',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(height: 12, color: Colors.white10),
                      LayoutBuilder(
                        builder: (_, constraints) {
                          final total = math.max(max - min, 1.0);
                          final avgFrac = (avg - min) / total;
                          return CustomPaint(
                            size: Size(constraints.maxWidth, 12),
                            painter: _RangeBarPainter(
                              avgFrac: avgFrac,
                              accent: accent,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${max.toStringAsFixed(0)}°',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Moy. ${avg.toStringAsFixed(1)}°',
              style: TextStyle(color: accent, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeBarPainter extends CustomPainter {
  final double avgFrac;
  final Color accent;
  const _RangeBarPainter({required this.avgFrac, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient bar
    final grad = LinearGradient(
      colors: [Colors.lightBlueAccent, accent, Colors.orangeAccent],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = grad.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );
    // Avg marker
    final x = avgFrac.clamp(0.0, 1.0) * size.width;
    canvas.drawRect(
      Rect.fromLTWH(x - 1.5, -2, 3, size.height + 4),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_RangeBarPainter old) =>
      old.avgFrac != avgFrac || old.accent != accent;
}

class _LandmarkHeatmap extends StatelessWidget {
  final List<_FrameData> frames;
  final Color accent;
  const _LandmarkHeatmap({required this.frames, required this.accent});

  @override
  Widget build(BuildContext context) {
    // Count how many frames each landmark appears in
    final counts = <int, int>{};
    for (final f in frames) {
      for (final id in f.landmarks.keys) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    final total = frames.length.toDouble();

    final items = _LM.names.entries.toList()
      ..sort((a, b) => (counts[b.key] ?? 0).compareTo(counts[a.key] ?? 0));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: items.map((e) {
          final count = counts[e.key] ?? 0;
          final pct = total == 0 ? 0.0 : count / total;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    e.value,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(
                        pct > 0.8
                            ? Colors.greenAccent
                            : pct > 0.5
                            ? accent
                            : Colors.orangeAccent,
                      ),
                      minHeight: 7,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
