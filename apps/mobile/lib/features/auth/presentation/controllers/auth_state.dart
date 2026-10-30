// @date 2026-10-30
// @file auth_state.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({required this.status, this.userId});

  final AuthStatus status;
  final String? userId;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isInitial => status == AuthStatus.initial;

  @override
  List<Object?> get props => [status, userId];
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage)
    : super(const AuthState(status: AuthStatus.initial)) {
    checkAuthStatus();
  }

  final SecureStorageService _storage;

  Future<void> checkAuthStatus() async {
    final token = await _storage.getAccessToken();
    final userId = await _storage.getUserId();
    if (token != null && token.isNotEmpty) {
      state = AuthState(status: AuthStatus.authenticated, userId: userId);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void setAuthenticated({required String userId}) {
    state = AuthState(status: AuthStatus.authenticated, userId: userId);
  }

  Future<void> logout() async {
    await _storage.clearAuthData();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Provider for [AuthState] managing authentication session lifecycle.
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final notifier = AuthNotifier(storage);

  // Listen to 401 session expiration from ApiClient
  ref.listen<bool>(sessionExpiredProvider, (_, expired) {
    if (expired) {
      notifier.logout();
      ref.read(sessionExpiredProvider.notifier).state = false;
    }
  });

  return notifier;
});
