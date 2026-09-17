# Forui CLI Examples

## Safe Generation Plan

1. Inspect existing files:

```bash
git status --short
rg -n "FTheme|FThemes|toApproximateMaterialTheme|accordionStyle" lib pubspec.yaml
```

2. Discover available outputs:

```bash
fvm dart run forui snippet ls
fvm dart run forui style ls
fvm dart run forui theme ls
fvm dart run forui snippet create material-theme --output .dart_tool/forui_cli_probe/material_theme.dart --force
```

3. Generate the smallest needed surface:

```bash
fvm dart run forui style create accordion
```

4. Review and wire the generated file:

```bash
git diff -- lib/theme lib
fvm dart format lib
fvm flutter analyze
```

## Choosing Commands

- App root missing Forui providers: `init`.
- Need editable Material theme mapping: `snippet create material-theme`.
- One widget family needs custom states: `style create <style>`.
- Whole design system should be app-owned: `theme create <theme>`.

## Windows FVM Probe

As of the 2026-06-13 snapshot, the example app verified these commands on Windows with FVM and Forui 0.22.3:

```bash
fvm dart run forui --help
fvm dart run forui snippet ls
fvm dart run forui style ls
fvm dart run forui theme ls
```

Observed snippets:

```text
icon-mapping
main-basic
main-router
material-theme
```

Observed theme families include blue, green, neutral, orange, red, rose, slate, violet, yellow, zinc, and their light/dark variants. The style list is intentionally broad; run `style ls` before generating instead of copying a stale list into a task.
