// @date 2026-10-25
// @file api_client.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/env.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/core/utils/result.dart';

/// Centralized HTTP API client wrapping [Dio] with authentication and error mapping.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Dio get dio => _dio;

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _safeRequest(
      () =>
          _dio.get<T>(path, queryParameters: queryParameters, options: options),
    );
  }

  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _safeRequest(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _safeRequest(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _safeRequest(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// Direct binary upload (e.g. to MinIO / S3 via presigned PUT URL).
  Future<Result<void>> uploadToPresignedUrl({
    required String presignedUrl,
    required File file,
    required String contentType,
    void Function(int sentBytes, int totalBytes)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final uploadDio =
          Dio(); // Clean Dio instance without standard auth headers
      final fileLength = await file.length();

      await uploadDio.put<dynamic>(
        presignedUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileLength,
            Headers.contentTypeHeader: contentType,
          },
        ),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      return const Success(null);
    } on DioException catch (e) {
      return Error(_mapDioExceptionToFailure(e));
    } catch (e) {
      return Error(UnexpectedFailure(e.toString()));
    }
  }

  Future<Result<T>> _safeRequest<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null && null is! T) {
        return const Error(
          ServerFailure('Received empty response from server.'),
        );
      }
      return Success(data as T);
    } on DioException catch (e) {
      return Error(_mapDioExceptionToFailure(e));
    } catch (e) {
      return Error(UnexpectedFailure(e.toString()));
    }
  }

  Failure _mapDioExceptionToFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) {
          final msg =
              _extractErrorMessage(e.response?.data) ??
              'Invalid credentials or unauthorized.';
          return AuthFailure(msg);
        }
        final msg =
            _extractErrorMessage(e.response?.data) ??
            'Server returned error status $status.';
        return ServerFailure(msg);
      case DioExceptionType.cancel:
        return const UnexpectedFailure('Request was cancelled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return UnexpectedFailure(
          e.message ?? 'An unexpected network error occurred.',
        );
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    return null;
  }
}

/// Session expiration event controller to allow reactive navigation to login
final sessionExpiredProvider = StateProvider<bool>((ref) => false);

/// Riverpod provider for the configured [Dio] instance.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.backendUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      storage: storage,
      onSessionExpired: () {
        ref.read(sessionExpiredProvider.notifier).state = true;
      },
    ),
  );

  return dio;
});

/// Riverpod provider for [ApiClient].
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
