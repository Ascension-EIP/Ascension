// @date 2026-09-07
// @file forui_profile_view.dart
// @brief Vue de profil utilisant le kit d'interface Forui (duobaseio/forui).
// @project Ascension
// @author Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/features/upload/presentation/pages/analysis_page.dart';
import 'package:mobile/shared/components/interactive_circular_gauge.dart';
import 'package:mobile/shared/localization/app_localizations.dart';
import 'package:mobile/shared/theme/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ForuiProfileView extends StatefulWidget {
  final List<AnalysisHistoryEntry>? history;
  final Future<void> Function() onRefresh;
  final VoidCallback onProfileUpdated;

  const ForuiProfileView({
    super.key,
    required this.history,
    required this.onRefresh,
    required this.onProfileUpdated,
  });

  @override
  State<ForuiProfileView> createState() => _ForuiProfileViewState();
}

class _ForuiProfileViewState extends State<ForuiProfileView> {
  Future<void> _openEditSheet() async {
    final result = await showFSheet<bool>(
      context: context,
      side: FLayout.btt,
      builder: (sheetContext) =>
          _ForuiEditProfileSheet(onSaved: widget.onProfileUpdated),
    );

    if (result == true) {
      widget.onProfileUpdated();
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        animation: animation,
        builder: (dialogCtx, dialogStyle) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('profile.logoutTitle'),
                style: dialogStyle.titleTextStyle,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('profile.logoutPrompt'),
                style: dialogStyle.bodyTextStyle,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.t('profile.cancel')),
                  ),
                  const SizedBox(width: 10),
                  FButton(
                    variant: FButtonVariant.destructive,
                    onPress: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.t('profile.logoutTitle')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = FThemeData(
      colors: isDark ? FColors.neutralDark : FColors.neutralLight,
      touch: true,
    );

    return FTheme(
      data: theme,
      child: Builder(
        builder: (fContext) {
          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ForuiUserCard(onEdit: _openEditSheet)
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 24),
                  _ForuiStatsSection(history: widget.history)
                      .animate()
                      .fadeIn(
                        duration: 400.ms,
                        delay: 100.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 24),
                  _ForuiRecentAnalyses(history: widget.history)
                      .animate()
                      .fadeIn(
                        duration: 400.ms,
                        delay: 200.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 32),
                  _ForuiLogoutButton(onLogout: _logout)
                      .animate()
                      .fadeIn(
                        duration: 400.ms,
                        delay: 300.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class _ForuiUserCard extends StatelessWidget {
  final VoidCallback onEdit;

  const _ForuiUserCard({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final username = auth.username;
    final email = auth.email;

    final displayName =
        username ?? email?.split('@').first ?? l10n.t('profile.defaultUser');
    final initials = _initials(displayName);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.card.withValues(alpha: 0.9),
            colors.muted.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colors.primary, const Color(0xFF10B981)],
              ),
            ),
            child: FAvatar.raw(
              size: 52,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: typography.display.sm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.foreground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FBadge(child: const Text('Grimpeur')),
                  ],
                ),
                if (email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: l10n.t('profile.editProfile'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: FButton.icon(
                variant: FButtonVariant.outline,
                onPress: onEdit,
                child: const Icon(FLucideIcons.pencil, size: 16),
              ),
            ),
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

class _ForuiEditProfileSheet extends StatefulWidget {
  final VoidCallback onSaved;

  const _ForuiEditProfileSheet({required this.onSaved});

  @override
  State<_ForuiEditProfileSheet> createState() => _ForuiEditProfileSheetState();
}

class _ForuiEditProfileSheetState extends State<_ForuiEditProfileSheet> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  String? _usernameError;
  String? _emailError;
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

  bool _validate() {
    final l10n = AppLocalizations.of(context);
    bool valid = true;
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    if (username.isNotEmpty && username.length < 3) {
      setState(() => _usernameError = l10n.t('auth.register.usernameMin3'));
      valid = false;
    } else {
      setState(() => _usernameError = null);
    }

    if (email.isNotEmpty && !email.contains('@')) {
      setState(() => _emailError = l10n.t('auth.invalidEmail'));
      valid = false;
    } else {
      setState(() => _emailError = null);
    }

    return valid;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    await AuthService().updateProfile(
      username: username.isNotEmpty ? username : null,
      email: email.isNotEmpty ? email : null,
    );

    if (mounted) {
      widget.onSaved();
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.mutedForeground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.t('profile.editProfile'),
            style: typography.display.sm.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mettez à jour vos informations de compte',
            style: typography.body.xs.copyWith(color: colors.mutedForeground),
          ),
          const SizedBox(height: 20),
          FTextField(
            control: FTextFieldControl.managed(controller: _usernameController),
            label: Text(l10n.t('profile.username')),
            hint: 'ex: AlexHonnold',
            error: _usernameError != null ? Text(_usernameError!) : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          FTextField(
            control: FTextFieldControl.managed(controller: _emailController),
            label: const Text('Email'),
            hint: 'nom@domaine.com',
            error: _emailError != null ? Text(_emailError!) : null,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmit: (_) => _save(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FButton(
              variant: FButtonVariant.primary,
              onPress: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.t('profile.save')),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FButton(
              variant: FButtonVariant.outline,
              onPress: () => Navigator.of(context).pop(false),
              child: Text(l10n.t('profile.cancel')),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats section ─────────────────────────────────────────────────────────────

class _ForuiStatsSection extends StatelessWidget {
  final List<AnalysisHistoryEntry>? history;

  const _ForuiStatsSection({required this.history});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final entries = history ?? [];
    final total = entries.length;
    final completed = entries.where((e) => e.isCompleted).toList();
    final successRate = total == 0 ? 0.0 : (completed.length / total) * 100;
    final avgDetection = completed.isEmpty
        ? 0.0
        : completed.map((e) => e.detectionRate).reduce((a, b) => a + b) /
              completed.length;

    return Container(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.t('profile.globalStats'),
                  style: typography.display.sm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(FLucideIcons.activity, size: 18, color: colors.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('profile.hoverHint'),
            style: typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 18),
          Skeletonizer(
            enabled: history == null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: InteractiveCircularGauge(
                    value: total > 0 ? (total / 10).clamp(0.0, 1.0) : 0.0,
                    displayValue: history == null ? '0' : '$total',
                    label: l10n.t('profile.analyses'),
                    icon: FLucideIcons.chartColumn,
                    color: colors.primary,
                    size: 82,
                    strokeWidth: 6,
                    tooltipText: '$total analyses enregistrées',
                  ),
                ),
                Expanded(
                  child: InteractiveCircularGauge(
                    value: total == 0 ? 0.0 : (completed.length / total),
                    displayValue: history == null
                        ? '0%'
                        : '${successRate.toStringAsFixed(0)}%',
                    label: l10n.t('profile.successes'),
                    icon: FLucideIcons.checkCircle,
                    color: const Color(0xFF10B981),
                    size: 82,
                    strokeWidth: 6,
                    tooltipText:
                        '${completed.length}/$total réussies (${successRate.toStringAsFixed(0)}%)',
                  ),
                ),
                Expanded(
                  child: InteractiveCircularGauge(
                    value: (avgDetection / 100).clamp(0.0, 1.0),
                    displayValue: history == null
                        ? '0%'
                        : '${avgDetection.toStringAsFixed(0)}%',
                    label: l10n.t('profile.detection'),
                    icon: FLucideIcons.user,
                    color: const Color(0xFF0EA5E9),
                    size: 82,
                    strokeWidth: 6,
                    tooltipText:
                        'Précision IA : ${avgDetection.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent analyses ───────────────────────────────────────────────────────────

class _ForuiRecentAnalyses extends StatelessWidget {
  final List<AnalysisHistoryEntry>? history;

  const _ForuiRecentAnalyses({required this.history});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final entries = history ?? [];
    final recent = entries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.t('profile.latestAnalyses'),
              style: typography.display.sm.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.foreground,
              ),
            ),
            if (recent.isNotEmpty) FBadge(child: Text('${entries.length}')),
          ],
        ),
        const SizedBox(height: 12),
        if (history == null)
          Skeletonizer(
            enabled: true,
            child: Column(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  _ForuiMiniAnalysisCard(
                    entry: AnalysisHistoryEntry(
                      analysisId: 'placeholder-$i',
                      createdAt: DateTime.now(),
                      status: 'completed',
                      processingTimeMs: 1200,
                      resultJson: '{"frames":[{"pose_detected":true}]}',
                    ),
                  ),
                  if (i < 2) const SizedBox(height: 10),
                ],
              ],
            ),
          )
        else if (recent.isEmpty)
          const _ForuiEmptyState()
        else
          Column(
            children: [
              for (int i = 0; i < recent.length; i++) ...[
                _ForuiMiniAnalysisCard(entry: recent[i])
                    .animate()
                    .fadeIn(
                      duration: 350.ms,
                      delay: (60 * i).ms,
                      curve: Curves.easeOutCubic,
                    )
                    .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                if (i < recent.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}

class _ForuiEmptyState extends StatelessWidget {
  const _ForuiEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Icon(FLucideIcons.video, size: 36, color: colors.mutedForeground),
              const SizedBox(height: 12),
              Text(
                l10n.t('profile.emptyTitle'),
                style: typography.body.md.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.t('profile.emptySubtitle'),
                style: typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForuiMiniAnalysisCard extends StatelessWidget {
  final AnalysisHistoryEntry entry;

  const _ForuiMiniAnalysisCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final isCompleted = entry.isCompleted;
    final statusColor = isCompleted ? AppColors.success : colors.destructive;

    return Container(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted
                              ? FLucideIcons.check
                              : FLucideIcons.circleAlert,
                          color: statusColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _formatDate(context, entry.createdAt),
                                  style: typography.body.sm.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.foreground,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FBadge(
                                  variant: isCompleted
                                      ? FBadgeVariant.primary
                                      : FBadgeVariant.destructive,
                                  child: Text(
                                    isCompleted ? 'Terminée' : 'Échouée',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            if (isCompleted && entry.frameCount > 0)
                              Text(
                                l10n.tr('profile.framesDetected', {
                                  'frames': '${entry.frameCount}',
                                  'rate': entry.detectionRate.toStringAsFixed(
                                    0,
                                  ),
                                }),
                                style: typography.body.xs.copyWith(
                                  color: colors.mutedForeground,
                                ),
                              )
                            else
                              Text(
                                isCompleted
                                    ? l10n.t('profile.analysisCompleted')
                                    : l10n.t('profile.analysisFailed'),
                                style: typography.body.xs.copyWith(
                                  color: isCompleted
                                      ? colors.mutedForeground
                                      : statusColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isCompleted && entry.resultJson != null)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: FButton.icon(
                            variant: FButtonVariant.ghost,
                            onPress: () {
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
                            child: Icon(
                              FLucideIcons.circlePlay,
                              color: colors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _ForuiLogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _ForuiLogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      child: FButton(
        variant: FButtonVariant.destructive,
        onPress: onLogout,
        prefix: const Icon(FLucideIcons.logOut, size: 18),
        child: Text(l10n.t('profile.logoutAction')),
      ),
    );
  }
}
