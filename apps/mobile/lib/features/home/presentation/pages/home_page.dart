// @date 2026-09-03
// @file home_page.dart
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:mobile/shared/components/header.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: Header(
        title: 'Ascension',
        description: l10n.t('home.description'),
        descriptionColor: theme.colorScheme.primary,
        logoPath: 'assets/images/logo.png',
      ),
      body: Center(
        child: Text(l10n.t('home.comingSoon'), style: theme.textTheme.p),
      ),
    );
  }
}
