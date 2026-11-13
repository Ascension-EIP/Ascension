---
name: forui-content-components
description: Use Forui content and display components. Use when implementing FCard, FTile, FTileGroup, FItem, FItemGroup, FAccordion, FAlert, FBadge, FAvatar, FCircularProgress, FDeterminateProgress, FProgress, FCollapsible, FFocusedOutline, FTappable, or display-oriented Forui widgets.
metadata:
  date: "2026-06-13"
---

# Forui Content Components

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. Check current Forui widget constructors when adding newer component variants or state-specific styling.

## Component Choices

- Use `FCard` for grouped content with a clear title, subtitle, or body.
- Use `FTile` and `FTileGroup` for settings-like rows and grouped actions.
- Use `FItem` and `FItemGroup` for item lists that need richer row content or grouping.
- Use `FAccordion` for optional sections that can expand and collapse.
- Use `FAlert` for important inline messages.
- Use `FBadge` for compact status or category labels.
- Use `FAvatar` for people, accounts, or entities.
- Use `FProgress`, `FDeterminateProgress`, and `FCircularProgress` for progress states.
- Use `FCollapsible`, `FFocusedOutline`, and `FTappable` when building custom components from Forui primitives.

## Best Practices

- Choose the component that matches the content contract: card for a standalone object, tile/item group for repeated rows, alert for inline status, badge for compact metadata.
- Keep repeated components structurally consistent. Titles, subtitles, details, suffix actions, and destructive states should appear in predictable positions.
- Use Forui primitives for custom interactive components only after checking whether a full component already exists.
- Keep empty, loading, disabled, destructive, and selected states visible without changing layout dimensions unexpectedly.
- Preserve semantics: a tappable row should have one clear action, and nested buttons should not compete with the row action unless the design demands it.

## Anti-Patterns

- Do not use cards as page sections when a simple layout container is enough.
- Do not put unrelated actions into a tile suffix just because space is available.
- Do not model progress with static text when a Forui progress widget communicates state better.
- Do not build custom gesture boxes when `FTappable` or a higher-level component handles interaction states.

## Composition Rules

- Use Forui components directly before recreating the same behavior from boxes and gestures.
- Keep actions visually and semantically attached to the component they affect.
- Prefer component variants and styles over ad hoc decoration.
- Keep repeated content in builders when the list can grow.

## State Rules

- Model loading, empty, disabled, destructive, selected, and error states explicitly.
- Use deterministic ordering for grouped rows and accordions.
- Keep destructive actions visually distinct with Forui destructive variants.

## Reference Samples

Read `references/examples.md` when choosing display components or reviewing repeated row/card patterns.

## Verification

Check focused, hovered, pressed, disabled, selected, loading, and empty states for the components touched.
