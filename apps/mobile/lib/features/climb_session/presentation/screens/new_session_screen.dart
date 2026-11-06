// @date 2026-11-06
// @file new_session_screen.dart
// @brief Screen for configuring and starting a new climbing session.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/climb_session/domain/entities/climb_session.dart';
import 'package:mobile/features/climb_session/presentation/controllers/climb_session_controller.dart';
import 'package:mobile/routing/routes.dart';

class NewSessionScreen extends ConsumerStatefulWidget {
  const NewSessionScreen({super.key});

  @override
  ConsumerState<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends ConsumerState<NewSessionScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  ClimbSessionVisibility _visibility = ClimbSessionVisibility.friends;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(now);
    _nameController.text = 'Session du ${dateStr.toLowerCase()}';
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (_nameError != null && _nameController.text.trim().isNotEmpty) {
      setState(() => _nameError = null);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = context.tr('auth.requiredField');
      });
      return;
    }

    final success = await ref
        .read(climbSessionControllerProvider.notifier)
        .startSession(
          name: name,
          location: null, // Disabled for now as specified in Excalidraw
          visibility: _visibility,
        );

    if (success && mounted) {
      context.goNamed(AppRoute.activeSession.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(climbSessionControllerProvider);
    final isLoading = state.isLoading;

    return FScaffold(
      header: FHeader.nested(
        title: Text(context.tr('sessions.newSessionTitle')),
        prefixes: [
          FHeaderAction.back(onPress: isLoading ? null : () => context.pop()),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Session name
                Text(
                  context.tr('sessions.sessionNameLabel'),
                  style: context.theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _nameController,
                  ),
                  hint: context.tr('sessions.sessionNameHint'),
                  error: _nameError != null ? Text(_nameError!) : null,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),

                // Location (Disabled for now as specified in Excalidraw)
                Text(
                  context.tr('sessions.sessionLocationLabel'),
                  style: context.theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('sessions.locationDisabledNote'),
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _locationController,
                  ),
                  hint: context.tr('sessions.locationHint'),
                  enabled: false,
                ),
                const SizedBox(height: 24),

                // Visibility selector
                Text(
                  context.tr('sessions.sessionVisibilityLabel'),
                  style: context.theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ClimbSessionVisibility.values.map((v) {
                    final isSelected = _visibility == v;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FButton(
                          variant: isSelected
                              ? FButtonVariant.primary
                              : FButtonVariant.outline,
                          size: FButtonSizeVariant.sm,
                          onPress: isLoading
                              ? null
                              : () => setState(() => _visibility = v),
                          child: Text(v.label),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 48),

                // Start button
                FButton(
                  onPress: isLoading ? null : _submit,
                  prefix: isLoading
                      ? const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: FCircularProgress(
                            size: FCircularProgressSizeVariant.sm,
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(FLucideIcons.play, size: 16),
                        ),
                  child: Text(context.tr('sessions.startSessionButton')),
                ),
              ],
            ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0),
          ),
        ),
      ),
    );
  }
}
