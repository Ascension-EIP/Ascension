# Forui Setup Examples

## Existing MaterialApp With Router

Keep the router and replace only the provider layer:

```dart
class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = _themeForPlatform();

    return MaterialApp.router(
      routerConfig: router,
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: const [...FLocalizations.localizationsDelegates],
      theme: theme.toApproximateMaterialTheme(),
      builder: (context, child) => FTheme(
        data: theme,
        child: FToaster(
          child: FTooltipGroup(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
```

## Platform Density Selection

```dart
FThemeData _themeForPlatform() {
  final touch = switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.fuchsia => true,
    _ => false,
  };

  return touch ? FThemes.neutral.light.touch : FThemes.neutral.light.desktop;
}
```

## Upgrade Checklist

- Run `fvm flutter --version` and confirm the Flutter SDK satisfies the Forui requirement.
- Run `fvm flutter pub upgrade forui --major-versions` for pre-1.0 minor upgrades.
- Run `fvm dart fix --apply` when Forui data-driven fixes are available.
- Re-run format, analyze, and app boot after generated fixes.
