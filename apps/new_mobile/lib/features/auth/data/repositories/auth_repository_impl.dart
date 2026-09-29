// @date 2026-09-29
// @file auth_repository_impl.dart
// @brief Concrete implementation of AuthRepository with secure storage orchestration.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_mobile/core/storage/secure_storage_service.dart';
import 'package:new_mobile/core/utils/result.dart';
import 'package:new_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:new_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:new_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] combining [AuthRemoteDataSource] and [SecureStorageService].
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  @override
  Future<Result<AuthSession>> login({
    required String identifier,
    required String password,
    bool remember = true,
  }) async {
    final result = await remoteDataSource.login(
      identifier: identifier,
      password: password,
      remember: remember,
    );

    switch (result) {
      case Success(:final data):
        await _persistSession(data);
        return Success(data);
      case Error(:final failure):
        return Error(failure);
    }
  }

  @override
  Future<Result<AuthSession>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    bool remember = true,
  }) async {
    final result = await remoteDataSource.register(
      username: username,
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      remember: remember,
    );

    switch (result) {
      case Success(:final data):
        await _persistSession(data);
        return Success(data);
      case Error(:final failure):
        return Error(failure);
    }
  }

  @override
  Future<Result<void>> logout() async {
    final refreshToken = await secureStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      // Best-effort logout call to the server
      await remoteDataSource.logout(refreshToken: refreshToken);
    }

    await secureStorage.clearAuthData();
    return const Success(null);
  }

  @override
  Future<bool> hasValidSession() async {
    final token = await secureStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _persistSession(AuthSession session) async {
    await secureStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await secureStorage.saveUserId(session.user.id);
  }
}

/// Provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    secureStorage: secureStorage,
  );
});
