// @date 2026-11-13
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
  bool _initializedDefaultName = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedDefaultName && _nameController.text.isEmpty) {
      _initializedDefaultName = true;
      final locale = Localizations.localeOf(context).toString();
      final now = DateTime.now();
      if (locale.startsWith('fr')) {
        final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(now);
        _nameController.text = 'Session du ${dateStr.toLowerCase()}';
      } else {
        final dateStr = DateFormat('EEEE, MMMM d', 'en_US').format(now);
        _nameController.text = '$dateStr Session';
      }
    }
  }

  void _onNameChanged() {
    setState(() {});
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
    if (name.isEmpty) return;

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
    final isNameEmpty = _nameController.text.trim().isEmpty;

    return FScaffold(
      header: FHeader.nested(
        title: Text(context.tr('sessions.newSessionTitle')),
        prefixes: [
          FHeaderAction.back(onPress: isLoading ? null : () => context.pop()),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Session name
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _nameController,
                  ),
                  label: Text(context.tr('sessions.sessionNameLabel')),
                  hint: context.tr('sessions.sessionNameHint'),
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),

                // Location (Disabled for now as specified in Excalidraw)
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _locationController,
                  ),
                  label: Text(context.tr('sessions.sessionLocationLabel')),
                  description: Text(
                    context.tr('sessions.locationDisabledNote'),
                  ),
                  hint: context.tr('sessions.locationHint'),
                  enabled: false,
                ),
                const SizedBox(height: 20),

                // Visibility selector (Dropdown)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('sessions.sessionVisibilityLabel'),
                      style: context.theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    PopupMenuButton<ClimbSessionVisibility>(
                      initialValue: _visibility,
                      onSelected: isLoading
                          ? null
                          : (visibility) =>
                                setState(() => _visibility = visibility),
                      color: context.theme.colors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: context.theme.colors.border),
                      ),
                      itemBuilder: (context) =>
                          ClimbSessionVisibility.values.map((v) {
                            final isSelected = _visibility == v;
                            final icon = switch (v) {
                              ClimbSessionVisibility.public =>
                                FLucideIcons.globe,
                              ClimbSessionVisibility.friends =>
                                FLucideIcons.users,
                              ClimbSessionVisibility.private =>
                                FLucideIcons.lock,
                            };
                            return PopupMenuItem(
                              value: v,
                              child: Row(
                                children: [
                                  Icon(icon, size: 16),
                                  const SizedBox(width: 10),
                                  Text(
                                    context.tr(v.translationKey),
                                    style: context.theme.typography.body.sm
                                        .copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.theme.colors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.theme.colors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  switch (_visibility) {
                                    ClimbSessionVisibility.public =>
                                      FLucideIcons.globe,
                                    ClimbSessionVisibility.friends =>
                                      FLucideIcons.users,
                                    ClimbSessionVisibility.private =>
                                      FLucideIcons.lock,
                                  },
                                  size: 16,
                                  color: context.theme.colors.mutedForeground,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  context.tr(_visibility.translationKey),
                                  style: context.theme.typography.body.sm,
                                ),
                              ],
                            ),
                            const Icon(FLucideIcons.chevronDown, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Start button - disabled when session name is empty
                FButton(
                  onPress: (isLoading || isNameEmpty) ? null : _submit,
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
