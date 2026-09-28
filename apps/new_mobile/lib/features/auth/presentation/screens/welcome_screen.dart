// @date 2026-09-29
// @file welcome_screen.dart
// @brief Welcome / Landing screen for authentication with logo and action buttons.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:new_mobile/core/l10n/app_localizations.dart';
import 'package:new_mobile/routing/routes.dart';

/// Landing screen welcoming unauthenticated climbers with branding and sign in / sign up entrypoints.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FScaffold(
      child: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  // Ascension logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        FLucideIcons.mountain,
                        size: 96,
                        color: theme.colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // "Ascension"
                  Text(
                    context.tr('common.appName'),
                    textAlign: TextAlign.center,
                    style: theme.typography.display.xl.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stylized slogan
                  Text(
                    context.tr('auth.slogan'),
                    textAlign: TextAlign.center,
                    style: theme.typography.body.md.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Sign In button
                  FButton(
                    onPress: () => context.goNamed(AppRoute.login.name),
                    child: Text(context.tr('auth.signIn')),
                  ),
                  const SizedBox(height: 14),
                  // Sign Up button
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => context.goNamed(AppRoute.register.name),
                    child: Text(context.tr('auth.signUp')),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
