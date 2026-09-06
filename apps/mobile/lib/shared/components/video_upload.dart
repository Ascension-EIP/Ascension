// @date 2026-09-07
// @file video_upload.dart
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
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
    icon: FLucideIcons.rocket,
    textKey: 'video.promo.1',
    isPromo: true,
  ),
  _PromoMessage(
    icon: FLucideIcons.bolt,
    textKey: 'video.promo.2',
    isPromo: true,
  ),
  _PromoMessage(
    icon: FLucideIcons.sparkles,
    textKey: 'video.promo.3',
    isPromo: true,
  ),
  _PromoMessage(
    icon: FLucideIcons.history,
    textKey: 'video.promo.4',
    isPromo: true,
  ),
  _PromoMessage(
    icon: FLucideIcons.arrowLeftRight,
    textKey: 'video.promo.5',
    isPromo: true,
  ),
  _PromoMessage(
    icon: FLucideIcons.chartColumn,
    textKey: 'video.promo.6',
    isPromo: true,
  ),
  _PromoMessage(
    icon: FLucideIcons.lightbulb,
    textKey: 'video.promo.7',
    isPromo: false,
  ),
  _PromoMessage(
    icon: FLucideIcons.sun,
    textKey: 'video.promo.8',
    isPromo: false,
  ),
  _PromoMessage(
    icon: FLucideIcons.trendingUp,
    textKey: 'video.promo.9',
    isPromo: false,
  ),
  _PromoMessage(
    icon: FLucideIcons.cloudCheck,
    textKey: 'video.promo.10',
    isPromo: false,
  ),
  _PromoMessage(
    icon: FLucideIcons.users,
    textKey: 'video.promo.11',
    isPromo: true,
  ),
  _PromoMessage(
    icon: FLucideIcons.trophy,
    textKey: 'video.promo.12',
    isPromo: true,
  ),
  _PromoMessage(
    icon: FLucideIcons.brain,
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
        processingTimeMs: result['processing_time'] as int?,
        resultJson: result['result'] as String?,
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
    final content = switch (_state) {
      _UploadState.idle => _buildIdle(),
      _UploadState.selected => _buildSelected(),
      _UploadState.uploading => _buildUploading(),
      _UploadState.analysing => _buildAnalysing(),
      _UploadState.done => _buildDone(),
      _UploadState.error => _buildError(),
    };
    return content
        .animate(key: ValueKey(_state))
        .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildIdle() {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: FCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(
                      FLucideIcons.video,
                      size: 72,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.t('video.pickOrRecord'),
                      textAlign: TextAlign.center,
                      style: typo.body.md,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _PickerButton(
                  icon: FLucideIcons.camera,
                  label: l10n.t('video.record'),
                  onTap: () => _pickVideo(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PickerButton(
                  icon: FLucideIcons.images,
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
    final colors = context.theme.colors;
    final typo = context.theme.typography;
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
                                  FLucideIcons.play,
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
                          FLucideIcons.fileVideo,
                          size: 80,
                          color: colors.mutedForeground,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _videoFile?.path.split('/').last ?? '',
                          textAlign: TextAlign.center,
                          style: typo.body.md,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.t('video.previewUnavailable'),
                          style: typo.body.sm,
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          if (_videoFile != null)
            Text(
              _videoFile!.path.split('/').last,
              style: typo.body.sm,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              FButton(
                variant: .outline,
                onPress: _reset,
                prefix: const Icon(FLucideIcons.x),
                child: Text(AppLocalizations.of(context).t('profile.cancel')),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FButton(
                  onPress: _upload,
                  prefix: const Icon(FLucideIcons.upload),
                  child: Text(l10n.t('video.analyze')),
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
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              color: colors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.tr('video.uploadingProgress', {
                'progress': '${(_uploadProgress * 100).toInt()}',
              }),
              style: typo.display.lg.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            FDeterminateProgress(value: _uploadProgress.clamp(0.0, 1.0)),
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
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FLucideIcons.circleAlert, size: 72, color: colors.destructive),
            const SizedBox(height: 16),
            Text(
              l10n.t('video.errorTitle'),
              style: typo.display.lg.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? l10n.t('video.errorUnknown'),
              textAlign: TextAlign.center,
              style: typo.body.sm,
            ),
            const SizedBox(height: 32),
            FButton(onPress: _reset, child: Text(l10n.t('video.retry'))),
          ],
        ),
      ),
    );
  }

  Widget _buildDone() {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final result = _analysisResult;
    final status = result?['status'] as String? ?? '—';
    final processingMs = result?['processing_time'] as int?;
    final resultJson = result?['result'] as String?;
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
            isCompleted ? FLucideIcons.circleCheck : FLucideIcons.circleX,
            size: 80,
            color: isCompleted ? colors.primary : colors.destructive,
          ),
          const SizedBox(height: 16),
          Text(
            isCompleted
                ? l10n.t('video.doneSuccess')
                : l10n.t('video.doneFailed'),
            style: typo.display.xl2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (processingMs != null)
            Text(
              l10n.tr('video.processingTime', {
                'seconds': (processingMs / 1000).toStringAsFixed(1),
              }),
              style: typo.body.sm.copyWith(color: colors.mutedForeground),
            ),
          if (frameCount != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.tr('video.framesAnalyzed', {'count': '$frameCount'}),
              style: typo.body.sm.copyWith(color: colors.mutedForeground),
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
              child: FButton(
                prefix: const Icon(FLucideIcons.circlePlay),
                onPress: () {
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
                child: Text(l10n.t('video.viewAnalysis')),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: FButton(
              variant: .outline,
              onPress: _reset,
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
    final colors = context.theme.colors;
    final typo = context.theme.typography;
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

    return SizedBox(
      width: double.infinity,
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('video.results'),
                style: typo.body.md.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
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
        ),
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
    final typo = context.theme.typography;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typo.body.sm),
          Text(
            value,
            style: typo.body.sm.copyWith(fontWeight: FontWeight.w600),
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
    final colors = context.theme.colors;
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
            border: Border.all(color: colors.primary, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 36, color: colors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: context.theme.typography.body.md.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
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
    final colors = context.theme.colors;
    final typo = context.theme.typography;

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
                    color: colors.secondary,
                    backgroundColor: colors.secondary.withValues(alpha: 0.15),
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
                          color: colors.secondary,
                        ),
                      ),
                      Text(widget.remainingLabel, style: typo.body.sm),
                    ],
                  )
                else
                  Icon(
                    FLucideIcons.sparkles,
                    color: colors.secondary,
                    size: 32,
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              widget.isGeneratingHints
                  ? l10n.t('video.generatingHints')
                  : l10n.t('video.analysisInProgress'),
              style: typo.display.xl,
            ),
            const SizedBox(height: 6),
            Text(
              widget.isGeneratingHints
                  ? l10n.t('video.generatingHintsSubtitle')
                  : l10n.t('video.analysisSubtitle'),
              textAlign: TextAlign.center,
              style: typo.body.md.copyWith(color: colors.mutedForeground),
            ),
            const SizedBox(height: 28),

            // ── Swipeable promo / tips cards ──
            Row(
              children: [
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
                          accent: colors.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
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
                            ? colors.secondary
                            : colors.mutedForeground.withValues(alpha: 0.35),
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
              builder: (context, _) => FDeterminateProgress(
                value: (widget.reducedMotion ? 0.0 : _autoSlideCtrl.value)
                    .clamp(0.0, 1.0),
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
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: msg.isPromo ? accent.withValues(alpha: 0.10) : colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: msg.isPromo ? accent.withValues(alpha: 0.35) : colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            msg.icon,
            size: 26,
            color: msg.isPromo ? accent : colors.mutedForeground,
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
                  style: typo.body.sm.copyWith(
                    color: msg.isPromo
                        ? colors.foreground
                        : colors.mutedForeground,
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
