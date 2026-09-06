// @date 2026-09-07
// @file login_page.dart
// @brief Page de connexion avec composants Forui.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/accessibility/accessibility_announcer.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/features/profile/presentation/pages/settings_page.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context);
    bool valid = true;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _emailError = l10n.t('auth.requiredField');
      valid = false;
    } else if (!email.contains('@')) {
      _emailError = l10n.t('auth.invalidEmail');
      valid = false;
    } else {
      _emailError = null;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      _passwordError = l10n.t('auth.requiredField');
      valid = false;
    } else {
      _passwordError = null;
    }

    setState(() {});
    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await AuthService().saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String? ?? '',
        userId: data['user_id'] as String,
        email: _emailController.text.trim(),
      );
      if (mounted) {
        AccessibilityAnnouncer.announce(
          context,
          AppLocalizations.of(context).t('auth.connectionSuccess'),
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
    if (msg.contains('401') || msg.contains('403')) {
      return l10n.t('auth.connectionErrorCredentials');
    }
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return l10n.t('auth.connectionErrorServer');
    }
    return l10n.t('auth.connectionErrorGeneric');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typo = context.theme.typography;
    final colors = context.theme.colors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Tooltip(
            message: l10n.t('common.settings'),
            child: IconButton(
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
                    l10n.t('auth.login.title'),
                    style: typo.display.xl2.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('auth.login.subtitle'),
                    style: typo.body.sm.copyWith(color: colors.mutedForeground),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FTextField(
                    control: FTextFieldControl.managed(
                      controller: _emailController,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    label: const Text('Email'),
                    hint: 'nom@exemple.com',
                    description: Text(l10n.t('auth.login.emailHelper')),
                    error: _emailError != null ? Text(_emailError!) : null,
                  ),
                  const SizedBox(height: 16),
                  FTextField.password(
                    control: FTextFieldControl.managed(
                      controller: _passwordController,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmit: (_) => _submit(),
                    label: Text(l10n.t('auth.login.password')),
                    hint: '••••••••',
                    description: Text(l10n.t('auth.login.passwordHelper')),
                    error: _passwordError != null
                        ? Text(_passwordError!)
                        : null,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    FAlert(
                      variant: .destructive,
                      title: Text(_errorMessage!),
                      icon: const Icon(Icons.error_outline),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: _isLoading ? null : _submit,
                      prefix: _isLoading
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      child: Text(l10n.t('auth.login.submit')),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.t('auth.login.noAccount'),
                        style: typo.body.sm.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text(
                          l10n.t('auth.login.register'),
                          style: typo.body.sm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
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
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return Semantics(
      container: true,
      label: l10n.t('common.logoAscension'),
      child: Column(
        children: [
          Image.asset('assets/images/logo.png', width: 72, height: 72),
          const SizedBox(height: 12),
          Text(
            'ASCENSION',
            style: typo.display.xl.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}
