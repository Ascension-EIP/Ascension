import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/accessibility/accessibility_announcer.dart';
import 'package:mobile/core/accessibility/accessibility_settings_service.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/features/upload/presentation/pages/analysis_page.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

/// video_player is only supported on Android, iOS, and Web.
bool get _supportsVideoPlayer =>
    !kIsWeb ? Platform.isAndroid || Platform.isIOS : true;

enum _UploadState { idle, selected, uploading, analysing, done, error }

// ─────────────────────────────────────────────────────────────────────────────
// Promotional messages displayed during analysis
// ─────────────────────────────────────────────────────────────────────────────

const List<_PromoMessage> _promoMessages = [
  _PromoMessage(
    icon: Icons.rocket_launch_rounded,
    textKey: 'video.promo.1',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.bolt_rounded,
    textKey: 'video.promo.2',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.stars_rounded,
    textKey: 'video.promo.3',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.history_rounded,
    textKey: 'video.promo.4',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.compare_arrows_rounded,
    textKey: 'video.promo.5',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.bar_chart_rounded,
    textKey: 'video.promo.6',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.tips_and_updates_rounded,
    textKey: 'video.promo.7',
    isPromo: false,
  ),
  _PromoMessage(
    icon: Icons.wb_sunny_rounded,
    textKey: 'video.promo.8',
    isPromo: false,
  ),
  _PromoMessage(
    icon: Icons.trending_up_rounded,
    textKey: 'video.promo.9',
    isPromo: false,
  ),
  _PromoMessage(
    icon: Icons.cloud_done_rounded,
    textKey: 'video.promo.10',
    isPromo: false,
  ),
  _PromoMessage(
    icon: Icons.people_rounded,
    textKey: 'video.promo.11',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.emoji_events_rounded,
    textKey: 'video.promo.12',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.psychology_rounded,
    textKey: 'video.promo.13',
    isPromo: false,
  ),
];

class _PromoMessage {
  final IconData icon;
  final String textKey;
  final bool isPromo;
  const _PromoMessage({
    required this.icon,
    required this.textKey,
    required this.isPromo,
  });
}

class VideoUpload extends StatefulWidget {
  const VideoUpload({super.key});

  @override
  State<VideoUpload> createState() => _VideoUploadState();
}

class _VideoUploadState extends State<VideoUpload> {
  final AccessibilitySettingsService _a11y = AccessibilitySettingsService();

  _UploadState _state = _UploadState.idle;
  File? _videoFile;
  VideoPlayerController? _playerController;
  double _uploadProgress = 0;
  String? _errorMessage;
  Map<String, dynamic>? _analysisResult;

  // Analysis progress tracking
  int _analysisProgress = 0; // real value 0–100 from the API
  DateTime? _analysisStartedAt; // when the analysing phase began
  bool _isGeneratingHints = false; // true while the server runs Gemini
  static const int _analysisMaxPolls = 120; // 120 × 5 s = 10 min

  Future<void> _pickVideo(ImageSource source) async {
    XFile? picked = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 10),
    );
    if (picked == null) return;

    final file = File(picked.path);

    VideoPlayerController? controller;
    if (_supportsVideoPlayer) {
      controller = VideoPlayerController.file(file);
      await controller.initialize();
    }

    setState(() {
      _videoFile = file;
      _playerController?.dispose();
      _playerController = controller;
      _state = _UploadState.selected;
    });
    if (!mounted) return;
    AccessibilityAnnouncer.announce(
      context,
      AppLocalizations.of(context).t('video.announceSelected'),
    );
  }

  Future<void> _upload() async {
    final localizations = AppLocalizations.of(context);

    setState(() {
      _state = _UploadState.uploading;
      _uploadProgress = 0;
      _errorMessage = null;
    });
    AccessibilityAnnouncer.announce(
      context,
      localizations.t('video.announceUploading'),
    );

    try {
      final file = _videoFile!;
      final filename = file.path.split('/').last;
      final api = ApiService();

      // 1. Get presigned PUT URL from backend
      setState(() => _uploadProgress = 0.1);
      final userId = AuthService().userId;
      if (userId == null) {
        throw Exception(localizations.t('video.errorNotLoggedIn'));
      }
      final urlData = await api.getUploadUrl(
        filename: filename,
        userId: userId,
      );
      final videoId = urlData['video_id'] as String;
      final uploadUrl = urlData['upload_url'] as String;

      // 2. Upload directly to MinIO
      setState(() => _uploadProgress = 0.3);
      final bytes = await file.readAsBytes();
      final contentType = _mimeFromFilename(filename);
      await api.uploadToMinio(
        uploadUrl: uploadUrl,
        fileBytes: bytes,
        contentType: contentType,
      );
      setState(() => _uploadProgress = 0.6);

      // 3. Trigger analysis
      setState(() {
        _state = _UploadState.analysing;
        _analysisProgress = 0;
        _analysisStartedAt = DateTime.now();
      });
      if (!mounted) return;
      AccessibilityAnnouncer.announce(
        context,
        localizations.t('video.announceAnalysing'),
      );
      final analysisData = await api.triggerAnalysis(videoId: videoId);
      final analysisId = analysisData['analysis_id'] as String;

      // 4. Poll until completed or failed (up to ~10 minutes).
      // A `failed` status seen in the first 30 s may be a stale result from a
      // previous attempt on the same video — keep waiting until the worker
      // picks up the new job and updates the status.
      Map<String, dynamic>? result;
      for (int i = 0; i < _analysisMaxPolls; i++) {
        await Future.delayed(const Duration(seconds: 5));
        final a = await api.getAnalysis(analysisId);
        final status = a['status'] as String;
        // Read the real progress written by the AI worker.
        final rawProgress = a['progress'];
        int? nextProgress;
        bool? nextIsGeneratingHints;
        if (rawProgress is int) {
          nextProgress = rawProgress;
        }
        // Show a dedicated spinner while Gemini is generating coaching hints.
        if (status == 'generating_hints') {
          nextIsGeneratingHints = true;
        } else if (_isGeneratingHints && status != 'generating_hints') {
          // Gemini finished — revert to normal display
          nextIsGeneratingHints = false;
        }
        if (nextProgress != null || nextIsGeneratingHints != null) {
          setState(() {
            if (nextProgress != null) {
              _analysisProgress = nextProgress;
            }
            if (nextIsGeneratingHints != null) {
              _isGeneratingHints = nextIsGeneratingHints;
            }
          });
        }
        if (status == 'completed') {
          result = a;
          break;
        }
        // Accept `failed` only after 30 s so that a fresh worker run has had
        // time to update the status from a previously-failed attempt.
        if (status == 'failed' && i >= 6) {
          result = a;
          break;
        }
      }

      if (result == null) {
        throw Exception(localizations.t('video.timeoutError'));
      }

      // Save to local history (userId is guaranteed non-null at this point)
      final createdAtRaw = result['created_at'] as String?;
      final completedAtRaw = result['completed_at'] as String?;
      final historyEntry = AnalysisHistoryEntry(
        analysisId: result['id'] as String? ?? '',
        createdAt: createdAtRaw != null
            ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
            : DateTime.now(),
        completedAt: completedAtRaw != null
            ? DateTime.tryParse(completedAtRaw)
            : null,
        processingTimeMs: result['processing_time_ms'] as int?,
        resultJson: result['result_json'] as String?,
        status: result['status'] as String? ?? 'unknown',
      );
      await AnalysisHistoryService().saveEntry(userId, historyEntry);

      setState(() {
        _analysisResult = result;
        _state = _UploadState.done;
      });
      if (!mounted) return;
      AccessibilityAnnouncer.announce(
        context,
        localizations.t('video.announceDone'),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _state = _UploadState.error;
      });
      if (!mounted) return;
      AccessibilityAnnouncer.announce(
        context,
        localizations.t('video.announceError'),
      );
    }
  }

  String _mimeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }

  void _reset() {
    _playerController?.dispose();
    setState(() {
      _state = _UploadState.idle;
      _videoFile = null;
      _playerController = null;
      _uploadProgress = 0;
      _errorMessage = null;
      _analysisResult = null;
      _analysisProgress = 0;
      _analysisStartedAt = null;
      _isGeneratingHints = false;
    });
  }

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _UploadState.idle => _buildIdle(),
      _UploadState.selected => _buildSelected(),
      _UploadState.uploading => _buildUploading(),
      _UploadState.analysing => _buildAnalysing(),
      _UploadState.done => _buildDone(),
      _UploadState.error => _buildError(),
    };
  }

  Widget _buildIdle() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 72,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('video.pickOrRecord'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _PickerButton(
                  icon: Icons.videocam_rounded,
                  label: l10n.t('video.record'),
                  onTap: () => _pickVideo(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PickerButton(
                  icon: Icons.photo_library_rounded,
                  label: l10n.t('video.import'),
                  onTap: () => _pickVideo(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelected() {
    final l10n = AppLocalizations.of(context);
    final controller = _playerController;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: controller != null
                ? GestureDetector(
                    onTap: () => setState(() {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    }),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: VideoPlayer(controller),
                          ),
                          ValueListenableBuilder(
                            valueListenable: controller,
                            builder: (_, value, _) {
                              final playIndicator = Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(16),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              );

                              if (_a11y.reducedMotion) {
                                return value.isPlaying
                                    ? const SizedBox.shrink()
                                    : playIndicator;
                              }

                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: value.isPlaying ? 0 : 1,
                                child: playIndicator,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_file_rounded,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _videoFile?.path.split('/').last ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.t('video.previewUnavailable'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          if (_videoFile != null)
            Text(
              _videoFile!.path.split('/').last,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.close_rounded),
                label: Text(AppLocalizations.of(context).t('profile.cancel')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _upload,
                  icon: const Icon(Icons.upload_rounded),
                  label: Text(l10n.t('video.analyze')),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploading() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.tr('video.uploadingProgress', {
                'progress': '${(_uploadProgress * 100).toInt()}',
              }),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                color: Theme.of(context).colorScheme.secondary,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysing() {
    // While Gemini is generating hints, lock the display at 99 %.
    final int percent = _isGeneratingHints ? 99 : _analysisProgress;
    final double progress = percent / 100.0;

    // Compute ETA from elapsed time and current speed.
    // Only shown once we have at least 2 % progress to avoid wild estimates.
    // Hidden during the Gemini phase (we can't estimate Gemini duration).
    String remainingLabel = AppLocalizations.of(
      context,
    ).t('video.remainingCalculating');
    final started = _analysisStartedAt;
    if (!_isGeneratingHints && started != null && percent >= 2) {
      final elapsedSecs = DateTime.now().difference(started).inSeconds;
      final remainingSecs = (elapsedSecs / percent * (100 - percent)).round();
      remainingLabel = _formatRemaining(
        AppLocalizations.of(context),
        remainingSecs,
      );
    }

    return _AnalysingScreen(
      progress: progress,
      percent: percent,
      remainingLabel: remainingLabel,
      isGeneratingHints: _isGeneratingHints,
      reducedMotion: _a11y.reducedMotion,
    );
  }

  static String _formatRemaining(AppLocalizations l10n, int seconds) {
    if (seconds <= 0) return l10n.t('video.remainingSoon');
    if (seconds < 60) return '~$seconds s';
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return sec == 0
        ? '~$min min'
        : '~${min}m${sec.toString().padLeft(2, '0')}s';
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 72, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              l10n.t('video.errorTitle'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? l10n.t('video.errorUnknown'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _reset,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: Text(l10n.t('video.retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone() {
    final l10n = AppLocalizations.of(context);
    final result = _analysisResult;
    final status = result?['status'] as String? ?? '—';
    final processingMs = result?['processing_time_ms'] as int?;
    final resultJson = result?['result_json'] as String?;
    final hints = result?['hints'] as String?;

    // Parse frame count from JSON if available
    int? frameCount;
    if (resultJson != null) {
      try {
        final parsed = jsonDecode(resultJson) as Map<String, dynamic>;
        frameCount = (parsed['frames'] as List?)?.length;
      } catch (_) {}
    }

    final isCompleted = status == 'completed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 80,
            color: isCompleted
                ? Theme.of(context).colorScheme.secondary
                : Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            isCompleted
                ? l10n.t('video.doneSuccess')
                : l10n.t('video.doneFailed'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (processingMs != null)
            Text(
              l10n.tr('video.processingTime', {
                'seconds': (processingMs / 1000).toStringAsFixed(1),
              }),
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          if (frameCount != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.tr('video.framesAnalyzed', {'count': '$frameCount'}),
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
          const SizedBox(height: 24),
          if (resultJson != null && isCompleted)
            _AnalysisSummaryCard(resultJson: resultJson),
          const SizedBox(height: 24),
          // ── Visualiser button (only when analysis succeeded) ──
          if (resultJson != null && isCompleted) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AnalysisViewPage(
                        resultJson: resultJson,
                        processingMs: processingMs,
                        videoFile: _videoFile,
                        hints: hints,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: Text(l10n.t('video.viewAnalysis')),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.t('video.analyzeAnother')),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisSummaryCard extends StatelessWidget {
  final String resultJson;
  const _AnalysisSummaryCard({required this.resultJson});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(resultJson) as Map<String, dynamic>;
    } catch (_) {
      return const SizedBox.shrink();
    }

    final frames = (data['frames'] as List?) ?? [];
    final detectedFrames = frames
        .where((f) => f['pose_detected'] == true)
        .length;
    final detectionRate = frames.isEmpty
        ? 0.0
        : detectedFrames / frames.length * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('video.results'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: l10n.t('video.totalFrames'),
            value: '${frames.length}',
          ),
          _StatRow(
            label: l10n.t('video.poseDetected'),
            value:
                '$detectedFrames frames (${detectionRate.toStringAsFixed(0)} %)',
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: label,
      hint: l10n.tr('video.tapHint', {'action': label}),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00B5D3),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnalysingScreen — shown while the AI processes the video
// ─────────────────────────────────────────────────────────────────────────────

class _AnalysingScreen extends StatefulWidget {
  final double progress;
  final int percent;
  final String remainingLabel;
  final bool isGeneratingHints;
  final bool reducedMotion;

  const _AnalysingScreen({
    required this.progress,
    required this.percent,
    required this.remainingLabel,
    this.isGeneratingHints = false,
    this.reducedMotion = false,
  });

  @override
  State<_AnalysingScreen> createState() => _AnalysingScreenState();
}

class _AnalysingScreenState extends State<_AnalysingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageCtrl;
  late AnimationController _autoSlideCtrl;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    // Auto-advance timer: drives a thin progress bar and flips the page when full.
    _autoSlideCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              _nextPage();
              _autoSlideCtrl.forward(from: 0);
            }
          });
    if (!widget.reducedMotion) {
      _autoSlideCtrl.forward();
    }
  }

  void _nextPage() {
    _goToPage((_pageIndex + 1) % _promoMessages.length);
  }

  void _goToPage(int index) {
    setState(() => _pageIndex = index);
    if (widget.reducedMotion) {
      _pageCtrl.jumpToPage(index);
      return;
    }
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoSlideCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Circular progress with percentage ──
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: widget.isGeneratingHints
                        ? null
                        : (widget.progress > 0 ? widget.progress : null),
                    color: colorScheme.secondary,
                    backgroundColor: colorScheme.secondary.withValues(
                      alpha: 0.15,
                    ),
                    strokeWidth: 8,
                  ),
                ),
                if (!widget.isGeneratingHints)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.percent} %',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                      Text(
                        widget.remainingLabel,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: colorScheme.secondary,
                    size: 32,
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              widget.isGeneratingHints
                  ? l10n.t('video.generatingHints')
                  : l10n.t('video.analysisInProgress'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isGeneratingHints
                  ? l10n.t('video.generatingHintsSubtitle')
                  : l10n.t('video.analysisSubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 28),

            // ── Swipeable promo / tips cards ──
            Row(
              children: [
                //_NavArrow(
                //  onTap: () {
                //    _autoSlideCtrl.forward(from: 0);
                //    _goToPage(
                //      (_pageIndex - 1 + _promoMessages.length) %
                //          _promoMessages.length,
                //    );
                //  },
                //  icon: Icons.chevron_left_rounded,
                //  accent: colorScheme.secondary,
                //),
                const SizedBox(width: 4),
                Expanded(
                  child: SizedBox(
                    height: 85,
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: _promoMessages.length,
                      onPageChanged: (i) {
                        setState(() => _pageIndex = i);
                        if (!widget.reducedMotion) {
                          _autoSlideCtrl.forward(from: 0);
                        }
                      },
                      itemBuilder: (context, i) => Padding(
                        // Horizontal gap between cards when paging
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _PromoCard(
                          msg: _promoMessages[i],
                          accent: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
                //_NavArrow(
                //  onTap: () {
                //    _autoSlideCtrl.forward(from: 0);
                //    _nextPage();
                //  },
                //  icon: Icons.chevron_right_rounded,
                //  accent: colorScheme.secondary,
                //),
              ],
            ),

            // ── Dot indicators (tappable) ──
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _promoMessages.length,
                (i) => Semantics(
                  button: true,
                  label: l10n.tr('video.tip', {'index': '${i + 1}'}),
                  selected: i == _pageIndex,
                  child: InkWell(
                    onTap: () {
                      if (!widget.reducedMotion) {
                        _autoSlideCtrl.forward(from: 0);
                      }
                      _goToPage(i);
                    },
                    child: AnimatedContainer(
                      duration: widget.reducedMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _pageIndex ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _pageIndex
                            ? colorScheme.secondary
                            : Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Thin auto-advance progress bar ──
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _autoSlideCtrl,
              builder: (context, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.reducedMotion ? 0 : _autoSlideCtrl.value,
                  color: colorScheme.secondary.withValues(alpha: 0.5),
                  backgroundColor: colorScheme.secondary.withValues(alpha: 0.1),
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small left/right arrow button used beside the swipeable promo cards.
// ignore: unused_element
class _NavArrow extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color accent;
  const _NavArrow({
    required this.onTap,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 20, color: accent.withValues(alpha: 0.7)),
      ),
    );
  }
}

/// A single promotional / tips card shown inside the PageView.
class _PromoCard extends StatelessWidget {
  final _PromoMessage msg;
  final Color accent;
  const _PromoCard({required this.msg, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: msg.isPromo
            ? accent.withValues(alpha: 0.10)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: msg.isPromo
              ? accent.withValues(alpha: 0.35)
              : Colors.grey.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            msg.icon,
            size: 26,
            color: msg.isPromo ? accent : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.isPromo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      l10n.t('video.promoBadge'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                Text(
                  l10n.t(msg.textKey),
                  style: TextStyle(
                    fontSize: 13,
                    color: msg.isPromo ? Colors.white : Colors.grey[400],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
