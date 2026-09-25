// @date 2026-09-25
// @file app.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:new_mobile/app/app_theme.dart';
import 'package:new_mobile/app/env.dart';
import 'package:new_mobile/core/l10n/app_localizations.dart';
import 'package:new_mobile/core/l10n/locale_provider.dart';
import 'package:new_mobile/routing/app_router.dart';

class AscensionApp extends ConsumerWidget {
  const AscensionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppEnv.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.materialDark(),
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        return FTheme(
          data: AppTheme.dark(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
