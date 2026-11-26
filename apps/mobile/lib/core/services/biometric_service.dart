// @date 2026-11-21
// @file biometric_service.dart
// @brief Service handling local biometric authentication (Fingerprint, Face ID).
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

class BiometricService {
  BiometricService({
    required LocalAuthentication localAuth,
    required SecureStorageService secureStorage,
  }) : _auth = localAuth,
       _storage = secureStorage;

  final LocalAuthentication _auth;
  final SecureStorageService _storage;

  /// Checks if the device has biometric capabilities and hardware support.
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } on PlatformException {
      return false;
    }
  }

  /// Returns the available biometric types on the device (e.g. fingerprint, face).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Checks if biometric login is enabled by the user in app settings.
  Future<bool> isBiometricEnabled() => _storage.isBiometricEnabled();

  /// Sets whether biometric login is enabled.
  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.setBiometricEnabled(enabled);

  /// Checks if both biometrics is enabled and credentials are saved.
  Future<bool> hasSavedBiometrics() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return false;
    final pwd = await _storage.getBiometricPassword();
    return pwd != null && pwd.isNotEmpty;
  }

  /// Saves biometric credentials securely.
  Future<void> saveBiometricCredentials({
    required String identifier,
    required String password,
  }) async {
    await _storage.saveSavedIdentifier(identifier);
    await _storage.saveBiometricPassword(password);
    await _storage.setBiometricEnabled(true);
  }

  /// Retrieves the saved biometric password.
  Future<String?> getSavedPassword() => _storage.getBiometricPassword();

  /// Disables biometric login and removes stored biometric password.
  Future<void> disableBiometric() => _storage.clearBiometricCredentials();

  /// Authenticates using biometrics.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }
}

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  final localAuth = ref.watch(localAuthProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return BiometricService(localAuth: localAuth, secureStorage: secureStorage);
});
