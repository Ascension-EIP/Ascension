// @date 2026-09-03
// @file header.dart
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
    final theme = ShadTheme.of(context);
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
              style: theme.textTheme.h2.copyWith(color: titleColor),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            if (description != null)
              SizedBox(
                height: 46,
                child: Text(
                  description!,
                  style: theme.textTheme.p.copyWith(color: descriptionColor),
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
            padding: EdgeInsets.only(right: 16),
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
