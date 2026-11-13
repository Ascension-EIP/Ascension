# Forui Forms And Inputs Examples

## Field Selection Matrix

| User task | Preferred widget |
| --- | --- |
| Enter arbitrary short text | `FTextField` or `FTextFormField` |
| Pick one of under 10 stable values | `FSelect` |
| Pick one from many searchable values | `FSelect.search` or `FAutocomplete` |
| Pick several values | `FMultiSelect` |
| Pick date or time | `FDateField`, `FTimeField`, or picker variant |
| Toggle a boolean setting | `FSwitch` or `FCheckbox` |
| Choose exactly one visible option | `FRadio` or `FSelectGroup` |

## Typed Option Pattern

```dart
class Project {
  const Project({required this.id, required this.name});

  final String id;
  final String name;
}

String projectLabel(Project project) => project.name;
```

Keep `Project.id` as the saved value and use `projectLabel` only for presentation.

## Async Options Review

- Debounce text input when querying remote data.
- Cancel or ignore stale requests.
- Show loading, empty, and error states.
- Preserve the selected value when the current query no longer returns it.
- Test clear, retry, keyboard selection, and submit.
