// @date 2026-10-25
// @file settings_screen.dart
// @brief Settings screen allowing user preferences, biometrics toggle, and logout.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/core/services/biometric_service.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/presentation/controllers/auth_state.dart';
import 'package:mobile/routing/routes.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBiometricSupported = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBiometricSettings();
    });
  }

  Future<void> _loadBiometricSettings() async {
    final biometricService = ref.read(biometricServiceProvider);
    final isSupported = await biometricService.isDeviceSupported();
    final isEnabled = await biometricService.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _isBiometricSupported = isSupported;
        _isBiometricEnabled = isEnabled;
      });
    }
  }

  Future<String?> _promptPasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    return showFDialog<String>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        builder: (context, dialogStyle) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('settings.biometricsPasswordTitle'),
                style: dialogStyle.titleTextStyle,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('settings.biometricsPasswordPrompt'),
                style: dialogStyle.bodyTextStyle,
              ),
              const SizedBox(height: 16),
              FTextField.password(
                control: FTextFieldControl.managed(controller: controller),
                hint: context.tr('auth.password'),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(context).pop(null),
                    child: Text(context.tr('common.cancel')),
                  ),
                  const SizedBox(width: 12),
                  FButton(
                    onPress: () => Navigator.of(context).pop(controller.text),
                    child: Text(context.tr('common.save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    final biometricService = ref.read(biometricServiceProvider);
    final storage = ref.read(secureStorageServiceProvider);

    if (value) {
      final authenticated = await biometricService.authenticate(
        localizedReason: context.tr('settings.biometricsEnablePrompt'),
      );
      if (!authenticated) return;

      final existingPassword = await biometricService.getSavedPassword();
      if (existingPassword != null && existingPassword.isNotEmpty) {
        await biometricService.setBiometricEnabled(true);
        if (mounted) {
          setState(() => _isBiometricEnabled = true);
        }
      } else {
        if (!mounted) return;
        final password = await _promptPasswordDialog(context);
        if (password != null && password.isNotEmpty) {
          final identifier = await storage.getSavedIdentifier() ?? '';
          await biometricService.saveBiometricCredentials(
            identifier: identifier,
            password: password,
          );
          if (mounted) {
            setState(() => _isBiometricEnabled = true);
          }
        }
      }
    } else {
      await biometricService.disableBiometric();
      if (mounted) {
        setState(() => _isBiometricEnabled = false);
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    await ref.read(authStateProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: Text(context.tr('settings.title')),
        prefixes: [
          FHeaderAction.back(
            onPress: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AppRoute.profile.name);
              }
            },
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isBiometricSupported) ...[
                    FTileGroup(
                      description: Text(
                        context.tr('settings.biometricsSubtitle'),
                      ),
                      children: [
                        FTile(
                          prefix: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(FLucideIcons.fingerprint, size: 20),
                          ),
                          title: Text(context.tr('settings.biometrics')),
                          suffix: FSwitch(
                            value: _isBiometricEnabled,
                            onChange: _toggleBiometric,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 16),
                  FButton(
                    variant: FButtonVariant.destructive,
                    prefix: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(FLucideIcons.logOut, size: 18),
                    ),
                    onPress: _logout,
                    child: Text(context.tr('settings.logout')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
