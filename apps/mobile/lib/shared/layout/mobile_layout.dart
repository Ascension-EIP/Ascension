import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile/core/accessibility/accessibility_settings_service.dart';
import 'package:mobile/features/home/presentation/pages/home_page.dart';
import 'package:mobile/features/upload/presentation/pages/upload_page.dart';
import 'package:mobile/features/stats/presentation/pages/stats_page.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  int _currentIndex = 0; // Home is the default page

  static const List<Widget> _pages = [
    HomePage(),
    UploadPage(),
    StatsPage(),
    ProfilePage(),
  ];

  static const List<_NavItemData> _items = [
    _NavItemData(
      icon: CupertinoIcons.house,
      selectedIcon: CupertinoIcons.house_fill,
      labelKey: 'nav.home',
    ),
    _NavItemData(
      icon: CupertinoIcons.cloud_upload,
      selectedIcon: CupertinoIcons.cloud_upload_fill,
      labelKey: 'nav.upload',
    ),
    _NavItemData(
      icon: CupertinoIcons.graph_square,
      selectedIcon: CupertinoIcons.graph_square_fill,
      labelKey: 'nav.stats',
    ),
    _NavItemData(
      icon: CupertinoIcons.person,
      selectedIcon: CupertinoIcons.person_solid,
      labelKey: 'nav.profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = AccessibilitySettingsService();

    return Scaffold(
      body: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: _CustomNavBar(
        currentIndex: _currentIndex,
        items: _items,
        reducedMotion: settings.reducedMotion,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;

  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
  });
}

class _CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItemData> items;
  final bool reducedMotion;
  final ValueChanged<int> onTap;

  const _CustomNavBar({
    required this.currentIndex,
    required this.items,
    required this.reducedMotion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 60,
        child: Row(
          children: List.generate(items.length, (index) {
            return Expanded(
              child: _NavItem(
                data: items[index],
                isSelected: index == currentIndex,
                reducedMotion: reducedMotion,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final _NavItemData data;
  final bool isSelected;
  final bool reducedMotion;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.reducedMotion,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.reducedMotion) {
      _controller.forward(from: 0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = l10n.t(widget.data.labelKey);
    final icon = Icon(
      widget.isSelected ? widget.data.selectedIcon : widget.data.icon,
      size: 32,
    );

    return Semantics(
      container: true,
      button: true,
      selected: widget.isSelected,
      label: l10n.tr('nav.semanticLabel', {'label': label}),
      hint: widget.isSelected
          ? l10n.t('nav.currentTabHint')
          : l10n.tr('nav.openTabHint', {'label': label}),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: InkWell(
          onTap: _onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.reducedMotion
                  ? icon
                  : ScaleTransition(scale: _scale, child: icon),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
