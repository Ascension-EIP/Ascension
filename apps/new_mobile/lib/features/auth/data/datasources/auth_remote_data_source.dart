// @date 2026-09-29
// @file auth_remote_data_source.dart
// @brief Remote data source performing network calls to the auth API.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_mobile/core/constants/api_endpoints.dart';
import 'package:new_mobile/core/network/api_client.dart';
import 'package:new_mobile/core/utils/result.dart';
import 'package:new_mobile/features/auth/data/models/auth_response_model.dart';

/// Contract for authentication remote HTTP interactions.
abstract class AuthRemoteDataSource {
  Future<Result<AuthResponseModel>> login({
    required String identifier,
    required String password,
    bool remember = true,
  });

  Future<Result<AuthResponseModel>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    bool remember = true,
  });

  Future<Result<void>> logout({required String refreshToken});
}

/// Implementation of [AuthRemoteDataSource] using [ApiClient].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Result<AuthResponseModel>> login({
    required String identifier,
    required String password,
    bool remember = true,
  }) async {
    final result = await _apiClient.post<dynamic>(
      ApiEndpoints.login,
      data: {
        'identifier': identifier,
        'password': password,
        'remember': remember,
      },
    );

    return result.map((data) => AuthResponseModel.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<Result<AuthResponseModel>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    bool remember = true,
  }) async {
    final result = await _apiClient.post<dynamic>(
      ApiEndpoints.register,
      data: {
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'remember': remember,
      },
    );

    return result.map((data) => AuthResponseModel.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<Result<void>> logout({required String refreshToken}) async {
    final result = await _apiClient.delete<dynamic>(
      ApiEndpoints.logout,
      data: {'refresh_token': refreshToken},
    );

    return result.map((_) {});
  }
}

/// Provider for [AuthRemoteDataSource].
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});
