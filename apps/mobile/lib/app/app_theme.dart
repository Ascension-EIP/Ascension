// @date 2026-11-07
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

  static FTypography _createTypography(FColors colors) {
    final base = FTypeface.inherit(colors: colors, touch: true);
    final display = base.copyWith(
      xl2: base.xl2.copyWith(fontSize: 22),
      xl: base.xl.copyWith(fontSize: 18),
    );
    return FTypography(display: display, body: base);
  }

  static FThemeData _createTheme(FColors colors, String debugLabel) {
    final typography = _createTypography(colors);
    final style = FStyle.inherit(
      colors: colors,
      typography: typography,
      touch: true,
    );

    final baseHeaders = FHeaderStyles.inherit(
      colors: colors,
      typography: typography,
      style: style,
      touch: true,
    );

    final rootHeader = baseHeaders.root.copyWith(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsetsGeometryDelta.value(
        EdgeInsets.fromLTRB(16, 2, 16, 2),
      ),
      actionStyle: baseHeaders.root.actionStyle.copyWith(
        padding: const EdgeInsetsGeometryDelta.value(EdgeInsets.all(6)),
      ),
    );

    final nestedHeader = baseHeaders.nested.copyWith(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsetsGeometryDelta.value(
        EdgeInsets.fromLTRB(16, 2, 16, 2),
      ),
      actionStyle: baseHeaders.nested.actionStyle.copyWith(
        padding: const EdgeInsetsGeometryDelta.value(EdgeInsets.all(6)),
      ),
    );

    final headerStyles = FHeaderStyles(
      FVariants<
        FHeaderVariantConstraint,
        FHeaderVariant,
        FHeaderStyle,
        FHeaderStyleDelta
      >(
        rootHeader,
        variants: {
          [FHeaderVariant.root]: rootHeader,
          [FHeaderVariant.nested]: nestedHeader,
        },
      ),
    );

    final scaffoldStyle = FScaffoldStyle.inherit(colors: colors, style: style)
        .copyWith(
          childPadding: const EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
        );

    return FThemeData(
      debugLabel: debugLabel,
      colors: colors,
      touch: true,
      typography: typography,
      style: style,
      headerStyles: headerStyles,
      scaffoldStyle: scaffoldStyle,
    );
  }

  static FThemeData dark() {
    return _createTheme(FColors.neutralDark, 'Neutral Dark');
  }

  static FThemeData light() {
    return _createTheme(FColors.neutralLight, 'Neutral Light');
  }

  static ThemeData materialDark() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF09090B),
    );
  }
}
