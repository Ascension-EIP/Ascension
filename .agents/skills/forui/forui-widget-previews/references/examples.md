# Forui Widget Preview Examples

## Full App Preview

Use a full app preview when the surface depends on routing, overlay roots, and provider scopes.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';

import 'main.dart';

@Preview(
  group: 'Forui app',
  name: 'Example app',
  size: Size(430, 840),
)
Widget foruiAppPreview() {
  return const ProviderScope(child: MyForuiApp());
}
```

## Shared Forui Wrapper

Use a shared wrapper when previewing individual Forui widgets.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:forui/forui.dart';

@Preview(
  group: 'Forui components',
  name: 'Alert',
  size: Size(420, 220),
  wrapper: foruiPreviewWrapper,
)
Widget foruiAlertPreview() {
  return FAlert(
    title: const Text('Saved'),
    subtitle: const Text('Preview wrappers provide Forui ancestors.'),
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
      child: FToaster(child: FTooltipGroup(child: child)),
    ),
  );
}
```

## Riverpod State

Override providers in the wrapper when the preview needs filled state.

```dart
Widget previewStateWrapper(Widget child) {
  return ProviderScope(
    overrides: [
      submittedProjectProvider.overrideWith((ref) => 'Preview project'),
    ],
    child: foruiPreviewWrapper(child),
  );
}
```

## Verification

```bash
fvm dart format lib
fvm flutter analyze
fvm flutter test
fvm flutter widget-preview start --web-server
```

Stop the previewer after it prints a local URL or after confirming the first error. Do not leave the long-running process active.
