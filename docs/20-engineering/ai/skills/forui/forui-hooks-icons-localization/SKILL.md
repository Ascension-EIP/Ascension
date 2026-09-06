---
name: forui-hooks-icons-localization
description: Use Forui hooks, icons, and localization. Use when adding flutter_hooks integration for Forui controllers, FLucideIcons, FIcons, custom icon widgets, forui_assets icon-only usage, FLocalizations, supportedLocales, localizationsDelegates, or localized Forui widgets.
metadata:
  date: "2026-06-13"
---

# Forui Hooks, Icons, And Localization

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. Verify current `forui_hooks`, `forui_assets`, and localization APIs before adding dependencies or changing generated localization setup.

## Hooks

- Use Forui hook helpers when the app already uses `flutter_hooks` and a Forui controller must be created with widget lifecycle safety.
- Keep hook-created controllers inside hook widgets.
- Do not introduce hooks only to avoid disposing one controller in a normal stateful widget.

## Best Practices

- Add `forui_hooks` only when the project already uses hooks or when several Forui controllers would otherwise make lifecycle code noisy.
- Keep hooks local to hook widgets. Do not leak hook-owned controllers into long-lived services.
- Prefer theme-level `FIcons` customization when replacing an icon family across the app.
- Keep product copy in the app localization layer and Forui widget chrome in `FLocalizations`.
- Merge localization delegates deliberately so adding Forui does not drop app, Material, or Cupertino localizations.

## Anti-Patterns

- Do not add hooks as a workaround for unclear controller ownership; fix ownership first.
- Do not override the same icon repeatedly at call sites when a theme-level icon mapping exists.
- Do not add `forui_assets` when the full `forui` package is already installed only for widgets.
- Do not replace app translations with Forui built-in localization; they solve different problems.

## Icons

- Use `FLucideIcons` exclusively for all application and Forui iconography. It is bundled and directly exported by `import 'package:forui/forui.dart';`.
- **Anti-Pattern**: NEVER use `Icons.*` from Flutter Material (outdated visual design, clashes with Forui).
- **No extra dependency needed**: Do NOT add `lucide_icons` or `flutter_phosphor_icons`; `FLucideIcons` already contains the full Lucide catalogue.
- Use `FIcons` in `FThemeData` to swap default icons across Forui widgets if global customization is needed.
- Add `forui_assets` only when a sub-package wants Lucide icons without importing the full `forui` widget library.
- See `references/polish-guidelines.md` in `forui-best-practices` for the complete icon replacement table.

## Localization

Wire Forui localization at the app root:

```dart
MaterialApp(
  supportedLocales: FLocalizations.supportedLocales,
  localizationsDelegates: const [...FLocalizations.localizationsDelegates],
);
```

Merge Forui delegates with the app's existing localization delegates when the app has its own translations.

## Migration Rules

- Replace scattered icon overrides with theme-level icon configuration when the same icon choice repeats.
- Replace one-off localized strings in Forui widgets with the app's localization source when the text is product copy.
- Keep Forui-provided localization delegates for built-in widget text.

## Reference Samples

Read `references/examples.md` when adding hooks, icon overrides, or localization delegate setup.

## Verification

Check icon rendering, missing glyphs, supported locales, locale switching, and controller disposal when hooks are involved.
