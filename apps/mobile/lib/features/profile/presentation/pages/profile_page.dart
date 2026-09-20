// @date 2026-09-07
// @file profile_page.dart
// @brief Page de profil utilisateur propulsée par Forui.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/auth/auth_service.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/core/services/analysis_history_service.dart';
import 'package:mobile/features/profile/presentation/pages/settings_page.dart';
import 'package:mobile/features/profile/presentation/widgets/forui_profile_view.dart';
import 'package:mobile/shared/components/header.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: Header(
        title: l10n.t('profile.title'),
        actions: [
          Tooltip(
            message: l10n.t('common.settings'),
            child: IconButton(
              icon: const Icon(FLucideIcons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
          ),
        ],
      ),
      body: ForuiProfileView(
        history: _history,
        onRefresh: _loadHistory,
        onProfileUpdated: _loadProfile,
      ),
    );
  }
}
