---
name: forui-controls
description: Choose and wire Forui controls and controller ownership. Use when working with lifted controls, managed controls, internal controllers, external controllers, programmatic popovers or fields, state synchronization, lifecycle ownership, or Flutter Hooks with Forui controls.
metadata:
  date: "2026-06-13"
---

# Forui Controls

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. For controller constructors and hook names, check the installed `forui` and `forui_hooks` versions before editing code.

## Control Choice

Start with managed internal controls for simple UI:

```dart
FPopover(
  control: const .managed(initial: false),
  child: trigger,
  popoverBuilder: (context, style) => content,
);
```

Use lifted controls when app state owns the value:

```dart
FPopover(
  control: .lifted(
    shown: shown,
    onChange: (value) => setState(() => shown = value),
  ),
  child: trigger,
  popoverBuilder: (context, style) => content,
);
```

Use managed controls with an external controller when the code needs programmatic control or lifecycle integration.

## Best Practices

- Let ownership follow the data. Local UI state should be managed internally; shared or persisted state should be lifted.
- Keep lifted state pure: the parent provides the current value and handles changes; the widget should not maintain a second copy.
- Use external controllers only when code must call imperative methods, coordinate multiple widgets, or integrate with hooks/lifecycle helpers.
- Keep controller ownership visible in the widget that creates it. Creation and disposal should be easy to audit together.
- Prefer one control boundary per user-facing value. Avoid splitting one selection between control state, form state, and app state.

## Anti-Patterns

- Do not use lifted controls just because the parent can call `setState`; lift only when another part of the app needs the value.
- Do not create controllers inside `build`.
- Do not update lifted control values asynchronously without considering stale callbacks and mounted checks.
- Do not use both an external controller and separate provider state as competing authorities.

## Lifecycle Rules

- The owner that creates an external controller must dispose it.
- Prefer Flutter Hooks when the project already uses hooks and Forui exposes a matching hook.
- Keep lifted control callbacks small. Update state and let the widget rebuild from that state.
- Do not mix lifted and separately mutated controller state for the same value.

## Migration Rules

- Replace direct Flutter controller plumbing with Forui controls at the touched widget boundary.
- Remove old adapter state once the Forui control becomes the source of truth.
- Keep state in Riverpod, Bloc, or another app state layer only when the value is shared beyond the widget.

## Reference Samples

Read `references/examples.md` when deciding between managed, lifted, and external-controller patterns.

## Verification

Test open/close, clear, selection, keyboard focus, and disposal-sensitive flows for widgets whose control ownership changed.
