// @date 2026-09-03
// @file app_theme.dart
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppTheme {
  // Pure shadcn/ui defaults (zinc) — no app-specific branding.
  static const ShadColorScheme _darkScheme = ShadZincColorScheme.dark();
  static const ShadColorScheme _lightScheme = ShadZincColorScheme.light();

  // High contrast keeps the default zinc scheme but pushes background/
  // foreground/border to pure black/white for maximum contrast.
  static const ShadColorScheme _highContrastDarkScheme =
      ShadZincColorScheme.dark(
        background: Colors.black,
        foreground: Colors.white,
        card: Colors.black,
        cardForeground: Colors.white,
        popover: Colors.black,
        popoverForeground: Colors.white,
        border: Colors.white,
        input: Colors.white,
        ring: Colors.white,
      );

  static const ShadColorScheme _highContrastLightScheme =
      ShadZincColorScheme.light(
        background: Colors.white,
        foreground: Colors.black,
        card: Colors.white,
        cardForeground: Colors.black,
        popover: Colors.white,
        popoverForeground: Colors.black,
        border: Colors.black,
        input: Colors.black,
        ring: Colors.black,
      );

  /// Shadcn theme used for the dark [ShadApp.router] theme.
  static ShadThemeData shadDark({required bool highContrast}) => ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: highContrast ? _highContrastDarkScheme : _darkScheme,
  );

  /// Shadcn theme used for the light [ShadApp.router] theme.
  static ShadThemeData shadLight({required bool highContrast}) => ShadThemeData(
    brightness: Brightness.light,
    colorScheme: highContrast ? _highContrastLightScheme : _lightScheme,
  );

  /// Applies the accessibility-driven tweaks (dyslexia spacing, simplified
  /// density, reduced motion, high-contrast borders) on top of the Material
  /// [ThemeData] that [ShadApp.router] derives automatically from the shad
  /// color scheme above.
  static ThemeData applyAccessibility(
    ThemeData base, {
    required bool highContrast,
    required bool dyslexiaProfile,
    required bool simplifiedInterface,
    required bool reducedMotion,
  }) {
    final ColorScheme colorScheme = base.colorScheme;

    final TextTheme textTheme = dyslexiaProfile
        ? base.textTheme
              .apply(heightFactor: 1.4)
              .copyWith(
                bodyLarge: base.textTheme.bodyLarge?.copyWith(
                  letterSpacing: 0.2,
                ),
                bodyMedium: base.textTheme.bodyMedium?.copyWith(
                  letterSpacing: 0.2,
                ),
              )
        : base.textTheme;

    return base.copyWith(
      visualDensity: simplifiedInterface
          ? VisualDensity.comfortable
          : VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: reducedMotion
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoTransitionsBuilder(),
                TargetPlatform.iOS: _NoTransitionsBuilder(),
                TargetPlatform.macOS: _NoTransitionsBuilder(),
                TargetPlatform.windows: _NoTransitionsBuilder(),
                TargetPlatform.linux: _NoTransitionsBuilder(),
              },
            )
          : base.pageTransitionsTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: highContrast ? 3 : 2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: highContrast
                ? BorderSide(color: colorScheme.onSurface, width: 1.4)
                : BorderSide.none,
          ),
        ),
      ),
      textTheme: textTheme,
    );
  }
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
