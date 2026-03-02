import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? titleColor;
  final bool centerTitle;
  final String? description;
  final Color? descriptionColor;
  final String? logoPath;

  const Header({
    super.key,
    required this.title,
    this.titleColor,
    this.centerTitle = false,
    this.description,
    this.descriptionColor,
    this.logoPath,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(description != null ? 100 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle,
      toolbarHeight: description != null ? 100 : kToolbarHeight,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: titleColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          if (description != null)
            SizedBox(
              height: 46,
              child: Text(
                description!,
                style: TextStyle(
                  fontSize: 18,
                  color:
                      descriptionColor ??
                      Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      actions: [
        if (logoPath != null)
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Image.asset(logoPath!, width: 75, height: 75),
          ),
      ],
    );
  }
}
