// @date 2026-09-29
// @file auth_interceptor.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:dio/dio.dart';
import 'package:new_mobile/core/constants/api_endpoints.dart';
import 'package:new_mobile/core/storage/secure_storage_service.dart';

/// Interceptor that attaches the JWT Bearer token to outgoing requests
/// and handles token refresh on 401 Unauthorized responses.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.storage,
    required this.onSessionExpired,
  });

  final SecureStorageService storage;
  final void Function() onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isAuthEndpoint = options.path.contains('/v1/auth/login') ||
        options.path.contains('/v1/auth/register');

    if (!isAuthEndpoint) {
      final token = await storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final isRefreshEndpoint = err.requestOptions.path.contains(ApiEndpoints.refreshToken);

    // If 401 on refresh endpoint or auth endpoint, user session is invalid
    if (response?.statusCode == 401 && !isRefreshEndpoint) {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: err.requestOptions.baseUrl,
              headers: {'Content-Type': 'application/json'},
            ),
          );

          final refreshResponse = await refreshDio.put<Map<String, dynamic>>(
            ApiEndpoints.refreshToken,
            data: {'refresh_token': refreshToken},
          );

          if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
            final newAccessToken = refreshResponse.data!['access_token'] as String?;
            final newRefreshToken = refreshResponse.data!['refresh_token'] as String? ?? refreshToken;

            if (newAccessToken != null) {
              await storage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              // Retry original request with new token
              final originalOptions = err.requestOptions;
              originalOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryResponse = await refreshDio.fetch<dynamic>(originalOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          // Token refresh failed -> session expired
        }
      }

      await storage.clearAuthData();
      onSessionExpired();
    }

    return handler.next(err);
  }
}
