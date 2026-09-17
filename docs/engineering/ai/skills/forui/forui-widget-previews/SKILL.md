---
name: forui-widget-previews
description: Add and validate Flutter Widget Previewer coverage for Forui UI. Use when creating @Preview annotations, previewing Forui widgets in Chrome, checking Windows/FVM preview support, wrapping previews with FTheme/FToaster/FTooltipGroup/FLocalizations/ProviderScope, or documenting preview limitations.
metadata:
  date: "2026-06-13"
---

# Forui Widget Previews

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. Flutter Widget Previewer is experimental; before adding nontrivial preview infrastructure, run `fvm flutter widget-preview start --help` and check the pinned Flutter SDK docs or local `package:flutter/widget_previews.dart` API.

## Rules

- Use FVM: run preview commands as `fvm flutter widget-preview start`.
- Keep previews under `lib/` so the previewer can discover them.
- Import `package:flutter/widget_previews.dart` only in preview files or preview-specific annotations.
- Preview targets must be public top-level functions, public static methods, or public no-required-argument constructors/factories that return `Widget` or `WidgetBuilder`.
- Wrap Forui previews with the same root ancestors the widget requires: `FTheme`, `FToaster`, `FTooltipGroup`, `FLocalizations`, and any app state scope such as `ProviderScope`.
- Prefer preview wrappers over duplicating setup in every preview.
- Keep preview state web-safe. Do not invoke `dart:io`, `dart:ffi`, native plugins, or platform channels from previewed widgets.

## Best Practices

- Add previews next to the component or in a small `lib/previews.dart` file for small example apps.
- Preview the smallest useful surface. Use a full routed app preview only when the behavior depends on routing, overlays, or provider scope.
- Give every preview a clear `group`, `name`, and stable `size` so the rendered frame is predictable.
- Use `Preview.wrapper` for shared Forui setup and app state injection.
- Use `Preview.theme` only for Material/Cupertino theme data; Forui's `FThemeData` still needs an `FTheme` wrapper.
- Add multiple previews for important states: empty, filled, error, disabled, narrow, and wide.
- Keep annotations const-friendly: referenced callbacks must be public and static/top-level.
- Treat preview code as checked source. Run format, analyze, widget tests, and a short previewer launch after adding it.

## Workflow

1. Confirm the project uses Flutter 3.35 or newer; IDE support needs 3.38 or newer.
2. Run `fvm flutter widget-preview start --help` to confirm the command exists in the pinned SDK.
3. Identify the Forui ancestors and state scopes required by the widget.
4. Add a public preview target with `@Preview`.
5. Add a public wrapper function when the widget needs `FTheme`, `FToaster`, localization, or app state.
6. Run `fvm dart format lib`, `fvm flutter analyze`, and tests affected by the UI.
7. Launch `fvm flutter widget-preview start --web-server` or `fvm flutter widget-preview start` long enough to confirm the previewer starts.

## Windows Notes

- Windows support depends on the pinned Flutter SDK and Chrome availability, not on a Windows desktop build target.
- `fvm flutter doctor -v` should show a Chrome web device.
- If Chrome auto-launch is disruptive, start with `fvm flutter widget-preview start --web-server` and open the printed local URL manually.
- If a preview fails only in the previewer, check for web-incompatible APIs before changing the Forui widget itself.

## Example Shape

```dart
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:forui/forui.dart';

@Preview(
  group: 'Forui',
  name: 'Card - light',
  size: Size(420, 320),
  wrapper: foruiPreviewWrapper,
)
Widget foruiCardPreview() {
  return FCard(
    title: const Text('Previewed card'),
    child: const Text('Rendered through Flutter Widget Previewer.'),
  );
}

Widget foruiPreviewWrapper(Widget child) {
  final theme = FThemes.neutral.light.desktop;

  return MaterialApp(
    supportedLocales: FLocalizations.supportedLocales,
    localizationsDelegates: const [...FLocalizations.localizationsDelegates],
    theme: theme.toApproximateMaterialTheme(),
    home: FTheme(
      data: theme,
      child: FToaster(
        child: FTooltipGroup(child: child),
      ),
    ),
  );
}
```

## Reference Samples

Read `references/examples.md` when adding preview wrappers, Riverpod state, GoRouter previews, or Windows verification notes.
