# Forui Hooks, Icons, And Localization Examples

## Dependency Choices

| Need | Dependency |
| --- | --- |
| Forui widgets and bundled icons | `forui` |
| Icons only, no widgets | `forui_assets` |
| Hook-managed Forui controllers | `forui_hooks` plus `flutter_hooks` |

## Localization Merge Pattern

```dart
MaterialApp(
  supportedLocales: const [
    ...AppLocalizations.supportedLocales,
    ...FLocalizations.supportedLocales,
  ],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...FLocalizations.localizationsDelegates,
  ],
);
```

Adjust the exact merge to match the app's localization setup; do not duplicate locales if the app keeps a single canonical locale list.

## Review Checklist

- Hook dependencies match existing project architecture.
- Hook-owned controllers stay inside hook widgets.
- Icon changes are theme-level when repeated.
- Built-in Forui localization and product copy localization are both present.
