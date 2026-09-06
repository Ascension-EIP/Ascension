---
name: forui-styling
description: Customize Forui widget styles. Use when applying style deltas, FVariants, variant constraints, generated style files, FStyle, border radius, icon size, per-widget styles, custom icons in theme data, or shadcn-like unpacking decisions.
metadata:
  date: "2026-06-13"
---

# Forui Styling

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. For generated style APIs, check the current installed `forui` version because generated style names and fields can change across pre-1.0 releases.

## Choose The Smallest Ownership Level

1. Use a widget `style: .delta(...)` for local, narrow tweaks.
2. Generate a style file with `fvm dart run forui style create <style>` for repeated or app-owned widget styling.
3. Generate a theme when colors, typography, icon defaults, and multiple widget styles must move together.
4. Use `dart pub unpack forui` only when taking full ownership of behavior, accessibility, gestures, and layout.

## Best Practices

- Start with semantic intent: disabled, destructive, selected, focused, hovered, pressed, touch, or desktop. Then choose the smallest style surface that represents it.
- Use deltas when preserving defaults is valuable; use generated styles when repeated state logic would otherwise be copied between widgets.
- Keep variant changes deterministic. Prefer explicit `.exact(...)` for new state combinations and `.match(...)` only when modifying existing related states.
- Keep component styling close to the theme module, not scattered across feature screens, once it becomes reusable.
- Review accessibility states visually and with keyboard focus, not only in the default enabled state.

## Anti-Patterns

- Do not replace a whole style object to change one color or spacing value.
- Do not put unrelated product layout decisions into a widget style; styles should describe the component, not the page.
- Do not unpack Forui just to change colors, typography, border radii, icons, or ordinary widget state styling.

## Deltas

Use deltas to preserve the existing Forui defaults:

```dart
FAccordion(
  style: .delta(focusedOutlineStyle: .delta(color: Colors.blue)),
  children: const [],
);
```

Prefer deltas over complete style replacement unless the design intentionally replaces the whole style object.

## Variants

- Use `FVariants` for state-specific styling such as hovered, focused, pressed, disabled, selected, error, and platform variants.
- Treat semantic states as stronger than interaction states, and interaction states as stronger than platform states.
- Use `.base(...)` for default changes, `.exact(...)` for one precise state combination, and `.match(...)` for existing variants containing a state.

## Generated Styles

- Run `fvm dart run forui style ls` before choosing a style name.
- Put generated styles in the project location chosen by the Forui CLI unless the app already has a theme module convention.
- After generating, wire the style through the relevant widget or theme and delete obsolete hand-built styling paths.

## Reference Samples

Read `references/examples.md` when writing deltas, variants, or generated style functions.

## Verification

Run format, analyze, and visual inspection when hover, focus, disabled, selected, or error states changed.
