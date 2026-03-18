import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/accessibility/accessibility_announcer.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/features/profile/presentation/pages/settings_page.dart';
import 'package:mobile/shared/localization/app_localizations.dart';
import 'package:mobile/shared/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.t('common.settings'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
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
                  _Logo(),
                  const SizedBox(height: 40),
                  Text(
                    l10n.t('auth.login.title'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('auth.login.subtitle'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            helperText: l10n.t('auth.login.emailHelper'),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return l10n.t('auth.requiredField');
                            }
                            if (!v.contains('@')) {
                              return l10n.t('auth.invalidEmail');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l10n.t('auth.login.password'),
                            helperText: l10n.t('auth.login.passwordHelper'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? l10n.t('auth.login.showPassword')
                                  : l10n.t('auth.login.hidePassword'),
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
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n.t('auth.requiredField');
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
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.t('auth.login.submit')),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.t('auth.login.noAccount'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          l10n.t('auth.login.register'),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
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
    return Semantics(
      container: true,
      label: l10n.t('common.logoAscension'),
      child: Column(
        children: [
          Image.asset('assets/images/logo.png', width: 72, height: 72),
          const SizedBox(height: 12),
          const Text(
            'ASCENSION',
            style: TextStyle(
              color: AppColors.primary,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
