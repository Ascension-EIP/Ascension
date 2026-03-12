import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/features/upload/presentation/pages/analysis_page.dart';

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
    text: 'Le mode Premium réduit le temps d\'analyse de 3×.',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.bolt_rounded,
    text: 'Avec Premium, vos analyses passent en tête de file.',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.stars_rounded,
    text: 'Passez au mode Premium pour seulement 4,99 €/mois.',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.history_rounded,
    text: 'Premium : accédez à tout l\'historique de vos sessions.',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.compare_arrows_rounded,
    text: 'Comparez vos sessions côte à côte avec le mode Premium.',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.bar_chart_rounded,
    text: 'Premium débloque des statistiques avancées par groupe musculaire.',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.tips_and_updates_rounded,
    text:
        'Le saviez-vous ? MediaPipe détecte jusqu\'à 33 points du corps humain.',
    isPromo: false,
  ),
  _PromoMessage(
    icon: Icons.videocam_rounded,
    text: 'Astuce : filmez de profil pour de meilleures détections.',
    isPromo: false,
  ),
  _PromoMessage(
    icon: Icons.wb_sunny_rounded,
    text: 'Astuce : un bon éclairage améliore la précision des landmarks.',
    isPromo: false,
  ),
  _PromoMessage(
    icon: Icons.trending_up_rounded,
    text: 'Votre progression est analysée image par image.',
    isPromo: false,
  ),
  _PromoMessage(
    icon: Icons.cloud_done_rounded,
    text: 'Vos données sont stockées de façon sécurisée dans le cloud.',
    isPromo: false,
  ),
  _PromoMessage(
    icon: Icons.people_rounded,
    text: 'Premium : partagez vos analyses avec votre coach en un tap.',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.emoji_events_rounded,
    text: 'Premium : recevez des objectifs personnalisés chaque semaine.',
    isPromo: true,
  ),
  _PromoMessage(
    icon: Icons.psychology_rounded,
    text:
        'L\'IA Ascension apprend de chaque session pour mieux vous conseiller.',
    isPromo: false,
  ),
  _PromoMessage(
    icon: Icons.offline_bolt_rounded,
    text: 'Premium : analyses disponibles même hors connexion (bientôt).',
    isPromo: true,
  ),
];

class _PromoMessage {
  final IconData icon;
  final String text;
  final bool isPromo;
  const _PromoMessage({
    required this.icon,
    required this.text,
    required this.isPromo,
  });
}

class VideoUpload extends StatefulWidget {
  const VideoUpload({super.key});

  @override
  State<VideoUpload> createState() => _VideoUploadState();
}

class _VideoUploadState extends State<VideoUpload> {
  _UploadState _state = _UploadState.idle;
  File? _videoFile;
  VideoPlayerController? _playerController;
  double _uploadProgress = 0;
  String? _errorMessage;
  Map<String, dynamic>? _analysisResult;

  // Analysis progress tracking
  int _analysisProgress = 0; // real value 0–100 from the API
  DateTime? _analysisStartedAt; // when the analysing phase began
  static const int _analysisMaxPolls = 120; // 120 × 5 s = 10 min

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await ImagePicker().pickVideo(
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
  }

  Future<void> _upload() async {
    setState(() {
      _state = _UploadState.uploading;
      _uploadProgress = 0;
      _errorMessage = null;
    });

    try {
      final file = _videoFile!;
      final filename = file.path.split('/').last;
      final api = ApiService();

      // 1. Get presigned PUT URL from backend
      setState(() => _uploadProgress = 0.1);
      final userId = AuthService().userId;
      if (userId == null) throw Exception('User not logged in');
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
        if (rawProgress is int) {
          setState(() => _analysisProgress = rawProgress);
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
        throw Exception(
          'L\'analyse a dépassé le délai d\'attente (10 min). '
          'Vérifiez l\'état du worker et réessayez.',
        );
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
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _state = _UploadState.error;
      });
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
                  'Sélectionnez ou filmez votre session',
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
                  label: 'Filmer',
                  onTap: () => _pickVideo(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PickerButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Importer',
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
                            builder: (_, value, _) => AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: value.isPlaying ? 0 : 1,
                              child: Container(
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
                              ),
                            ),
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
                          'Aperçu non disponible sur bureau',
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
                label: const Text('Annuler'),
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
                  label: const Text('Analyser'),
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
              'Envoi en cours… ${(_uploadProgress * 100).toInt()} %',
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
    final int percent = _analysisProgress;
    final double progress = percent / 100.0;

    // Compute ETA from elapsed time and current speed.
    // Only shown once we have at least 2 % progress to avoid wild estimates.
    String remainingLabel = 'calcul en cours…';
    final started = _analysisStartedAt;
    if (started != null && percent >= 2) {
      final elapsedSecs = DateTime.now().difference(started).inSeconds;
      // seconds-per-percent then extrapolate remaining
      final remainingSecs = (elapsedSecs / percent * (100 - percent)).round();
      remainingLabel = _formatRemaining(remainingSecs);
    }

    return _AnalysingScreen(
      progress: progress,
      percent: percent,
      remainingLabel: remainingLabel,
    );
  }

  static String _formatRemaining(int seconds) {
    if (seconds <= 0) return 'bientôt…';
    if (seconds < 60) return '~$seconds s';
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return sec == 0
        ? '~$min min'
        : '~${min}m${sec.toString().padLeft(2, '0')}s';
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_rounded, size: 72, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Une erreur est survenue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _reset,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone() {
    final result = _analysisResult;
    final status = result?['status'] as String? ?? '—';
    final processingMs = result?['processing_time_ms'] as int?;
    final resultJson = result?['result_json'] as String?;

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
            isCompleted ? 'Analyse terminée !' : 'Analyse échouée',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (processingMs != null)
            Text(
              'Traitement : ${(processingMs / 1000).toStringAsFixed(1)} s',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          if (frameCount != null) ...[
            const SizedBox(height: 4),
            Text(
              '$frameCount frames analysées',
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
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Visualiser l\'analyse'),
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
              child: const Text('Analyser une autre vidéo'),
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
            'Résultats',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          _StatRow(label: 'Frames totales', value: '${frames.length}'),
          _StatRow(
            label: 'Pose détectée',
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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

  const _AnalysingScreen({
    required this.progress,
    required this.percent,
    required this.remainingLabel,
  });

  @override
  State<_AnalysingScreen> createState() => _AnalysingScreenState();
}

class _AnalysingScreenState extends State<_AnalysingScreen>
    with SingleTickerProviderStateMixin {
  int _promoIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Duration _promoInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _scheduleNext();
  }

  void _scheduleNext() {
    Future.delayed(_promoInterval, () {
      if (!mounted) return;
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _promoIndex = (_promoIndex + 1) % _promoMessages.length;
        });
        _fadeController.forward().then((_) => _scheduleNext());
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final msg = _promoMessages[_promoIndex];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
                    value: widget.progress > 0 ? widget.progress : null,
                    color: colorScheme.secondary,
                    backgroundColor: colorScheme.secondary.withValues(
                      alpha: 0.15,
                    ),
                    strokeWidth: 8,
                  ),
                ),
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
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Analyse en cours…',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'MediaPipe analyse votre session d\'escalade.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 32),

            // ── Promotional / tips banner ──
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: msg.isPromo
                      ? colorScheme.secondary.withValues(alpha: 0.10)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: msg.isPromo
                        ? colorScheme.secondary.withValues(alpha: 0.35)
                        : Colors.grey.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      msg.icon,
                      size: 28,
                      color: msg.isPromo
                          ? colorScheme.secondary
                          : Colors.grey[400],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msg.isPromo)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '✦ MODE PREMIUM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.secondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: msg.isPromo
                                  ? Colors.white
                                  : Colors.grey[400],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Dot indicators ──
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _promoMessages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _promoIndex ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _promoIndex
                        ? colorScheme.secondary
                        : Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
