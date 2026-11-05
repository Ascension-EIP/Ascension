// @date 2026-10-25
// @file app_shell.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';

/// Root application shell with 4 persistent Forui bottom navigation destinations:
/// Home, Sessions, Training, and Profile.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      footer: FBottomNavigationBar(
        index: navigationShell.currentIndex,
        onChange: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        children: [
          FBottomNavigationBarItem(
            icon: const Icon(FLucideIcons.house),
            label: Text(context.tr('nav.home')),
          ),
          FBottomNavigationBarItem(
            icon: const Icon(FLucideIcons.mountain),
            label: Text(context.tr('nav.sessions')),
          ),
          FBottomNavigationBarItem(
            icon: const Icon(FLucideIcons.dumbbell),
            label: Text(context.tr('nav.training')),
          ),
          FBottomNavigationBarItem(
            icon: const Icon(FLucideIcons.user),
            label: Text(context.tr('nav.profile')),
          ),
        ],
      ),
      child: navigationShell,
    );
  }
}
