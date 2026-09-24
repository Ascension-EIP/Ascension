// @date 2026-09-25
// @file app_theme.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Centralized application theme configuration using Forui design system.
class AppTheme {
  AppTheme._();

  static FThemeData dark() {
    return FThemeData(
      colors: FColors.neutralDark,
      touch: true,
    );
  }

  static FThemeData light() {
    return FThemeData(
      colors: FColors.neutralLight,
      touch: true,
    );
  }

  static ThemeData materialDark() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF09090B),
    );
  }
}
