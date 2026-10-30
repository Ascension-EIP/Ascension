// @date 2026-10-30
// @file auth_repository.dart
// @brief Abstract repository contract for authentication.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/domain/entities/auth_session.dart';

/// Abstract repository defining authentication business operations.
abstract class AuthRepository {
  /// Authenticates a user with identifier (email or username) and password.
  Future<Result<AuthSession>> login({
    required String identifier,
    required String password,
    bool remember = true,
  });

  /// Registers a new user and automatically logs them in.
  Future<Result<AuthSession>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    bool remember = true,
  });

  /// Logs out the user on the server and clears local tokens.
  Future<Result<void>> logout();

  /// Checks if a valid session exists in secure storage.
  Future<bool> hasValidSession();
}
