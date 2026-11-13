# Forui Overlays And Feedback Examples

## Overlay Selection Matrix

| Need | Preferred surface |
| --- | --- |
| Explain one control | `FTooltip` |
| Confirm a destructive decision | `showFDialog` or `FDialog` |
| Show quick success/failure feedback | `showFToast` |
| Present contextual anchored actions | `FPopoverMenu` |
| Present contextual anchored content | `FPopover` |
| Edit a focused side/bottom task | `showFSheet` |
| Keep a non-modal panel tied to a page | `showFPersistentSheet` |

## Result Pattern

```dart
Future<void> confirmDelete(BuildContext context) async {
  final confirmed = await showFDialog<bool>(
    context: context,
    builder: (context, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: const Text('Delete item?'),
      body: const Text('This action cannot be undone.'),
      actions: [
        FButton(
          variant: .outline,
          onPress: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FButton(
          variant: .destructive,
          onPress: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  await deleteItem();
  if (context.mounted) {
    showFToast(context: context, title: const Text('Deleted'));
  }
}
```

## Dismiss Review

- Back/escape behavior is known.
- Outside tap behavior is deliberate.
- Focus returns to the trigger when the overlay closes.
- Repeated calls do not create duplicate overlays.
