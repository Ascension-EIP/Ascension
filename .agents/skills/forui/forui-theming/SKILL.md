---
name: forui-theming
description: Work with Forui themes in Flutter. Use when choosing FThemes, FThemeData, FColors, FTypography, FIcons, FStyle, touch/desktop theme variants, breakpoints, context.theme, ThemeExtension, or Material theme interoperability.
metadata:
  date: "2026-06-13"
---

# Forui Theming

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. For version-sensitive theme APIs, compare this skill with the installed `forui` package and current Forui theme docs before changing generated theme files.

## Theme Selection

- Always choose brightness explicitly. Forui does not automatically manage light and dark themes.
- Use predefined themes when possible: neutral, zinc, slate, blue, green, orange, red, rose, violet, or yellow.
- Choose `touch` variants for Android, iOS, and Fuchsia targets.
- Choose `desktop` variants for Windows, macOS, and Linux targets.
- If a screen must adapt at runtime, branch on platform or app settings and pass the selected `FThemeData` into `FTheme`.

## Best Practices

- Make one `FThemeData` the source of truth for each active app mode, then derive Material interop, widget styles, and custom extensions from it.
- Keep color pairs together: when using a background color such as `primary`, use its matching foreground color for text/icons.
- Use `context.theme` at the leaf where a value is consumed instead of threading colors and typography through unrelated constructors.
- Keep density and platform choices separate from brand choices. A brand theme can still have touch and desktop variants.
- Prefer generated theme files when product design will keep evolving; prefer `copyWith()` for narrow app-specific additions.

## Anti-Patterns

- Do not compute random theme values inside `build` beyond simple platform or app-mode selection.
- Do not hardcode Material colors inside Forui widgets when matching `FColors` fields exist.
- Do not use `toApproximateMaterialTheme()` as the only source of custom Material mapping once the mapping needs exact product behavior.

## Accessing Theme Data

Use `context.theme` inside widgets:

```dart
final colors = context.theme.colors;
final typography = context.theme.typography;
final style = context.theme.style;
final icons = context.theme.icons;
```

Use `copyWith()` for small theme changes and generated theme files for broad ownership.

## Responsive Rules

- Use Forui breakpoints from `context.theme.breakpoints`.
- Pair breakpoints with `MediaQuery.sizeOf(context).width`.
- Keep adaptive layout decisions near the widget boundary they affect.

## Material Interop

- Use `theme.toApproximateMaterialTheme()` for a quick Material `ThemeData`.
- Generate and edit the material mapping snippet when Material interop needs exact app-specific mapping.
- Do not keep both an old Material theme and a new Forui theme as competing authorities after migration.

## Custom Theme Properties

Use Flutter `ThemeExtension` for app-specific theme values that Forui does not model. Keep those extensions small and pass them through the Material theme when Material widgets need them.

## Reference Samples

Read `references/examples.md` when adding platform density selection, app-specific theme extensions, or Material interop.

## Verification

Run format and analyze. For broad theme changes, smoke-test at least one light/dark and touch/desktop path when the app supports them.
