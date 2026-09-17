# Forui Controls Examples

## Decision Matrix

| Need | Control choice |
| --- | --- |
| Simple one-off popover, select, or field state | Managed internal |
| Parent state, provider, or router owns the value | Lifted |
| Imperative show/hide/open/clear from code | Managed external controller |
| Hook-based lifecycle in an existing hooks project | Hook-provided controller |

## Lifted State Skeleton

```dart
class FilterPopover extends StatefulWidget {
  const FilterPopover({super.key});

  @override
  State<FilterPopover> createState() => _FilterPopoverState();
}

class _FilterPopoverState extends State<FilterPopover> {
  bool shown = false;

  @override
  Widget build(BuildContext context) => FPopover(
        control: .lifted(
          shown: shown,
          onChange: (value) => setState(() => shown = value),
        ),
        child: const FButton(child: Text('Filters')),
        popoverBuilder: (context, style) => const FilterPanel(),
      );
}
```

## External Controller Review

- Controller created in `initState` or hook.
- Controller disposed by the same owner.
- No separate state variable shadows the controller value.
- Tests cover programmatic open/close or clear behavior.
