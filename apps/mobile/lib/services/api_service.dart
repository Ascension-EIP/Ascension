import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Base URL of the Rust/Axum backend.
///
/// Resolution order:
///   1. --dart-define=BACKEND_URL=http://...   (highest priority, baked at build time)
///   2. Runtime fallback:
///        - Linux/macOS/Windows desktop → http://localhost:8080
///        - Android emulator            → http://10.0.2.2:8080
///        - Android real device         → rebuild with --dart-define=BACKEND_URL=http://192.168.1.42:8080
const String _kDefinedUrl = String.fromEnvironment('BACKEND_URL');

String get _kBaseUrl {
  if (_kDefinedUrl.isNotEmpty) return _kDefinedUrl;
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    return 'http://localhost:8080';
  }
  // Android emulator
  return 'http://10.0.2.2:8080';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = _kBaseUrl;

  // ── Videos ──────────────────────────────────────────────────────────────────

  /// Request a presigned PUT URL to upload a video directly to MinIO.
  /// Returns `{ video_id: Uuid, upload_url: String }`.
  Future<Map<String, dynamic>> getUploadUrl({
    required String filename,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/videos/upload-url');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'filename': filename, 'user_id': userId}),
    );
    _assertOk(response, 'get upload URL');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  /// Upload a video file directly to MinIO using the presigned PUT URL.
  Future<void> uploadToMinio({
    required String uploadUrl,
    required List<int> fileBytes,
    String contentType = 'video/mp4',
  }) async {
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
    final uri = Uri.parse('$baseUrl/v1/analyses');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'video_id': videoId}),
    );
    _assertOk(response, 'trigger analysis');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  /// Fetch the current state of an analysis (polls until completed/failed).
  /// Returns the full analysis object from the API.
  Future<Map<String, dynamic>> getAnalysis(String analysisId) async {
    final uri = Uri.parse('$baseUrl/v1/analyses/$analysisId');
    final response = await http.get(uri);
    _assertOk(response, 'get analysis');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  void _assertOk(http.Response response, String context) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '[$context] HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }
}
