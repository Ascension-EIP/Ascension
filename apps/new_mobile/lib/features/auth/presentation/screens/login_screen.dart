// @date 2026-09-25
// @file login_screen.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:new_mobile/core/l10n/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: Text(context.tr('auth.login')),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FLucideIcons.mountain, size: 64),
            const SizedBox(height: 16),
            Text(
              context.tr('common.appName'),
              style: context.theme.typography.display.xl2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('auth.tagline'),
              style: context.theme.typography.body.sm.copyWith(color: context.theme.colors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
