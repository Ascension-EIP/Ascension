---
name: forui-best-practices
description: Review or plan Forui best practices across a Flutter app. Use when the task asks for Forui best practices, architecture guidance, migration strategy, design-system structure, code review, risk assessment, or which focused Forui skill to use.
metadata:
  date: "2026-06-13"
---

# Forui Best Practices

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. If the project has a newer or older pinned `forui` version, verify current Forui docs and the installed package API before giving version-sensitive advice.

## Routing

- Use `forui-setup` for installation, app roots, `FTheme`, `FToaster`, `FTooltipGroup`, localization delegates, and `FScaffold`.
- Use `forui-cli` for generated app roots, snippets, styles, themes, and material mapping.
- Use `forui-theming` for `FThemeData`, theme variants, breakpoints, Material interop, and theme extensions.
- Use `forui-styling` for deltas, `FVariants`, generated style functions, and unpacking decisions.
- Use `forui-controls` for lifted/managed controls, external controllers, programmatic control, and lifecycle ownership.
- Use `forui-forms-inputs` for fields, selects, validation, async options, and form state.
- Use `forui-layout-navigation` for shells, navigation, responsive layout, tabs, breadcrumbs, pagination, and resizable panes.
- Use `forui-overlays-feedback` for dialogs, sheets, popovers, menus, tooltips, toasts, overlays, and dismiss behavior.
- Use `forui-content-components` for cards, tiles, items, accordions, alerts, badges, avatars, progress, and custom primitives.
- Use `forui-hooks-icons-localization` for `forui_hooks`, `FLucideIcons`, `FIcons`, `forui_assets`, and `FLocalizations`.
- Use `forui-widget-previews` for Flutter Widget Previewer annotations, Forui preview wrappers, and Windows/FVM preview validation.

## Cross-Cutting Standards

- Prefer hard cutover at the touched boundary. Remove the old Material/Cupertino implementation instead of keeping a compatibility branch.
- Use FVM for Flutter and Dart commands.
- Treat Forui as a design system: theme first, then generated styles, then local deltas, then custom primitives.
- Strict Polish standards: NEVER use `Icons.*` (Material) — use `FLucideIcons` exclusively. Never use isolated full-screen `CircularProgressIndicator` — use `Skeletonizer` for layout-preserving shimmering states. Use `flutter_animate` for staggered entrance transitions and micro-interactions. Read `references/polish-guidelines.md`.
- Keep state ownership explicit: route state, app state, form state, control state, and controller state should not compete.
- Preserve accessibility, focus, keyboard traversal, and disabled/error/destructive states when customizing.
- Keep generated code project-owned. Review generated diffs and delete obsolete hand-written equivalents.
- Keep docs small and task-specific. Do not add `llms-full.txt` or broad scraped docs to the skill repository.

## Review Checklist

- App root has one Forui provider path and no duplicate theme authority.
- Theme brightness and touch/desktop density are explicit.
- Material interop is deliberate and removable.
- UI Polish: No raw `Icons.*` in Forui screens (`FLucideIcons` only). Asynchronous loading surfaces use `Skeletonizer` instead of spinners. Entrances use declarative `flutter_animate` without manual `AnimationController`.
- Widget choice matches the user task, not just the desired shape.
- Long option lists have search or autocomplete; async lists have loading, empty, and error states.
- Overlays have defined dismiss behavior and root ancestors.
- Repeated styling lives in theme/generated style files; local deltas stay local.
- Tests or manual checks cover narrow/wide layout, keyboard focus, validation, and overlay close paths where relevant.
- Widget previews cover reusable Forui components or high-risk composed surfaces without calling native-only APIs.

## Reference Samples

- Read `references/polish-guidelines.md` for iconography rules (`FLucideIcons`), entrance micro-animations (`flutter_animate`), and modern loading states (`Skeletonizer`).
- Read `references/review-template.md` when producing a Forui architecture review or migration plan.
