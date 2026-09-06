# Forui Styling Examples

## Local Delta

Use this when only one instance needs a small change:

```dart
FAccordion(
  style: .delta(
    focusedOutlineStyle: .delta(color: context.theme.colors.primary),
  ),
  children: const [
    FAccordionItem(
      title: Text('Details'),
      child: Text('More content'),
    ),
  ],
);
```

## Generated Style Function Shape

Use this pattern after `fvm dart run forui style create accordion`:

```dart
FAccordionStyle appAccordionStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  required bool touch,
}) =>
    FAccordionStyle(
      titleTextStyle: FVariants.from(
        typography.sm.copyWith(color: colors.foreground),
        variants: {
          [.focused]: .delta(decoration: () => TextDecoration.underline),
          [.disabled]: .delta(color: colors.mutedForeground),
        },
      ),
    );
```

## Review Checklist

- Every custom state has a reason.
- Focus, disabled, error, and destructive states are still legible.
- Local deltas are not duplicated across many screens.
- Generated style files are wired into the app and covered by visual review.
