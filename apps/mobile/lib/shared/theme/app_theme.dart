import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData dark({
    required bool highContrast,
    required bool dyslexiaProfile,
    required bool simplifiedInterface,
    required bool reducedMotion,
  }) {
    final ColorScheme colorScheme = highContrast
        ? const ColorScheme.dark(
            primary: Color(0xFF4DDCFF),
            secondary: Color(0xFF7CEBFF),
            surface: Color(0xFF050A12),
            error: Color(0xFFFF6B6B),
            onSurface: Color(0xFFFFFFFF),
          )
        : const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.surfaceDark,
            error: AppColors.error,
          );

    final TextTheme baseTextTheme = const TextTheme(
      headlineLarge: TextStyle(color: AppColors.textPrimary),
      headlineMedium: TextStyle(color: AppColors.textPrimary),
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
    );

    final TextTheme textTheme = dyslexiaProfile
        ? baseTextTheme
              .apply(heightFactor: 1.4)
              .copyWith(
                bodyLarge: baseTextTheme.bodyLarge?.copyWith(
                  letterSpacing: 0.2,
                ),
                bodyMedium: baseTextTheme.bodyMedium?.copyWith(
                  letterSpacing: 0.2,
                ),
              )
        : baseTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: highContrast
          ? const Color(0xFF000000)
          : AppColors.backgroundDark,
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
          : null,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: highContrast ? const Color(0xFF000000) : AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: highContrast ? Colors.white : Colors.transparent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: highContrast ? Colors.white : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: highContrast ? 3 : 2,
          ),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: highContrast
                ? const BorderSide(color: Colors.white, width: 1.4)
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
