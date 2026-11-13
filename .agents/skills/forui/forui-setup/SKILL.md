---
name: forui-setup
description: Set up Forui in a Flutter app. Use when installing Forui, adding package:forui, wiring FTheme, FToaster, FTooltipGroup, FLocalizations, MaterialApp or CupertinoApp integration, FScaffold, or migrating an app root from Material/Cupertino to Forui.
metadata:
  date: "2026-06-13"
---

# Forui Setup

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. For version-sensitive APIs, first check the project's pinned `forui` version and, when the snapshot may be stale, verify against current Forui docs or pub.dev before editing.

## Workflow

1. Inspect `pubspec.yaml`, `.fvmrc` or `.fvm/`, and the current app root before editing.
2. Use FVM for Flutter commands: `fvm flutter ...` and `fvm dart ...`.
3. Add Forui with `fvm flutter pub add forui` when it is missing.
4. Import `package:forui/forui.dart` where Forui widgets or theme data are used.
5. Place `FTheme` below `MaterialApp`, `CupertinoApp`, or `WidgetsApp` through the app `builder`.
6. Add `FToaster` near the root when any toast can be shown.
7. Add `FTooltipGroup` near the root when tooltips are used.
8. Use a hard cutover at the app-root boundary. Replace the touched setup instead of keeping parallel Material-only and Forui-only roots.

## Best Practices

- Keep the app root boring: one app widget, one selected `FThemeData`, and one `builder` chain that wraps `FTheme`, `FToaster`, and `FTooltipGroup`.
- Select theme brightness and touch/desktop density explicitly instead of relying on implicit platform defaults.
- Preserve the app's existing router, localization, analytics, and error boundaries while replacing only the UI-provider layer.
- Make Material interop intentional: call `toApproximateMaterialTheme()` while Material widgets remain, then remove it when the app no longer uses Material theming.
- Keep `FScaffold` adoption screen-scoped unless the whole app shell is being replaced.

## Anti-Patterns

- Do not place `FTheme` below individual pages when the app has shared Forui widgets, toasts, tooltips, or navigation.
- Do not install `forui_assets` in addition to `forui` just to use bundled icons; `forui` already includes them.
- Do not leave duplicate app roots or theme providers as a compatibility path after migration.
- Do not assume a `^0.x.y` constraint will automatically pick up breaking pre-1.0 Forui changes.

## App Root Pattern

Choose an explicit theme. Forui does not switch light and dark automatically.

```dart
final theme = FThemes.neutral.light.touch;

return MaterialApp(
  supportedLocales: FLocalizations.supportedLocales,
  localizationsDelegates: const [...FLocalizations.localizationsDelegates],
  theme: theme.toApproximateMaterialTheme(),
  builder: (context, child) => FTheme(
    data: theme,
    child: FToaster(
      child: FTooltipGroup(child: child!),
    ),
  ),
  home: const FScaffold(child: HomePage()),
);
```

## Material And Cupertino Interop

- Keep Material or Cupertino widgets when they still fit the app, but put Forui theme setup at the root so Forui widgets render consistently.
- Use `toApproximateMaterialTheme()` when Material widgets remain and should visually align with Forui.
- Prefer `FScaffold` for Forui-first screens. Keep `Scaffold` only when the touched screen depends on Material-specific behavior.

## Reference Samples

Read `references/examples.md` when implementing an app-root migration, router setup, or package upgrade path.

## Verification

- Run `fvm dart format` on changed Dart files.
- Run `fvm flutter analyze`.
- Run targeted tests when setup changes affect navigation, localization, or app boot.
