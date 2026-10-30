// @date 2026-10-30
// @file login_screen.dart
// @brief Login screen with Forui components, validation, and error feedback.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/auth/presentation/controllers/auth_form_controller.dart';
import 'package:mobile/routing/routes.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _identifierError = _identifierController.text.trim().isEmpty
          ? context.tr('auth.requiredField')
          : null;
      _passwordError = _passwordController.text.isEmpty
          ? context.tr('auth.requiredField')
          : null;
    });

    if (_identifierError == null && _passwordError == null) {
      ref
          .read(authFormControllerProvider.notifier)
          .login(
            identifier: _identifierController.text.trim(),
            password: _passwordController.text,
            remember: _rememberMe,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(authFormControllerProvider);
    final isLoading = formState.isLoading;
    final errorMessage = formState.hasError ? formState.error.toString() : null;

    return FScaffold(
      header: FHeader.nested(
        title: Text(context.tr('auth.signIn')),
        prefixes: [
          FHeaderAction.back(
            onPress: isLoading
                ? null
                : () => context.goNamed(AppRoute.welcome.name),
          ),
        ],
      ),
      child: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorMessage != null) ...[
                      FAlert(
                        variant: FAlertVariant.destructive,
                        title: Text(errorMessage),
                      ),
                      const SizedBox(height: 20),
                    ],
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _identifierController,
                      ),
                      label: Text(context.tr('auth.identifier')),
                      hint: 'climber@ascension.app',
                      error: _identifierError != null
                          ? Text(_identifierError!)
                          : null,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    FTextField.password(
                      control: FTextFieldControl.managed(
                        controller: _passwordController,
                      ),
                      label: Text(context.tr('auth.password')),
                      error: _passwordError != null
                          ? Text(_passwordError!)
                          : null,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.done,
                      onSubmit: (_) => _validateAndSubmit(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FCheckbox(
                              value: _rememberMe,
                              onChange: isLoading
                                  ? null
                                  : (value) =>
                                        setState(() => _rememberMe = value),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => setState(
                                      () => _rememberMe = !_rememberMe,
                                    ),
                              child: Text(
                                context.tr('auth.rememberMe'),
                                style: context.theme.typography.body.sm,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                                  // Non-functional placeholder for forgot password
                                },
                          child: Text(
                            context.tr('auth.forgotPassword'),
                            style: context.theme.typography.body.sm.copyWith(
                              color: context.theme.colors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    FButton(
                      onPress: isLoading ? null : _validateAndSubmit,
                      prefix: isLoading
                          ? const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: FCircularProgress(
                                size: FCircularProgressSizeVariant.sm,
                              ),
                            )
                          : null,
                      child: Text(context.tr('auth.signIn')),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.tr('auth.noAccount'),
                          style: context.theme.typography.body.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => context.goNamed(AppRoute.register.name),
                          child: Text(
                            context.tr('auth.register'),
                            style: context.theme.typography.body.sm.copyWith(
                              color: context.theme.colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
