import 'package:flutter/material.dart';
import 'package:mobile/shared/components/header.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: Header(
        title: 'Ascension',
        description: l10n.t('home.description'),
        descriptionColor: Color(0xFF00B5D3),
        logoPath: 'assets/images/logo.png',
      ),
      body: Center(child: Text(l10n.t('home.comingSoon'))),
    );
  }
}
