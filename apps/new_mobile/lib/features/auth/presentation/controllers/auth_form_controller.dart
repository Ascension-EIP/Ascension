// @date 2026-09-29
// @file auth_form_controller.dart
// @brief Controller managing authentication forms (login & signup).
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:new_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:new_mobile/features/auth/presentation/controllers/auth_state.dart';

/// Form execution state handling loading, success, and localized error messages.
class AuthFormController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is idle (AsyncData(null))
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Performs user sign in.
  Future<bool> login({
    required String identifier,
    required String password,
    bool remember = true,
  }) async {
    state = const AsyncLoading();

    try {
      final result = await _repository.login(
        identifier: identifier.trim(),
        password: password,
        remember: remember,
      );

      bool isSuccess = false;
      result.when(
        success: (session) {
          ref.read(authStateProvider.notifier).setAuthenticated(userId: session.user.id);
          state = const AsyncData(null);
          isSuccess = true;
        },
        error: (failure) {
          state = AsyncError(failure.message, StackTrace.current);
          isSuccess = false;
        },
      );
      return isSuccess;
    } catch (error, stackTrace) {
      state = AsyncError(error.toString(), stackTrace);
      return false;
    }
  }

  /// Performs user registration and automatic sign in.
  Future<bool> signup({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    bool remember = true,
  }) async {
    state = const AsyncLoading();

    try {
      final result = await _repository.signup(
        username: username.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        password: password,
        remember: remember,
      );

      bool isSuccess = false;
      result.when(
        success: (session) {
          ref.read(authStateProvider.notifier).setAuthenticated(userId: session.user.id);
          state = const AsyncData(null);
          isSuccess = true;
        },
        error: (failure) {
          state = AsyncError(failure.message, StackTrace.current);
          isSuccess = false;
        },
      );
      return isSuccess;
    } catch (error, stackTrace) {
      state = AsyncError(error.toString(), stackTrace);
      return false;
    }
  }
}

/// Provider for [AuthFormController].
final authFormControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthFormController, void>(AuthFormController.new);
