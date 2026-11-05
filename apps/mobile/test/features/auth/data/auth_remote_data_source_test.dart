// @date 2026-10-25
// @file auth_remote_data_source_test.dart
// @brief Unit tests for AuthRemoteDataSource.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_data_source.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(Dio());

  dynamic responseData;
  Failure? failureToReturn;
  String? lastPath;
  dynamic lastData;

  @override
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastData = data;
    if (failureToReturn != null) {
      return Error(failureToReturn!);
    }
    return Success(responseData as T);
  }

  @override
  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastData = data;
    if (failureToReturn != null) {
      return Error(failureToReturn!);
    }
    return Success(responseData as T);
  }
}

void main() {
  late FakeApiClient fakeApiClient;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    fakeApiClient = FakeApiClient();
    dataSource = AuthRemoteDataSourceImpl(fakeApiClient);
  });

  group('AuthRemoteDataSource.login', () {
    test(
      'sends POST to /v1/auth/login and parses AuthResponseModel successfully',
      () async {
        fakeApiClient.responseData = {
          'access_token': 'jwt_access',
          'refresh_token': 'jwt_refresh',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'user': {
            'ID': 'usr_123',
            'Username': 'alex_climber',
            'FirstName': 'Alex',
            'LastName': 'Hon',
            'Email': 'alex@climber.com',
            'Role': 1,
            'Status': 1,
          },
        };

        final result = await dataSource.login(
          identifier: 'alex@climber.com',
          password: 'password123',
          remember: true,
        );

        expect(result.isSuccess, isTrue);
        final session = result.dataOrNull!;
        expect(fakeApiClient.lastPath, equals(ApiEndpoints.login));
        expect(
          fakeApiClient.lastData['identifier'],
          equals('alex@climber.com'),
        );
        expect(fakeApiClient.lastData['password'], equals('password123'));
        expect(session.accessToken, equals('jwt_access'));
        expect(session.refreshToken, equals('jwt_refresh'));
        expect(session.user.id, equals('usr_123'));
        expect(session.user.username, equals('alex_climber'));
        expect(session.user.fullName, equals('Alex Hon'));
      },
    );

    test('returns AuthFailure when server rejects credentials', () async {
      fakeApiClient.failureToReturn = const AuthFailure('Invalid credentials.');

      final result = await dataSource.login(
        identifier: 'bad@user.com',
        password: 'wrong',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.message, equals('Invalid credentials.'));
    });
  });

  group('AuthRemoteDataSource.register', () {
    test(
      'sends POST to /v1/auth/register and parses response correctly',
      () async {
        fakeApiClient.responseData = {
          'access_token': 'jwt_signup_access',
          'refresh_token': 'jwt_signup_refresh',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'user': {
            'id': 'usr_999',
            'username': 'newbie',
            'first_name': 'New',
            'last_name': 'Climber',
            'email': 'newbie@ascension.app',
          },
        };

        final result = await dataSource.register(
          username: 'newbie',
          firstName: 'New',
          lastName: 'Climber',
          email: 'newbie@ascension.app',
          password: 'SecretPassword',
        );

        expect(result.isSuccess, isTrue);
        expect(fakeApiClient.lastPath, equals(ApiEndpoints.register));
        final session = result.dataOrNull!;
        expect(session.accessToken, equals('jwt_signup_access'));
        expect(session.user.username, equals('newbie'));
        expect(session.user.fullName, equals('New Climber'));
      },
    );
  });

  group('AuthRemoteDataSource.logout', () {
    test('sends DELETE to /v1/auth/logout with refresh token', () async {
      fakeApiClient.responseData = null;

      final result = await dataSource.logout(refreshToken: 'token_to_revoke');

      expect(result.isSuccess, isTrue);
      expect(fakeApiClient.lastPath, equals(ApiEndpoints.logout));
      expect(
        fakeApiClient.lastData['refresh_token'],
        equals('token_to_revoke'),
      );
    });
  });
}
