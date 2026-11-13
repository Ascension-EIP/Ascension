// @date 2026-11-06
// @file no_session_dialog.dart
// @brief Dialog asking user to create a session before starting an analysis.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/l10n/app_localizations.dart';

/// Shows a Forui dialog when an analysis is requested with no active session.
/// Returns true if user chose "Oui" (Create session), false if "Non" (Proceed without session),
/// or null if dismissed.
Future<bool?> showNoSessionDialog(BuildContext context) {
  return showFDialog<bool>(
    context: context,
    builder: (context, style, animation) => FDialog(
      animation: animation,
      builder: (context, dialogStyle) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(FLucideIcons.mountain, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('sessions.noSessionDialogTitle'),
                    style: dialogStyle.titleTextStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('sessions.noSessionDialogBody'),
              style: dialogStyle.bodyTextStyle,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => Navigator.of(context).pop(false),
                  child: Text(context.tr('common.no')),
                ),
                const SizedBox(width: 12),
                FButton(
                  onPress: () => Navigator.of(context).pop(true),
                  child: Text(context.tr('common.yes')),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
