// @date 2026-10-30
// @file failures.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:equatable/equatable.dart';

/// Base failure class representing domain and data-level errors.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Failure caused by network/connectivity problems.
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Network error. Please check your internet connection.',
  ]);
}

/// Failure returned by the remote backend API.
final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'A server error occurred. Please try again later.',
  ]);
}

/// Failure related to authentication and session management.
final class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Authentication failed. Please sign in again.',
  ]);
}

/// Failure when reading or writing from local cache or storage.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load local data.']);
}

/// Generic unexpected failure.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred.']);
}
