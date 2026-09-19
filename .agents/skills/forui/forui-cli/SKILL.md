---
name: forui-cli
description: Use the Forui CLI in Flutter projects. Use when running or explaining dart run forui init, snippet create/list, style create/list, theme create/list, generated main.dart, generated theme/style files, or CLI-driven Forui customization.
metadata:
  date: "2026-06-13"
---

# Forui CLI

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. Before generating files for a pinned project, run the relevant `fvm dart run forui ... ls` command or check current docs because CLI templates and available snippets/styles/themes can change.

## Rules

- Use FVM: run Forui commands as `fvm dart run forui ...`.
- Inspect generated-file targets before using overwrite flags.
- Prefer CLI generation when the project needs editable Forui snippets, style files, or theme files.
- Treat generated files as project-owned after creation. Edit them directly and remove old competing code paths.

## Best Practices

- Treat CLI output as a scaffold, not an opaque dependency. Review the generated files before wiring them into the app.
- Run list commands before create commands so the skill does not invent snippet, style, or theme names.
- On Windows, prefer noninteractive discovery first: `fvm dart run forui --help`, `snippet ls`, `style ls`, and `theme ls` work without modifying files.
- Generate into the app's existing theme/module structure when it already has one; otherwise use the CLI defaults.
- Use `--force` only after checking the exact files that will be overwritten.
- Commit generated files together with the code that wires them in, so generated-but-unused files do not linger.

## Anti-Patterns

- Do not hand-copy large examples from docs when the CLI can generate the maintained template.
- Do not generate every style by default unless the project is deliberately taking ownership of all widget styling.
- Do not keep both generated mapping/theme files and old hand-written equivalents active.

## Commands

Initialize Forui files:

```bash
fvm dart run forui init
fvm dart run forui init --template=router
```

List and create snippets:

```bash
fvm dart run forui snippet ls
fvm dart run forui snippet create material-theme
```

List and create widget styles:

```bash
fvm dart run forui style ls
fvm dart run forui style create accordion
fvm dart run forui style create --all
```

List and create themes:

```bash
fvm dart run forui theme ls
fvm dart run forui theme create neutral
```

## When To Generate

- Use `init` for a new Forui root or when deliberately replacing the current root with a Forui-first root.
- Use `snippet create material-theme` when `toApproximateMaterialTheme()` is too generic and the Material theme mapping must be customized.
- Use `style create` when one widget family needs a project-wide visual language.
- Use `theme create` when colors, typography, style, and widget defaults should live in versioned app code.

## Reference Samples

Read `references/examples.md` when planning generated-file changes or reviewing a CLI-generated diff.

## Verification

Run `fvm dart format`, `fvm flutter analyze`, and any tests or app boot checks affected by the generated files.
