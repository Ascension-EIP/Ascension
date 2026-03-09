import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/pages/analysis/analysis_view_page.dart';

/// video_player is only supported on Android, iOS, and Web.
bool get _supportsVideoPlayer =>
    !kIsWeb
        ? Platform.isAndroid || Platform.isIOS
        : true;

enum _UploadState { idle, selected, uploading, analysing, done, error }

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

  // Temporary hard-coded userId until auth is wired.
  // Replace with your actual user UUID from the DB.
  static const String _tempUserId = '00000000-0000-0000-0000-000000000001';

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
      final urlData = await api.getUploadUrl(
        filename: filename,
        userId: _tempUserId,
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
      setState(() => _state = _UploadState.analysing);
      final analysisData = await api.triggerAnalysis(videoId: videoId);
      final analysisId = analysisData['analysis_id'] as String;

      // 4. Poll until completed or failed (up to ~5 minutes).
      // A `failed` status seen in the first 3 polls (< 15 s) may be a stale
      // result from a previous attempt on the same video — keep waiting until
      // the worker picks up the new job and updates the status.
      Map<String, dynamic>? result;
      for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 5));
        final a = await api.getAnalysis(analysisId);
        final status = a['status'] as String;
        if (status == 'completed') {
          result = a;
          break;
        }
        // Accept `failed` only after we have waited at least 15 s so that
        // a fresh worker run has had time to update the status from a
        // previously-failed attempt.
        if (status == 'failed' && i >= 2) {
          result = a;
          break;
        }
      }

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Analyse en cours…',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'MediaPipe analyse votre session d\'escalade.\nCela peut prendre quelques minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
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
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
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
                        resultJson:   resultJson,
                        processingMs: processingMs,
                        videoFile:    _videoFile,
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
    final detectedFrames =
        frames.where((f) => f['pose_detected'] == true).length;
    final detectionRate = frames.isEmpty
        ? 0.0
        : detectedFrames / frames.length * 100;

    // Collect average left-elbow angle across frames
    final angles = frames
        .where((f) => f['angles'] != null && (f['angles'] as Map).containsKey('13'))
        .map((f) => (f['angles']['13'] as num).toDouble())
        .toList();
    final avgAngle = angles.isEmpty
        ? null
        : angles.reduce((a, b) => a + b) / angles.length;

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
          _StatRow(
            label: 'Frames totales',
            value: '${frames.length}',
          ),
          _StatRow(
            label: 'Pose détectée',
            value:
                '$detectedFrames frames (${detectionRate.toStringAsFixed(0)} %)',
          ),
          if (avgAngle != null)
            _StatRow(
              label: 'Angle moyen coude gauche',
              value: '${avgAngle.toStringAsFixed(1)}°',
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
