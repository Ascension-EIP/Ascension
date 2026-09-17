---
name: forui-forms-inputs
description: Build Forui forms and input widgets. Use when implementing FTextField, FTextFormField, FCheckbox, FRadio, FSelect, FMultiSelect, FSelectGroup, FSlider, FSwitch, FDateField, FTimeField, FDateTimePicker, FTimePicker, FPicker, FOtpField, validation, clearable inputs, async options, or form integration.
metadata:
  date: "2026-06-13"
---

# Forui Forms And Inputs

## Freshness Rule

Use `metadata.date` as the guidance snapshot date. For constructor parameters, form variants, async builders, and validators, check the installed `forui` version or current Forui docs before making version-sensitive edits.

## Widget Choices

- Use `FTextField` for standalone text entry.
- Use `FTextFormField` when the input participates in a Flutter `Form`.
- Use `FCheckbox`, `FRadio`, `FSwitch`, and `FSlider` for common boolean, exclusive, toggle, and numeric controls.
- Use `FSelect` for one value, `FMultiSelect` for multiple values, and `FSelectGroup` for grouped checkbox/radio options.
- Use `FDateField`, `FTimeField`, `FDateTimePicker`, `FTimePicker`, and `FPicker` for constrained temporal or wheel-based selection.
- Use `FAutocomplete` when users type to search or choose options.
- Use `FOtpField` for fixed-length one-time codes.

## Best Practices

- Choose the widget from the task model, not the visual shape. Free text stays a text field; bounded options become select/autocomplete; structured time/date values use date/time components.
- Keep value, validation, and submission ownership together. If the value is in a `Form`, validation should also be in the form path.
- Use search variants for long or remote option lists and plain select variants for short stable lists.
- Keep async option loading explicit: loading, empty, error, retry, and selected-but-not-loaded states should each have a path.
- Prefer typed option values over display strings. Map labels at the edge so changing text does not break state.
- Use lifted controls for values that affect other filters, URLs, persistence, or global state.

## Anti-Patterns

- Do not store selected labels as business values when stable ids exist.
- Do not validate only at submit if the field can show an immediate Forui error state.
- Do not use a picker for values users reasonably need to type or paste.
- Do not let clear buttons clear only the UI while leaving provider/form state stale.
- Do not fetch async options in `build` without caching, debouncing, or cancellation strategy.

## Form Rules

- Use form variants when validation, saving, or reset behavior should integrate with Flutter `Form`.
- Keep validation messages near the field and use Forui error styling instead of ad hoc red text.
- Make clearable fields clear both the visible value and the state source.
- For async option lists, model loading, empty, and error states explicitly.

## State Rules

- Use managed internal controls for local field state.
- Use lifted controls when the selected value is part of app state or must synchronize with other widgets.
- Dispose text or selection controllers when using external controllers.

## UX Rules

- Use labels for fields unless surrounding layout already gives an accessible name.
- Keep option labels stable and deterministic.
- Prefer search variants for long option sets.
- Avoid replacing a native text entry problem with a picker when free text is expected.

## Reference Samples

Read `references/examples.md` when implementing validation, async options, or lifted filter state.

## Verification

Test keyboard entry, focus traversal, validation, clearing, disabled/error states, async loading, and form submit/reset behavior.
