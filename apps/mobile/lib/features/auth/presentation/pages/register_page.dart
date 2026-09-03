// @date 2026-09-03
// @file register_page.dart
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:mobile/core/accessibility/accessibility_announcer.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/features/profile/presentation/pages/settings_page.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<ShadFormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService().register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await AuthService().saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String? ?? '',
        userId: data['user_id'] as String,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
      );
      if (mounted) {
        AccessibilityAnnouncer.announce(
          context,
          AppLocalizations.of(context).t('auth.registerSuccess'),
        );
      }
    } catch (e) {
      final parsed = _parseError(e);
      setState(() => _errorMessage = parsed);
      if (mounted) {
        AccessibilityAnnouncer.announce(context, parsed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(Object e) {
    final l10n = AppLocalizations.of(context);
    final msg = e.toString();
    if (msg.contains('409') || msg.contains('already')) {
      return l10n.t('auth.register.errorConflict');
    }
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return l10n.t('auth.connectionErrorServer');
    }
    return l10n.t('auth.connectionErrorGeneric');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Tooltip(
            message: l10n.t('common.settings'),
            child: ShadIconButton.ghost(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const _Logo(),
                  const SizedBox(height: 40),
                  Text(
                    l10n.t('auth.register.title'),
                    style: theme.textTheme.h3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('auth.register.subtitle'),
                    style: theme.textTheme.muted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ShadForm(
                    key: _formKey,
                    child: Column(
                      children: [
                        ShadInputFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          label: Text(l10n.t('auth.register.username')),
                          description: Text(
                            l10n.t('auth.register.usernameMin3'),
                          ),
                          leading: const Icon(Icons.person_outline),
                          validator: (v) {
                            if (v.trim().isEmpty) {
                              return l10n.t('auth.requiredField');
                            }
                            if (v.trim().length < 3) {
                              return l10n.t('auth.register.usernameMin3');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ShadInputFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          label: const Text('Email'),
                          description: Text(
                            l10n.t('auth.register.emailHelper'),
                          ),
                          leading: const Icon(Icons.email_outlined),
                          validator: (v) {
                            if (v.trim().isEmpty) {
                              return l10n.t('auth.requiredField');
                            }
                            if (!v.contains('@')) {
                              return l10n.t('auth.invalidEmail');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ShadInputFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          label: Text(l10n.t('auth.register.password')),
                          description: Text(
                            l10n.t('auth.register.passwordHelper'),
                          ),
                          leading: const Icon(Icons.lock_outline),
                          trailing: SizedBox.square(
                            dimension: 24,
                            child: OverflowBox(
                              maxWidth: 28,
                              maxHeight: 28,
                              child: ShadIconButton(
                                iconSize: 20,
                                padding: const EdgeInsets.all(2),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v.isEmpty) {
                              return l10n.t('auth.requiredField');
                            }
                            if (v.length < 8) {
                              return l10n.t('auth.passwordMin8');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ShadInputFormField(
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          label: Text(l10n.t('auth.register.confirmPassword')),
                          description: Text(
                            l10n.t('auth.register.confirmPasswordHelper'),
                          ),
                          leading: const Icon(Icons.lock_outline),
                          trailing: SizedBox.square(
                            dimension: 24,
                            child: OverflowBox(
                              maxWidth: 28,
                              maxHeight: 28,
                              child: ShadIconButton(
                                iconSize: 20,
                                padding: const EdgeInsets.all(2),
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v.isEmpty) {
                              return l10n.t('auth.requiredField');
                            }
                            if (v != _passwordController.text) {
                              return l10n.t('auth.register.passwordMismatch');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: _errorMessage!),
                  ],
                  const SizedBox(height: 24),
                  ShadButton(
                    width: double.infinity,
                    onPressed: _isLoading ? null : _submit,
                    leading: _isLoading
                        ? SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primaryForeground,
                            ),
                          )
                        : null,
                    child: Text(l10n.t('auth.register.submit')),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.t('auth.register.hasAccount'),
                        style: theme.textTheme.muted,
                      ),
                      ShadButton.link(
                        onPressed: () => context.go('/login'),
                        child: Text(l10n.t('auth.register.login')),
                      ),
                    ],
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

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return Semantics(
      container: true,
      label: l10n.t('common.logoAscension'),
      child: Column(
        children: [
          Image.asset('assets/images/logo.png', width: 72, height: 72),
          const SizedBox(height: 12),
          Text(
            'ASCENSION',
            style: theme.textTheme.large.copyWith(
              color: theme.colorScheme.primary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      label: l10n.tr('common.errorLabel', {'message': message}),
      child: ShadAlert.destructive(
        icon: const Icon(Icons.error_outline),
        description: Text(message),
      ),
    );
  }
}
