// @date 2026-09-07
// @file header.dart
// @brief Composant d'en-tête AppBar compatible Forui.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../localization/app_localizations.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? titleColor;
  final bool centerTitle;
  final String? description;
  final Color? descriptionColor;
  final String? logoPath;
  final List<Widget>? actions;

  const Header({
    super.key,
    required this.title,
    this.titleColor,
    this.centerTitle = false,
    this.description,
    this.descriptionColor,
    this.logoPath,
    this.actions,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(description != null ? 100 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final typo = context.theme.typography;
    final colors = context.theme.colors;

    return AppBar(
      centerTitle: centerTitle,
      toolbarHeight: description != null ? 100 : kToolbarHeight,
      title: Semantics(
        container: true,
        header: true,
        label: description == null ? title : '$title, $description',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: typo.display.xl2.copyWith(
                fontWeight: FontWeight.w700,
                color: titleColor ?? colors.foreground,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            if (description != null)
              SizedBox(
                height: 46,
                child: Text(
                  description!,
                  style: typo.body.sm.copyWith(
                    color: descriptionColor ?? colors.mutedForeground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
      actions: [
        ...?actions,
        if (logoPath != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Semantics(
              image: true,
              label: AppLocalizations.of(context).t('common.logoAscension'),
              child: Image.asset(logoPath!, width: 75, height: 75),
            ),
          ),
      ],
    );
  }
}
