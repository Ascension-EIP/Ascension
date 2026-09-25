// @date 2026-09-25
// @file locale_provider.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_mobile/core/constants/storage_keys.dart';
import 'package:new_mobile/core/l10n/app_localizations.dart';
import 'package:new_mobile/core/storage/local_storage_service.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._storage) : super(AppLocalizations.defaultLocale) {
    _loadSavedLocale();
  }

  final LocalStorageService _storage;

  void _loadSavedLocale() {
    final savedCode = _storage.getString(StorageKeys.locale);
    if (savedCode != null) {
      final matched = AppLocalizations.supportedLocales.where(
        (l) => l.languageCode == savedCode,
      );
      if (matched.isNotEmpty) {
        state = matched.first;
      }
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (AppLocalizations.supportedLocales.contains(locale)) {
      state = locale;
      await _storage.setString(StorageKeys.locale, locale.languageCode);
    }
  }
}

/// Provider managing active app locale.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return LocaleNotifier(storage);
});
