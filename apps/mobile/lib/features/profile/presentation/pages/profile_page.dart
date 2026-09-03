// @date 2026-09-03
// @file profile_page.dart
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/features/upload/presentation/pages/analysis_page.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/shared/components/header.dart';
import 'package:mobile/shared/localization/app_localizations.dart';
import 'package:mobile/shared/theme/app_colors.dart';
import 'package:mobile/features/profile/presentation/pages/settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<AnalysisHistoryEntry>? _history;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadHistory();
  }

  Future<void> _loadProfile() async {
    final userId = AuthService().userId;
    if (userId == null) return;
    try {
      final data = await ApiService().getUser(userId);
      await AuthService().syncFromApi(data);
      if (mounted) setState(() {});
    } catch (_) {
      // Silently fall back to locally cached data
    }
  }

  Future<void> _loadHistory() async {
    final userId = AuthService().userId;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _history = []);
      return;
    }
    final entries = await AnalysisHistoryService().getHistory(userId);
    if (!mounted) return;
    setState(() => _history = entries);
  }

  Future<void> _openEditSheet() async {
    final result = await showShadSheet<bool>(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (_) => const _EditProfileSheet(),
    );
    if (result == true) setState(() {});
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog.alert(
        title: Text(l10n.t('profile.logoutTitle')),
        description: Text(l10n.t('profile.logoutPrompt')),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('profile.cancel')),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('profile.logoutTitle')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: Header(
        title: l10n.t('profile.title'),
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
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserCard(onEdit: _openEditSheet),
              const SizedBox(height: 24),
              _StatsSection(history: _history),
              const SizedBox(height: 24),
              _RecentAnalyses(history: _history, onViewAll: () {}),
              const SizedBox(height: 32),
              _LogoutButton(onLogout: _logout),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final VoidCallback onEdit;
  const _UserCard({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final username = auth.username;
    final email = auth.email;

    final displayName =
        username ?? email?.split('@').first ?? l10n.t('profile.defaultUser');
    final initials = _initials(displayName);

    return ShadCard(
      border: ShadBorder.all(
        color: theme.colorScheme.primary.withValues(alpha: 0.2),
      ),
      child: Row(
        children: [
          _Avatar(initials: initials),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: theme.textTheme.h4),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: theme.textTheme.muted,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          ShadIconButton.ghost(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'[\s_\-]+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

// ── Edit profile sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<ShadFormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = AuthService();
    _usernameController = TextEditingController(text: auth.username ?? '');
    _emailController = TextEditingController(text: auth.email ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.saveAndValidate()) return;
    setState(() => _saving = true);

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    await AuthService().updateProfile(
      username: username.isNotEmpty ? username : null,
      email: email.isNotEmpty ? email : null,
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);

    return ShadSheet(
      title: Text(l10n.t('profile.editProfile')),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.t('profile.cancel')),
        ),
        ShadButton(
          onPressed: _saving ? null : _save,
          leading: _saving
              ? SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primaryForeground,
                  ),
                )
              : null,
          child: Text(l10n.t('profile.save')),
        ),
      ],
      child: ShadForm(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShadInputFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              label: Text(l10n.t('profile.username')),
              leading: const Icon(Icons.person_outline),
              validator: (v) {
                if (v.trim().isNotEmpty && v.trim().length < 3) {
                  return l10n.t('auth.register.usernameMin3');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ShadInputFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              label: const Text('Email'),
              leading: const Icon(Icons.email_outlined),
              validator: (v) {
                if (v.trim().isNotEmpty && !v.contains('@')) {
                  return l10n.t('auth.invalidEmail');
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary,
      ),
      child: Center(
        child: Text(
          initials,
          style: theme.textTheme.h4.copyWith(
            color: theme.colorScheme.primaryForeground,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ── Stats section ─────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final List<AnalysisHistoryEntry>? history;
  const _StatsSection({required this.history});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final entries = history ?? [];
    final total = entries.length;
    final completed = entries.where((e) => e.isCompleted).toList();
    final avgDetection = completed.isEmpty
        ? 0.0
        : completed.map((e) => e.detectionRate).reduce((a, b) => a + b) /
              completed.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('profile.globalStats'), style: theme.textTheme.h4),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.analytics_outlined,
                value: '$total',
                label: l10n.t('profile.analyses'),
                color: theme.colorScheme.primary,
                loading: history == null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline_rounded,
                value: '${completed.length}',
                label: l10n.t('profile.successes'),
                color: AppColors.success,
                loading: history == null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.person_outline_rounded,
                value: '${avgDetection.toStringAsFixed(0)}%',
                label: l10n.t('profile.detection'),
                color: AppColors.warning,
                loading: history == null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool loading;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: ShadBorder.all(color: color.withValues(alpha: 0.2)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          loading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Text(value, style: theme.textTheme.h4.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.small),
        ],
      ),
    );
  }
}

// ── Recent analyses ───────────────────────────────────────────────────────────

class _RecentAnalyses extends StatelessWidget {
  final List<AnalysisHistoryEntry>? history;
  final VoidCallback onViewAll;

  const _RecentAnalyses({required this.history, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final entries = history ?? [];
    final recent = entries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('profile.latestAnalyses'), style: theme.textTheme.h4),
        const SizedBox(height: 12),
        if (history == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (recent.isEmpty)
          const _EmptyState()
        else
          Column(
            children: [
              for (final entry in recent) ...[
                _MiniAnalysisCard(entry: entry),
                if (entry != recent.last) const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return ShadCard(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.videocam_outlined,
            size: 40,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(height: 10),
          Text(l10n.t('profile.emptyTitle'), style: theme.textTheme.p),
          const SizedBox(height: 4),
          Text(l10n.t('profile.emptySubtitle'), style: theme.textTheme.small),
        ],
      ),
    );
  }
}

class _MiniAnalysisCard extends StatelessWidget {
  final AnalysisHistoryEntry entry;
  const _MiniAnalysisCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final isCompleted = entry.isCompleted;
    final statusColor = isCompleted
        ? AppColors.success
        : theme.colorScheme.destructive;

    return ShadCard(
      padding: const EdgeInsets.all(14),
      border: ShadBorder.all(color: statusColor.withValues(alpha: 0.2)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(context, entry.createdAt),
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (isCompleted && entry.frameCount > 0)
                  Text(
                    l10n.tr('profile.framesDetected', {
                      'frames': '${entry.frameCount}',
                      'rate': entry.detectionRate.toStringAsFixed(0),
                    }),
                    style: theme.textTheme.small,
                  )
                else
                  Text(
                    isCompleted
                        ? l10n.t('profile.analysisCompleted')
                        : l10n.t('profile.analysisFailed'),
                    style: theme.textTheme.small.copyWith(
                      color: isCompleted ? null : statusColor,
                    ),
                  ),
              ],
            ),
          ),
          if (isCompleted && entry.resultJson != null)
            ShadIconButton.ghost(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AnalysisViewPage(
                      resultJson: entry.resultJson!,
                      processingMs: entry.processingTimeMs,
                      videoFile: null,
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.play_circle_outline_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(dt);
    final time = '${_pad(dt.hour)}:${_pad(dt.minute)}';
    if (diff.inDays == 0) {
      return l10n.tr('date.todayAt', {'time': time});
    } else if (diff.inDays == 1) {
      return l10n.tr('date.yesterdayAt', {'time': time});
    } else if (diff.inDays < 7) {
      final days = [
        l10n.t('date.dayShort.monday'),
        l10n.t('date.dayShort.tuesday'),
        l10n.t('date.dayShort.wednesday'),
        l10n.t('date.dayShort.thursday'),
        l10n.t('date.dayShort.friday'),
        l10n.t('date.dayShort.saturday'),
        l10n.t('date.dayShort.sunday'),
      ];
      return '${days[dt.weekday - 1]} ${_pad(dt.day)}/${_pad(dt.month)}';
    } else {
      return "${_pad(dt.day)}/${_pad(dt.month)}/${dt.year}";
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

// ── Logout button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destructive = ShadTheme.of(context).colorScheme.destructive;
    return ShadButton.outline(
      width: double.infinity,
      foregroundColor: destructive,
      leading: const Icon(Icons.logout_rounded, size: 18),
      onPressed: onLogout,
      child: Text(l10n.t('profile.logoutAction')),
    );
  }
}
