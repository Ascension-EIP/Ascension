// @date 2026-09-03
// @file api_service.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// The current backend base URL. Can be changed at runtime via [setBaseUrl].
  String _baseUrl = AppConstants.defaultBackendUrl;

  String get baseUrl => _baseUrl;

  /// When true, every method below returns canned data instead of reaching
  /// the backend. See [AppConstants.useMockApiByDefault] for the default and
  /// [setMockMode] to flip it at runtime (e.g. from the Settings screen).
  bool _mockMode = AppConstants.useMockApiByDefault;

  bool get mockMode => _mockMode;

  final Random _rng = Random();
  final Map<String, int> _mockAnalysisPolls = {};

  /// Load the persisted URL and mock flag (if any) from SharedPreferences.
  /// Call this once at app startup (e.g. in [main]).
  Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.defaultBackendUrl);
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = saved;
    }
    final savedMock = prefs.getBool(AppConstants.mockApiEnabledKey);
    if (savedMock != null) {
      _mockMode = savedMock;
    }
  }

  /// Persist [url] and use it for all future requests.
  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.defaultBackendUrl, url);
  }

  /// Persist and apply [enabled] for the mock mode toggle.
  Future<void> setMockMode(bool enabled) async {
    _mockMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.mockApiEnabledKey, enabled);
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (_mockMode) return _mockLogin(email);

    final uri = Uri.parse('$baseUrl/v1/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    _assertOk(response, 'login');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (_mockMode) return _mockRegister(username, email);

    final uri = Uri.parse('$baseUrl/v1/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    _assertOk(response, 'register');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ── Users ────────────────────────────────────────────────────────────────────

  /// Fetch a user by ID.
  /// Returns `{ id, username, email, role }`.
  Future<Map<String, dynamic>> getUser(String userId) async {
    if (_mockMode) return _mockUser(userId);

    final uri = Uri.parse('$baseUrl/v1/users/$userId');
    final response = await http.get(uri);
    _assertOk(response, 'get user');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ── Videos ──────────────────────────────────────────────────────────────────

  /// Request a presigned PUT URL to upload a video directly to MinIO.
  /// Returns `{ video_id: Uuid, upload_url: String }`.
  Future<Map<String, dynamic>> getUploadUrl({
    required String filename,
    required String userId,
  }) async {
    if (_mockMode) return _mockUploadUrl();

    final uri = Uri.parse('$baseUrl/v1/videos/upload-url');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'filename': filename, 'user_id': userId}),
    );
    _assertOk(response, 'get upload URL');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Upload a video file directly to MinIO using the presigned PUT URL.
  Future<void> uploadToMinio({
    required String uploadUrl,
    required List<int> fileBytes,
    String contentType = 'video/mp4',
  }) async {
    if (_mockMode) {
      // Simulate a bit of upload latency so the progress UI feels real.
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    final uri = Uri.parse(uploadUrl);
    final response = await http.put(
      uri,
      headers: {'Content-Type': contentType},
      body: fileBytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'MinIO upload failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  // ── Analyses ─────────────────────────────────────────────────────────────────

  /// Trigger a pose-analysis job for the given video.
  /// Returns `{ analysis_id: Uuid, job_id: Uuid, status: String }`.
  Future<Map<String, dynamic>> triggerAnalysis({
    required String videoId,
  }) async {
    if (_mockMode) return _mockTriggerAnalysis(videoId);

    final uri = Uri.parse('$baseUrl/v1/analyses');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'video_id': videoId}),
    );
    _assertOk(response, 'trigger analysis');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Fetch the current state of an analysis (polls until completed/failed).
  /// Returns the full analysis object from the API.
  Future<Map<String, dynamic>> getAnalysis(String analysisId) async {
    if (_mockMode) return _mockGetAnalysis(analysisId);

    final uri = Uri.parse('$baseUrl/v1/analyses/$analysisId');
    final response = await http.get(uri);
    _assertOk(response, 'get analysis');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _assertOk(http.Response response, String context) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '[$context] HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  // ── Mock helpers ─────────────────────────────────────────────────────────────
  // Canned responses that mirror the real API's shape, so every screen keeps
  // working with no backend running.

  String _mockUserId(String seed) =>
      'mock-${seed.hashCode.toUnsigned(32).toRadixString(16)}';

  Map<String, dynamic> _mockLogin(String email) {
    final trimmed = email.trim();
    final username = trimmed.contains('@')
        ? trimmed.split('@').first
        : (trimmed.isEmpty ? 'Grimpeur' : trimmed);
    return {
      'access_token': 'mock-access-token',
      'refresh_token': 'mock-refresh-token',
      'user_id': _mockUserId(trimmed.isEmpty ? 'mock-user' : trimmed),
      'username': username,
      'email': trimmed,
      'role': 'user',
    };
  }

  Map<String, dynamic> _mockRegister(String username, String email) {
    return {
      'access_token': 'mock-access-token',
      'refresh_token': 'mock-refresh-token',
      'user_id': _mockUserId(email.isEmpty ? username : email),
      'username': username,
      'email': email,
      'role': 'user',
    };
  }

  Map<String, dynamic> _mockUser(String userId) {
    return {
      'id': userId,
      'username': 'Grimpeur',
      'email': 'mock@ascension.app',
      'role': 'user',
    };
  }

  Map<String, dynamic> _mockUploadUrl() {
    final videoId = 'mock-video-${DateTime.now().millisecondsSinceEpoch}';
    return {
      'video_id': videoId,
      'upload_url': 'https://mock.ascension.local/upload/$videoId',
    };
  }

  Map<String, dynamic> _mockTriggerAnalysis(String videoId) {
    final analysisId = 'mock-analysis-${DateTime.now().millisecondsSinceEpoch}';
    _mockAnalysisPolls[analysisId] = 0;
    return {
      'analysis_id': analysisId,
      'job_id': 'mock-job-$analysisId',
      'status': 'processing',
    };
  }

  /// Fake progress: each poll on the same [analysisId] advances a counter
  /// until it reports `completed` with generated frame data, mimicking the
  /// real polling loop in [VideoUpload].
  Future<Map<String, dynamic>> _mockGetAnalysis(String analysisId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final poll = (_mockAnalysisPolls[analysisId] ?? 0) + 1;
    _mockAnalysisPolls[analysisId] = poll;

    const totalPolls = 6; // a few seconds of fake "processing"
    if (poll < totalPolls) {
      final isLastStretch = poll == totalPolls - 1;
      return {
        'id': analysisId,
        'status': isLastStretch ? 'generating_hints' : 'processing',
        'progress': min(95, (poll * 100 / totalPolls).round()),
      };
    }

    _mockAnalysisPolls.remove(analysisId);
    return _mockCompletedAnalysis(analysisId);
  }

  Map<String, dynamic> _mockCompletedAnalysis(String analysisId) {
    final now = DateTime.now();
    final frames = List.generate(60, (i) {
      final detected = _rng.nextDouble() > 0.08;
      return {
        'frame_index': i,
        'pose_detected': detected,
        'keypoints': detected
            ? List.generate(
                33,
                (_) => {
                  'x': _rng.nextDouble(),
                  'y': _rng.nextDouble(),
                  'z': 0.0,
                  'visibility': 0.9,
                },
              )
            : [],
      };
    });

    return {
      'id': analysisId,
      'status': 'completed',
      'progress': 100,
      'created_at': now.subtract(const Duration(seconds: 30)).toIso8601String(),
      'completed_at': now.toIso8601String(),
      'processing_time_ms': 28000 + _rng.nextInt(5000),
      'result_json': jsonEncode({'frames': frames}),
      'hints':
          'Analyse générée en local (mode mock) : essaie de garder le '
          'bassin plus proche du mur sur les mouvements dynamiques et '
          'anticipe la prise suivante du regard avant de bouger les mains.',
    };
  }
}
