// @date 2026-09-29
// @file register_screen.dart
// @brief Registration screen with Forui components, validation, auto-generated username, and auto-login.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:new_mobile/core/l10n/app_localizations.dart';
import 'package:new_mobile/features/auth/presentation/controllers/auth_form_controller.dart';
import 'package:new_mobile/routing/routes.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameFocusNode = FocusNode();

  bool _isUsernameManuallyEdited = false;

  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_onNameChanged);
    _lastNameController.addListener(_onNameChanged);
    _usernameFocusNode.addListener(_onUsernameFocusChanged);
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onNameChanged);
    _lastNameController.removeListener(_onNameChanged);
    _usernameFocusNode.removeListener(_onUsernameFocusChanged);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  void _onUsernameFocusChanged() {
    if (_usernameFocusNode.hasFocus) {
      _isUsernameManuallyEdited = true;
    }
  }

  /// Normalizes a string by stripping accents and non-alphanumeric chars.
  static String _normalize(String input) {
    return removeDiacritics(input)
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  void _onNameChanged() {
    if (_isUsernameManuallyEdited) return;

    final first = _normalize(_firstNameController.text.trim());
    final last = _normalize(_lastNameController.text.trim());

    if (first.isNotEmpty && last.isNotEmpty) {
      _usernameController.text = '${first}_$last';
    } else if (first.isNotEmpty) {
      _usernameController.text = first;
    } else if (last.isNotEmpty) {
      _usernameController.text = last;
    } else {
      _usernameController.text = '';
    }
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _validateAndSubmit() {
    setState(() {
      _firstNameError = _firstNameController.text.trim().isEmpty
          ? context.tr('auth.requiredField')
          : null;
      _lastNameError = _lastNameController.text.trim().isEmpty
          ? context.tr('auth.requiredField')
          : null;
      _usernameError = _usernameController.text.trim().isEmpty
          ? context.tr('auth.requiredField')
          : null;

      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = context.tr('auth.requiredField');
      } else if (!_isEmailValid(email)) {
        _emailError = context.tr('auth.invalidEmail');
      } else {
        _emailError = null;
      }

      final password = _passwordController.text;
      _passwordError = password.isEmpty ? context.tr('auth.requiredField') : null;

      final confirmPassword = _confirmPasswordController.text;
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = context.tr('auth.requiredField');
      } else if (password != confirmPassword) {
        _confirmPasswordError = context.tr('auth.passwordsDoNotMatch');
      } else {
        _confirmPasswordError = null;
      }
    });

    final hasErrors = _firstNameError != null ||
        _lastNameError != null ||
        _usernameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null;

    if (!hasErrors) {
      ref.read(authFormControllerProvider.notifier).register(
            username: _usernameController.text.trim(),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
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
        title: Text(context.tr('auth.register')),
        prefixes: [
          FHeaderAction.back(
            onPress: isLoading ? null : () => context.goNamed(AppRoute.welcome.name),
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
                    // First Name and Last Name first!
                    Row(
                      children: [
                        Expanded(
                          child: FTextField(
                            control: FTextFieldControl.managed(
                              controller: _firstNameController,
                            ),
                            label: Text(context.tr('auth.firstName')),
                            error: _firstNameError != null ? Text(_firstNameError!) : null,
                            enabled: !isLoading,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FTextField(
                            control: FTextFieldControl.managed(
                              controller: _lastNameController,
                            ),
                            label: Text(context.tr('auth.lastName')),
                            error: _lastNameError != null ? Text(_lastNameError!) : null,
                            enabled: !isLoading,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Username (auto-suggested from First Name & Last Name)
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _usernameController,
                      ),
                      focusNode: _usernameFocusNode,
                      label: Text(context.tr('auth.username')),
                      hint: 'alex_climber',
                      error: _usernameError != null ? Text(_usernameError!) : null,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    // Email
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _emailController,
                      ),
                      label: Text(context.tr('auth.email')),
                      hint: 'climber@ascension.app',
                      error: _emailError != null ? Text(_emailError!) : null,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    // Password
                    FTextField.password(
                      control: FTextFieldControl.managed(
                        controller: _passwordController,
                      ),
                      label: Text(context.tr('auth.password')),
                      error: _passwordError != null ? Text(_passwordError!) : null,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    // Confirm Password
                    FTextField.password(
                      control: FTextFieldControl.managed(
                        controller: _confirmPasswordController,
                      ),
                      label: Text(context.tr('auth.confirmPassword')),
                      error: _confirmPasswordError != null ? Text(_confirmPasswordError!) : null,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.done,
                      onSubmit: (_) => _validateAndSubmit(),
                    ),
                    const SizedBox(height: 28),
                    // Submit button
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
                      child: Text(context.tr('auth.register')),
                    ),
                    const SizedBox(height: 20),
                    // Bottom link to Sign In
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.tr('auth.hasAccount'),
                          style: context.theme.typography.body.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => context.goNamed(AppRoute.login.name),
                          child: Text(
                            context.tr('auth.signIn'),
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
