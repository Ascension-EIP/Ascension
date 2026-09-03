// @date 2026-09-03
// @file main.dart
// @brief File description.
// @project Ascension
// @author Gianni TUERO <gianni.tuero@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:mobile/core/accessibility/accessibility_settings_service.dart';
import 'package:mobile/core/audio/audio_service.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/shared/localization/app_localizations.dart';
import 'package:mobile/shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().loadBaseUrl();
  await AuthService().init();
  await AccessibilitySettingsService().init();
  AudioService().init(); // lancé en arrière-plan, ne bloque pas le démarrage
  runApp(const AscensionApp());
}

class AscensionApp extends StatelessWidget {
  const AscensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AccessibilitySettingsService();

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) => ShadApp.router(
        title: 'Ascension',
        debugShowCheckedModeBanner: false,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.shadLight(highContrast: settings.highContrast),
        darkTheme: AppTheme.shadDark(highContrast: settings.highContrast),
        themeMode: settings.themeMode,
        materialThemeBuilder: (context, theme) => AppTheme.applyAccessibility(
          theme,
          highContrast: settings.highContrast,
          dyslexiaProfile: settings.dyslexiaProfile,
          simplifiedInterface: settings.simplifiedInterface,
          reducedMotion: settings.reducedMotion,
        ),
        routerConfig: appRouter,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final withScale = media.copyWith(
            textScaler: TextScaler.linear(settings.textScale),
            disableAnimations:
                settings.reducedMotion || media.disableAnimations,
          );
          return ScaffoldMessenger(
            child: MediaQuery(
              data: withScale,
              child: FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                descendantsAreFocusable: true,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}
