---
name: forui-layout-navigation
description: Build Forui app layout and navigation. Use when implementing FScaffold, FHeader, FBottomNavigationBar, FSidebar, FBreadcrumb, FPagination, FTabs, FResizable, FDivider, FTileGroup, FItemGroup, responsive shells, or navigation layout migration.
metadata:
  date: "2026-06-13"
---

# Forui Layout And Navigation

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. For navigation widgets and responsive APIs, check current Forui docs when the installed package version differs from the snapshot.

## App Shells

- Use `FScaffold` for Forui-first pages.
- Use `FHeader` for top app structure and nested headers for back or close flows.
- Use `FSidebar` for desktop or wide layouts with persistent navigation.
- Use `FBottomNavigationBar` for mobile primary destinations.
- Use `FTabs` for peer views inside one destination.

## Best Practices

- Start from information architecture: app destinations, page hierarchy, local tabs, and pagination are different navigation layers.
- Keep route state, selected nav item, and visible content derived from one source of truth.
- Use one primary navigation pattern per breakpoint: sidebar for wide layouts, bottom navigation for touch/narrow layouts, tabs for local peer content.
- Keep headers task-focused. Put global navigation in the shell and page-specific actions in the page.
- Use Forui breakpoints with stable layout constraints so resizing does not reorder stateful content unexpectedly.
- Convert Material shell families as a unit: scaffold, header/app bar, drawer/sidebar, bottom navigation, and tabs should not fight each other.

## Anti-Patterns

- Do not show sidebar and bottom navigation as competing primary nav on the same breakpoint.
- Do not encode current route separately in widget state and router state.
- Do not put pagination state only in UI if the page can be refreshed, shared, or deep-linked.
- Do not rebuild resizable panes with unstable keys that reset user sizes on every state change.

## Navigation Aids

- Use `FBreadcrumb` when users need location context in deeper hierarchies.
- Use `FPagination` for page-indexed content and pair it with the real page state.
- Keep route state and selected navigation state in one source of truth.

## Layout Primitives

- Use `FResizable` for user-adjustable split panes.
- Use `FDivider` for visual separation.
- Use `FTileGroup` or `FItemGroup` for repeated action/list rows.
- Prefer responsive branching with Forui breakpoints over duplicated screens.

## Responsive Rules

- Choose touch or desktop theme variants to match the target input mode.
- Collapse sidebars into sheets or bottom navigation on narrow layouts.
- Keep hit targets roomy on touch layouts and denser on desktop layouts.

## Migration Rules

When converting a Material layout, replace the touched scaffold/navigation family as a unit. Do not keep two competing nav models and hide one with conditionals.

## Reference Samples

Read `references/examples.md` when building responsive shells or mapping routes to Forui navigation state.

## Verification

Check narrow and wide layouts, selected nav state, back/close behavior, keyboard traversal, and resize persistence when applicable.
