// @date 2026-09-25
// @file app_localizations.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:new_mobile/core/l10n/translations/en.dart';
import 'package:new_mobile/core/l10n/translations/fr.dart';

/// Application localization manager with strict fallback:
/// 1. Current locale translation (e.g. French)
/// 2. Default English translation ('en')
/// 3. Translation key itself if missing in both
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const Locale defaultLocale = Locale('en');

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
  ];

  static const Map<String, Map<String, String>> _translations = {
    'en': enTranslations,
    'fr': frTranslations,
  };

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(defaultLocale);
  }

  /// Translates a [key] with optional parameter interpolation.
  ///
  /// Fallback chain:
  /// current locale -> 'en' -> raw [key]
  String tr(String key, [Map<String, String>? params]) {
    final langCode = locale.languageCode;
    final value = _translations[langCode]?[key] ?? _translations['en']?[key] ?? key;

    if (params == null || params.isEmpty) {
      return value;
    }

    var result = value;
    params.forEach((paramKey, paramValue) {
      result = result.replaceAll('{$paramKey}', paramValue);
    });
    return result;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

/// Convenience extension on [BuildContext] for translations.
extension LocalizationX on BuildContext {
  String tr(String key, [Map<String, String>? params]) {
    return AppLocalizations.of(this).tr(key, params);
  }
}
