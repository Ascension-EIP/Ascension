---
name: forui-overlays-feedback
description: Implement Forui overlays and feedback. Use when working with showFDialog, FDialog, showFSheet, FModalSheetRoute, showFPersistentSheet, FSheets, FPopover, FPopoverMenu, FTooltip, showFToast, showRawFToast, FToast, FToaster, FOverlay, FPortal, modal barriers, or dismiss behavior.
metadata:
  date: "2026-06-13"
---

# Forui Overlays And Feedback

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. Verify current Forui overlay APIs when changing route behavior, sheet persistence, popover controls, or toast root setup.

## Root Requirements

- Add `FToaster` near the app root before using `showFToast` or `showRawFToast`.
- Add `FTooltipGroup` near the root for grouped tooltip behavior.
- Ensure persistent sheets are shown from a subtree with `FScaffold` or `FSheets`.

## Widget Choices

- Use `showFDialog` or `FDialog` for focused modal decisions.
- Use `showFSheet` for modal bottom or side surfaces.
- Use `showFPersistentSheet` for persistent sheet flows tied to screen state.
- Use `FPopover` for contextual anchored content.
- Use `FPopoverMenu` for anchored command menus.
- Use `FTooltip` for short explanatory hover/long-press text.
- Use `showFToast` for transient feedback and `showRawFToast` only when fully custom content is needed.
- Use `FOverlay` and `FPortal` for low-level placement only when higher-level components do not fit.

## Best Practices

- Match overlay weight to user intent: tooltip for help, toast for feedback, popover for contextual tools, sheet for focused side tasks, dialog for decisions.
- Decide ownership before coding: route-owned overlay, control-owned popover, or root-owned toaster.
- Keep dismiss behavior explicit and testable. Include outside tap, escape/back, swipe, and auto-dismiss where relevant.
- Keep overlays small enough to exit safely. Long forms and multi-step workflows usually belong in a page or sheet, not a dialog.
- Return outcomes through one path: await a route/dialog result, update lifted state, or dispatch an app event. Do not mix paths.

## Anti-Patterns

- Do not show a toast for information the user must act on or remember.
- Do not use dialogs as general layout containers.
- Do not stack independent modal overlays.
- Do not call toast or sheet APIs from a context that lacks the required root ancestor.
- Do not hide route changes inside overlay callbacks without reflecting state in navigation when it matters.

## Behavior Rules

- Define dismiss behavior deliberately: outside tap, barrier, swipe, escape/back, and auto-dismiss.
- Keep modal content focused. Move multi-step flows into pages or sheets.
- Preserve focus and keyboard access for dialogs, menus, and popovers.
- Avoid stacking unrelated overlays.

## Migration Rules

Replace the old overlay family at the touched boundary. Do not wrap a Material dialog in Forui styling when a Forui dialog or sheet is the intended new component.

## Reference Samples

Read `references/examples.md` when choosing overlay types or implementing result/dismiss behavior.

## Verification

Test open, close, outside tap, escape/back, keyboard focus, route interactions, and repeated show/dismiss calls.
