// @date 2026-09-29
// @file auth_repository_impl_test.dart
// @brief Unit tests for AuthRepositoryImpl.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_mobile/core/errors/failures.dart';
import 'package:new_mobile/core/storage/secure_storage_service.dart';
import 'package:new_mobile/core/utils/result.dart';
import 'package:new_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:new_mobile/features/auth/data/models/auth_response_model.dart';
import 'package:new_mobile/features/auth/data/models/user_model.dart';
import 'package:new_mobile/features/auth/data/repositories/auth_repository_impl.dart';

class MockRemoteDataSource implements AuthRemoteDataSource {
  Result<AuthResponseModel>? loginResult;
  Result<AuthResponseModel>? registerResult;
  Result<void>? logoutResult;
  String? loggedOutRefreshToken;

  @override
  Future<Result<AuthResponseModel>> login({
    required String identifier,
    required String password,
    bool remember = true,
  }) async =>
      loginResult!;

  @override
  Future<Result<AuthResponseModel>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    bool remember = true,
  }) async =>
      registerResult!;

  @override
  Future<Result<void>> logout({required String refreshToken}) async {
    loggedOutRefreshToken = refreshToken;
    return logoutResult ?? const Success(null);
  }
}

class InMemorySecureStorageService extends SecureStorageService {
  InMemorySecureStorageService() : super(const FlutterSecureStorage());

  String? accessToken;
  String? refreshToken;
  String? userId;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveUserId(String userId) async {
    this.userId = userId;
  }

  @override
  Future<String?> getUserId() async => userId;

  @override
  Future<void> clearAuthData() async {
    accessToken = null;
    refreshToken = null;
    userId = null;
  }
}

void main() {
  late MockRemoteDataSource remoteDataSource;
  late InMemorySecureStorageService secureStorage;
  late AuthRepositoryImpl repository;

  const sampleResponse = AuthResponseModel(
    accessToken: 'access_abc',
    refreshToken: 'refresh_xyz',
    tokenType: 'Bearer',
    expiresIn: 3600,
    user: UserModel(
      id: 'user_42',
      username: 'climber42',
      email: 'user42@climber.com',
      firstName: 'Adam',
      lastName: 'Ondra',
    ),
  );

  setUp(() {
    remoteDataSource = MockRemoteDataSource();
    secureStorage = InMemorySecureStorageService();
    repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      secureStorage: secureStorage,
    );
  });

  group('AuthRepositoryImpl.login', () {
    test('persists tokens and user ID when login succeeds', () async {
      remoteDataSource.loginResult = const Success(sampleResponse);

      final result = await repository.login(
        identifier: 'user42@climber.com',
        password: 'password',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.accessToken, equals('access_abc'));
      expect(secureStorage.accessToken, equals('access_abc'));
      expect(secureStorage.refreshToken, equals('refresh_xyz'));
      expect(secureStorage.userId, equals('user_42'));
    });

    test('returns failure without saving tokens when login fails', () async {
      remoteDataSource.loginResult = const Error(AuthFailure('Invalid identifier'));

      final result = await repository.login(
        identifier: 'unknown',
        password: 'wrong',
      );

      expect(result.isError, isTrue);
      expect(secureStorage.accessToken, isNull);
    });
  });

  group('AuthRepositoryImpl.register', () {
    test('persists tokens and user ID when register succeeds', () async {
      remoteDataSource.registerResult = const Success(sampleResponse);

      final result = await repository.register(
        username: 'climber42',
        firstName: 'Adam',
        lastName: 'Ondra',
        email: 'user42@climber.com',
        password: 'password',
      );

      expect(result.isSuccess, isTrue);
      expect(secureStorage.accessToken, equals('access_abc'));
      expect(secureStorage.userId, equals('user_42'));
    });
  });

  group('AuthRepositoryImpl.logout', () {
    test('calls remote logout and clears secure storage', () async {
      secureStorage.accessToken = 'current_access';
      secureStorage.refreshToken = 'current_refresh';
      secureStorage.userId = 'user_42';

      final result = await repository.logout();

      expect(result.isSuccess, isTrue);
      expect(remoteDataSource.loggedOutRefreshToken, equals('current_refresh'));
      expect(secureStorage.accessToken, isNull);
      expect(secureStorage.refreshToken, isNull);
      expect(secureStorage.userId, isNull);
    });
  });

  group('AuthRepositoryImpl.hasValidSession', () {
    test('returns true when accessToken exists', () async {
      secureStorage.accessToken = 'valid_token';
      expect(await repository.hasValidSession(), isTrue);
    });

    test('returns false when accessToken is null or empty', () async {
      expect(await repository.hasValidSession(), isFalse);
    });
  });
}
