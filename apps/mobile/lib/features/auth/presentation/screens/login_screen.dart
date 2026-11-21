// @date 2026-11-13
// @file login_screen.dart
// @brief Login screen with Forui components, validation, error feedback, autofill, and biometric sign-in.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/core/services/biometric_service.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
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
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSavedIdentifierAndBiometrics();
    });
  }

  Future<void> _initSavedIdentifierAndBiometrics() async {
    final storage = ref.read(secureStorageServiceProvider);
    final savedId = await storage.getSavedIdentifier();
    if (savedId != null && _identifierController.text.isEmpty && mounted) {
      _identifierController.text = savedId;
    }

    final biometricService = ref.read(biometricServiceProvider);
    final canUseBio = await biometricService.hasSavedBiometrics();

    if (mounted) {
      setState(() {
        _canUseBiometrics = canUseBio;
      });
      if (canUseBio) {
        unawaited(_authenticateWithBiometrics());
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final biometricService = ref.read(biometricServiceProvider);
    final authenticated = await biometricService.authenticate(
      localizedReason: context.tr('auth.biometricPrompt'),
    );

    if (authenticated && mounted) {
      final storage = ref.read(secureStorageServiceProvider);
      final identifier =
          await storage.getSavedIdentifier() ??
          _identifierController.text.trim();
      final password = await biometricService.getSavedPassword();

      if (identifier.isNotEmpty && password != null && password.isNotEmpty) {
        _identifierController.text = identifier;
        _passwordController.text = password;
        await ref
            .read(authFormControllerProvider.notifier)
            .login(
              identifier: identifier,
              password: password,
              remember: _rememberMe,
            );
      }
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    // FocusScope.of(context).unfocus();

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
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (errorMessage != null) ...[
                        FAlert(
                          variant: FAlertVariant.destructive,
                          title: Text(errorMessage),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FTextField(
                        control: FTextFieldControl.managed(
                          controller: _identifierController,
                        ),
                        label: Text(context.tr('auth.identifier')),
                        hint: 'climber@ascension.app',
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
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
                        autofillHints: const [AutofillHints.password],
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
                      if (_canUseBiometrics) ...[
                        const SizedBox(height: 12),
                        FButton(
                          variant: FButtonVariant.outline,
                          prefix: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(FLucideIcons.fingerprint, size: 20),
                          ),
                          onPress: isLoading
                              ? null
                              : _authenticateWithBiometrics,
                          child: Text(context.tr('auth.biometricSignIn')),
                        ),
                      ],
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
      ),
    );
  }
}
