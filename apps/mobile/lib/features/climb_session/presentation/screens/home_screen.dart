// @date 2026-11-13
// @file home_screen.dart
// @brief Dashboard home screen with active session status banner.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/climb_session/presentation/controllers/climb_session_controller.dart';
import 'package:mobile/routing/routes.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(climbSessionControllerProvider);
    final activeSession = sessionState.activeSession;

    return FScaffold(
      header: FHeader(title: Text(context.tr('home.title'))),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (activeSession != null) ...[
                  GestureDetector(
                    onTap: () => context.pushNamed(AppRoute.activeSession.name),
                    child: FCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(FLucideIcons.mountain, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr('home.currentSession'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context
                                              .theme
                                              .typography
                                              .body
                                              .sm
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          activeSession.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context
                                              .theme
                                              .typography
                                              .body
                                              .xs
                                              .copyWith(
                                                color: context
                                                    .theme
                                                    .colors
                                                    .mutedForeground,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FBadge(
                              variant: FBadgeVariant.primary,
                              child: Text(
                                '${context.tr('sessions.since')} ${sessionState.formattedActiveDuration}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05),
                  const SizedBox(height: 24),
                ],
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      const Icon(FLucideIcons.house, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('home.welcome'),
                        style: context.theme.typography.body.md.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
