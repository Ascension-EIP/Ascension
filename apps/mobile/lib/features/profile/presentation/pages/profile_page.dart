import 'package:flutter/material.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/features/upload/presentation/pages/analysis_page.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/shared/components/header.dart';
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
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditProfileSheet(),
    );
    if (result == true) setState(() {});
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Déconnexion'),
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
    return Scaffold(
      appBar: Header(
        title: 'Profil',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
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
    final username = auth.username;
    final email = auth.email;

    final displayName = username ?? email?.split('@').first ?? 'Utilisateur';
    final initials = _initials(displayName);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _Avatar(initials: initials),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Modifier le profil',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Modifier le profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Nom d'utilisateur",
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty && v.trim().length < 3) {
                  return 'Minimum 3 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty && !v.contains('@')) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ],
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
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
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
        const Text(
          'Statistiques globales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.analytics_outlined,
                value: '$total',
                label: 'Analyses',
                color: AppColors.primary,
                loading: history == null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline_rounded,
                value: '${completed.length}',
                label: 'Réussies',
                color: AppColors.success,
                loading: history == null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.person_outline_rounded,
                value: '${avgDetection.toStringAsFixed(0)}%',
                label: 'Détection',
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
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
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
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
    final entries = history ?? [];
    final recent = entries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dernières analyses',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (history == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (recent.isEmpty)
          _EmptyState()
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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.videocam_outlined, size: 40, color: Colors.grey[600]),
          const SizedBox(height: 10),
          Text(
            'Aucune analyse pour l\'instant',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Uploadez une vidéo pour commencer.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = entry.isCompleted;
    final statusColor = isCompleted ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
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
                  _formatDate(entry.createdAt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (isCompleted && entry.frameCount > 0)
                  Text(
                    '${entry.frameCount} frames · ${entry.detectionRate.toStringAsFixed(0)}% détecté',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  )
                else
                  Text(
                    isCompleted ? 'Analyse terminée' : 'Analyse échouée',
                    style: TextStyle(
                      fontSize: 11,
                      color: isCompleted ? Colors.grey[500] : AppColors.danger,
                    ),
                  ),
              ],
            ),
          ),
          if (isCompleted && entry.resultJson != null)
            IconButton(
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
              icon: const Icon(
                Icons.play_circle_outline_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return "Aujourd'hui à ${_pad(dt.hour)}:${_pad(dt.minute)}";
    } else if (diff.inDays == 1) {
      return "Hier à ${_pad(dt.hour)}:${_pad(dt.minute)}";
    } else if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return "${days[dt.weekday - 1]} ${_pad(dt.day)}/${_pad(dt.month)}";
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Se déconnecter'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
