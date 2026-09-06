# Forui Theming Examples

## Theme Selector

```dart
FThemeData selectForuiTheme({
  required Brightness brightness,
  required TargetPlatform platform,
}) {
  final touch = switch (platform) {
    TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.fuchsia => true,
    _ => false,
  };

  final family = switch (brightness) {
    Brightness.dark => FThemes.neutral.dark,
    Brightness.light => FThemes.neutral.light,
  };

  return touch ? family.touch : family.desktop;
}
```

## Leaf Theme Consumption

```dart
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: context.theme.style.borderRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: typography.xs.copyWith(color: colors.secondaryForeground),
        ),
      ),
    );
  }
}
```

## Review Checklist

- Brightness is chosen explicitly.
- Touch/desktop density is explicit.
- `context.theme` is used instead of unrelated constants.
- Material interop is derived from the Forui theme while Material widgets remain.
