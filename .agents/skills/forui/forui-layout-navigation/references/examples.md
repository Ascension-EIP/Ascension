# Forui Layout And Navigation Examples

## Navigation Layering

| Layer | Use |
| --- | --- |
| Route | Browser/deep-linkable app location |
| Sidebar or bottom navigation | Primary app destinations |
| Header actions | Actions for the current page |
| Tabs | Peer subviews within one route |
| Pagination | Data page position |

## Responsive Shell Sketch

```dart
Widget build(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final breakpoints = context.theme.breakpoints;

  if (width >= breakpoints.lg) {
    return FScaffold(
      child: Row(
        children: [
          AppSidebar(selectedRoute: route),
          const Expanded(child: RoutedContent()),
        ],
      ),
    );
  }

  return FScaffold(
    child: const RoutedContent(),
    // Pair with the project's Forui bottom navigation pattern.
  );
}
```

## Review Checklist

- Selected navigation is derived from the router or one app state source.
- Narrow and wide breakpoints preserve the same destination model.
- Keyboard traversal reaches navigation, content, and page actions.
- Resize does not lose form state, tab state, or selected destination.
