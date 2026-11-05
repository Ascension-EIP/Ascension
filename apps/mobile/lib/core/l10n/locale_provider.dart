// @date 2026-11-02
// @file locale_provider.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/core/storage/local_storage_service.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final storage = ref.watch(localStorageServiceProvider);
    final savedCode = storage.getString(StorageKeys.locale);
    if (savedCode != null) {
      final matched = AppLocalizations.supportedLocales.where(
        (l) => l.languageCode == savedCode,
      );
      if (matched.isNotEmpty) {
        return matched.first;
      }
    }
    return AppLocalizations.defaultLocale;
  }

  Future<void> setLocale(Locale locale) async {
    if (AppLocalizations.supportedLocales.contains(locale)) {
      state = locale;
      await ref
          .read(localStorageServiceProvider)
          .setString(StorageKeys.locale, locale.languageCode);
    }
  }
}

/// Provider managing active app locale.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
