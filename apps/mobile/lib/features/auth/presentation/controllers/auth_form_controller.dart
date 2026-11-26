// @date 2026-11-02
// @file auth_form_controller.dart
// @brief Controller managing authentication forms (login & register).
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/biometric_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/controllers/auth_state.dart';

/// Form execution state handling loading, success, and localized error messages.
class AuthFormController extends AsyncNotifier<void> {
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

      switch (result) {
        case Success(:final data):
          // If biometric is enabled, ensure the stored password stays in sync
          final biometricService = ref.read(biometricServiceProvider);
          if (await biometricService.isBiometricEnabled()) {
            await biometricService.saveBiometricCredentials(
              identifier: identifier.trim(),
              password: password,
            );
          }

          TextInput.finishAutofillContext(shouldSave: true);
          await Future<void>.delayed(const Duration(milliseconds: 250));

          ref
              .read(authStateProvider.notifier)
              .setAuthenticated(userId: data.user.id);
          state = const AsyncData(null);
          return true;
        case Error(:final failure):
          TextInput.finishAutofillContext(shouldSave: false);
          state = AsyncError(failure.message, StackTrace.current);
          return false;
      }
    } catch (error, stackTrace) {
      state = AsyncError(error.toString(), stackTrace);
      return false;
    }
  }

  /// Performs user registration and automatic sign in.
  Future<bool> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    bool remember = true,
  }) async {
    state = const AsyncLoading();

    try {
      final result = await _repository.register(
        username: username.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        password: password,
        remember: remember,
      );

      switch (result) {
        case Success(:final data):
          TextInput.finishAutofillContext(shouldSave: true);
          await Future<void>.delayed(const Duration(milliseconds: 250));

          ref
              .read(authStateProvider.notifier)
              .setAuthenticated(userId: data.user.id);
          state = const AsyncData(null);
          return true;
        case Error(:final failure):
          TextInput.finishAutofillContext(shouldSave: false);
          state = AsyncError(failure.message, StackTrace.current);
          return false;
      }
    } catch (error, stackTrace) {
      state = AsyncError(error.toString(), stackTrace);
      return false;
    }
  }
}

/// Provider for [AuthFormController].
final authFormControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthFormController, void>(
      AuthFormController.new,
    );
