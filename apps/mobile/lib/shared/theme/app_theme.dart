// @date 2026-09-07
// @file app_theme.dart
// @brief Configuration du thème Forui et des adaptations d'accessibilité.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  /// Ascension's brand typeface: Plus Jakarta Sans — a geometric, highly
  /// legible sans with just enough character to be recognisable, without
  /// being a novelty display font. Used across both the Material and Forui
  /// layers so the app reads as one coherent product rather than a
  /// framework's default look.
  static String get fontFamily => GoogleFonts.plusJakartaSans().fontFamily!;

  static FTypography _typography({
    required FColors colors,
    required bool touch,
  }) {
    final typeface = FTypeface.inherit(
      colors: colors,
      touch: touch,
      fontFamily: fontFamily,
    );
    return FTypography(display: typeface, body: typeface);
  }

  /// Forui dark theme data
  static FThemeData foruiDark({required bool highContrast}) {
    final colors = highContrast
        ? FColors.neutralDark.copyWith(
            background: Colors.black,
            foreground: Colors.white,
            card: Colors.black,
            border: Colors.white,
          )
        : FColors.neutralDark;
    return FThemeData(
      colors: colors,
      touch: true,
      typography: _typography(colors: colors, touch: true),
    );
  }

  /// Forui light theme data
  static FThemeData foruiLight({required bool highContrast}) {
    final colors = highContrast
        ? FColors.neutralLight.copyWith(
            background: Colors.white,
            foreground: Colors.black,
            card: Colors.white,
            border: Colors.black,
          )
        : FColors.neutralLight;
    return FThemeData(
      colors: colors,
      touch: true,
      typography: _typography(colors: colors, touch: true),
    );
  }

  /// Material ThemeData used by [MaterialApp.router]
  static ThemeData materialBase(
    Brightness brightness, {
    required bool highContrast,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? Colors.white : Colors.black,
      onPrimary: isDark ? Colors.black : Colors.white,
      secondary: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
      onSecondary: isDark ? Colors.black : Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      surface: isDark
          ? (highContrast ? Colors.black : const Color(0xFF09090B))
          : (highContrast ? Colors.white : const Color(0xFFFAFAFA)),
      onSurface: isDark ? Colors.white : Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: fontFamily,
    );
  }

  /// Applies accessibility tweaks (dyslexia font spacing, simplified density,
  /// reduced motion transitions) on top of the base Material ThemeData.
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
