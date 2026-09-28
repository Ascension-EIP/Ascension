// @date 2026-09-29
// @file profile_screen.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:new_mobile/core/l10n/app_localizations.dart';
import 'package:new_mobile/routing/routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: Text(context.tr('profile.title')),
        suffixes: [
          FHeaderAction(
            icon: const Icon(FLucideIcons.settings),
            onPress: () => context.goNamed(AppRoute.settings.name),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FLucideIcons.user, size: 48),
            const SizedBox(height: 16),
            Text(
              context.tr('profile.climberProfile'),
              style: context.theme.typography.body.lg.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
